# VrfVerifier

Standalone Solidity contract that verifies VRF proofs produced by TEE machines holding `keccak256-secp256k1-vrf` keys.
The proof carries pre-computed witness points so verification can use `ecrecover` instead of full secp256k1 scalar multiplications, keeping on-chain cost low.

For the on-machine proof generation, see [`F_WALLET VRF`](../Operations/F_WALLET.md#vrf); for the concept overview, [Concepts/Keys § VRF Keys](../../Concepts/Keys.md#vrf-keys); for end-to-end usage including the on-chain request, [VrfProof workflow](../../Workflows/VrfProof.md). The on-chain entry point that emits the VRF request — `requestVrf` on the [`VrfFacet`](FlareTeeManager.md#facets) — lives on the `FlareTeeManager` diamond.

## Functions

### `verifyRandomness`

```solidity
function verifyRandomness(
    Proof calldata _proof,
    uint256 _pkX,
    uint256 _pkY,
    bytes calldata _nonce
) external view returns (bool);
```

Verifies that `_proof` is a valid VRF output for `(pk, _nonce)` where `pk = (_pkX, _pkY)`.

The verifier rejects with one of the [errors](#errors) below if any check fails; on success it returns `true`. Verification performs four independent checks using `ecrecover`:

1. $u = c \cdot \mathrm{pk} + s \cdot G$ — proves knowledge of $\mathrm{sk}$ with $\mathrm{pk} = \mathrm{sk} \cdot G$.
2. $\mathrm{cGamma} = c \cdot \gamma$ — confirms `cGamma` is correctly derived.
3. $v = \mathrm{cGamma} + s \cdot H$ where $H = \mathrm{HashToCurve}(\_nonce)$ — confirms $v$ is consistent with $\gamma$, $H$, $c$, $s$.
4. $c = \mathrm{HashToZn}(G, H, \mathrm{pk}, \gamma, u, v)$ — confirms the challenge is consistent with all public values.

### `randomnessFromProof`

```solidity
function randomnessFromProof(
    uint256 _gammaX,
    uint256 _gammaY
) external pure returns (bytes32);
```

Returns the randomness output extracted from a verified `gamma`:

$$\mathrm{randomness} = \mathrm{keccak256}(\gamma_x \,\|\, \gamma_y)$$

where $\gamma_x, \gamma_y$ are $32$-byte big-endian encodings of the point coordinates. Callers MUST verify the proof with [`verifyRandomness`](#verifyrandomness) before consuming the output.

## Types

### `Proof`

```solidity
struct Proof {
    Point gamma;
    uint256 c;
    uint256 s;
    Point u;
    Point cGamma;
    Point v;
    uint256 zInv;
}

struct Point {
    uint256 x;
    uint256 y;
}
```

| Field | Description |
|---|---|
| `gamma` | VRF output point $\gamma = \mathrm{sk} \cdot H$. |
| `c` | Challenge scalar. |
| `s` | Response scalar, $s = k - \mathrm{sk} \cdot c \mod N$. |
| `u` | Witness point $u = c \cdot \mathrm{pk} + s \cdot G$. |
| `cGamma` | Witness point $c \cdot \gamma$ (intermediate for $v$). |
| `v` | Witness point $v = c \cdot \gamma + s \cdot H$. |
| `zInv` | $\mathrm{modInv}(\mathrm{cGamma}_x - v_x,\ P)$ — pre-computed inverse used in point subtraction without `BigModExp`. |

The witness points (`u`, `cGamma`, `v`, `zInv`) are computed off-chain by the TEE machine; the verifier checks them rather than recomputing them.

## Errors

| Error | Condition |
|---|---|
| `PkNotOnCurve` | Public-key point does not satisfy $y^2 = x^3 + 7$. |
| `GammaNotOnCurve` | `gamma` does not satisfy $y^2 = x^3 + 7$. |
| `COutOfRange` | Challenge scalar $c$ is zero or $\geq N$. |
| `SOutOfRange` | Response scalar $s$ is $\geq N$. |
| `DegenerateInput` | $H_x \geq N$, which would make the `ecrecover` shortcut unsound. |
| `InvalidUWitness` | $u \neq c \cdot \mathrm{pk} + s \cdot G$. |
| `InvalidCGammaWitness` | $\mathrm{cGamma} \neq c \cdot \gamma$. |
| `InvalidZInv` | $\mathrm{zInv} \neq \mathrm{modInv}(\mathrm{cGamma}_x - v_x,\ P)$. |
| `InvalidVWitness` | $v \neq c \cdot \gamma + s \cdot H$. |
| `HashToCurveExceededIterationLimit` | Iterative hash-to-curve failed to find a valid point within $256$ tries (expected probability $\approx 2^{-256}$). |
