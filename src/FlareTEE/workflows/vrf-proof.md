# VRF Proof Generation

## Overview

This workflow describes generating a verifiable random number using a VRF key held inside a TEE machine.
The result can be verified on-chain by the `VrfVerifier` contract.

## Prerequisites

- **TEE machine in PRODUCTION status** — the machine holding the VRF key must be registered and operational (see [machine-registration.md](machine-registration.md))
- **Wallet in PRODUCTION status** — the wallet must be enabled via the [wallet-setup workflow](wallet-setup.md)
- **Wallet with a VRF key** — a key with signing algorithm `keccak256-secp256k1-vrf` must already be generated and confirmed
- **VRF authorization address set** — the caller must be the VRF authorization address for the wallet (set via `TeeVrf.setVrfAuthorizationAddress()`)

---

## Steps

### Step 1: Submit VRF Instruction

**Who initiates:** The VRF authorization address for the wallet (set via `TeeVrf.setVrfAuthorizationAddress()`).

A VRF proof request is submitted via `TeeVrf.requestVrf(walletId, keyId, nonce, claimBackAddress)`, which internally constructs and sends a [`VRF`](../commands/F_WALLET--VRF.md) instruction.

**Parameters:**
- `walletId` (`bytes32`) — the wallet ID of the VRF key.
- `keyId` (`uint64`) — the key ID within the wallet.
- `nonce` (`bytes`) — an arbitrary bytes value binding the proof to a specific request.
- `claimBackAddress` (`address`) — address to claim back unused instruction fees.

**Requirements:**
- The caller must be the VRF authorization address for the wallet.
- The wallet must be in `PRODUCTION` status.
- The `nonce` must be non-empty.
- The specified `(walletId, keyId)` pair must exist on the target TEE machine.
- The key's signing algorithm must be `keccak256-secp256k1-vrf`.

**Events emitted:** `VrfRequested(walletId, keyId, instructionId)`, `TeeInstructionsSent`

---

### Step 2: Voting

Data providers vote on the instruction following the standard voting process (see [extension-instructions.md](extension-instructions.md)). Since this is an instruction command, it requires a threshold of signatures from the current signing policy before the TEE proxy forwards the action to the TEE machine.

---

### Step 3: TEE Processing

Once the voting threshold is reached, the TEE proxy delivers the action to the TEE machine. The TEE then:

1. **Parses** the `VrfInstructionMessage` from the action's fixed data.
2. **Loads** the private key for the specified `(walletId, keyId)` pair from wallet storage.
3. **Validates** that the key's signing algorithm is `keccak256-secp256k1-vrf`. Any other algorithm is rejected.
4. **Computes** the ECVRF proof using the secp256k1 curve:
   - Hashes the nonce to a curve point $H = \mathrm{HashToCurve}(\mathrm{nonce})$ via iterative Keccak-256 hashing until a valid x-coordinate is found.
   - Computes the VRF output $\gamma = \mathrm{sk} \cdot H$.
   - Samples a random scalar $k$ and computes commitment points $U = k \cdot G$ and $V = k \cdot H$.
   - Derives the challenge $c = \mathrm{HashToZn}(\mathrm{Pack}(G, H, \mathrm{pk}, \gamma, U, V))$ using ABI-encoded Keccak-256 reduced modulo $N$.
   - Computes the response $s = k - \mathrm{sk} \cdot c \mod N$.
   - Pre-computes witness points for on-chain verification: $c\gamma$, and $z_{\mathrm{inv}} = (\mathrm{cGamma}_x - V_x)^{-1} \mod P$.
5. **Returns** the JSON-encoded result to the TEE proxy.

---

### Step 4: Retrieve Result

The action result is available from the TEE proxy. The response is a JSON object containing:

```json
{
    "walletId": "bytes32",
    "keyId": "uint64",
    "nonce": "bytes",
    "proof": {
        "gamma": { "x": "uint256", "y": "uint256" },
        "c": "uint256",
        "s": "uint256",
        "u": { "x": "uint256", "y": "uint256" },
        "cGamma": { "x": "uint256", "y": "uint256" },
        "v": { "x": "uint256", "y": "uint256" },
        "zInv": "uint256"
    }
}
```

Where:

- `gamma` — curve point $(\gamma_x, \gamma_y)$, the VRF output: $\gamma = \mathrm{sk} \cdot \mathrm{HashToCurve}(\mathrm{nonce})$.
- `c` — the challenge scalar.
- `s` — the response scalar: $s = k - \mathrm{sk} \cdot c \mod N$.
- `u` — witness point $c \cdot \mathrm{pk} + s \cdot G$.
- `cGamma` — witness point $c \cdot \gamma$.
- `v` — witness point $c \cdot \gamma + s \cdot H$.
- `zInv` — field element $(\mathrm{cGamma}_x - v_x)^{-1} \mod P$.

The four witness points (`u`, `cGamma`, `v`, `zInv`) are pre-computed off-chain to avoid expensive secp256k1 scalar multiplications in the EVM.

---

### Step 5: On-chain Verification

The proof can be verified on-chain by submitting it to the `VrfVerifier` contract. The contract performs $4$ independent checks using `ecrecover`:

1. $U = c \cdot \mathrm{pk} + s \cdot G$ — proves the TEE knows the secret key $\mathrm{sk}$ such that $\mathrm{pk} = \mathrm{sk} \cdot G$.
2. $c\gamma = c \cdot \gamma$ — confirms that `cGamma` is correctly derived.
3. $V = c\gamma + s \cdot H$ — confirms that $V$ is correctly derived from $\gamma$, $H$, $c$, and $s$.
4. $c = \mathrm{HashToZn}(\mathrm{Pack}(G, H, \mathrm{pk}, \gamma, U, V))$ — confirms the challenge is consistent with all public values.

Once verified, the final random value is extracted as:

$$\mathrm{randomness} = \mathrm{keccak256}(\gamma_x \| \gamma_y)$$

where $\gamma_x$ and $\gamma_y$ are $32$-byte big-endian encodings of the gamma point coordinates.

---

## Notes

- **Error conditions:**

  | Condition | Result |
  |-----------|--------|
  | Empty nonce | Rejected by TEE processor |
  | Key not found for `(walletId, keyId)` | Action fails |
  | Signing algorithm is not `keccak256-secp256k1-vrf` | Rejected by TEE processor |
  | `HashToCurve` fails (no valid point found in $256$ iterations) | Proof generation fails |
  | Zero denominator for `zInv` (probability $\approx 1/P$) | Proof generation fails; extremely unlikely |

- **Cryptographic reference:** The VRF implementation follows the ECVRF scheme based on secp256k1, as described in "Making NSEC5 Practical for DNSSEC" (Cryptology ePrint Archive, Report 2017/099). The `HashToCurve` function uses iterative Keccak-256 hashing with coordinates reduced modulo $P$, retrying until a valid curve point is found (expected $\approx 2$ iterations). The `HashToZn` function computes $\mathrm{keccak256}(\mathrm{msg}) \mod N$.

