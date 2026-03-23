# F_WALLET VRF

## Description

Generates a verifiable randomness proof using a VRF key. The TEE loads the private key identified by `(walletId, keyId)`, verifies that its signing algorithm is `keccak256-secp256k1-vrf`, and computes an ECVRF proof over the provided nonce. The witness points (`u`, `cGamma`, `v`, `zInv`) are pre-computed off-chain to avoid expensive secp256k1 scalar multiplications in the EVM. The on-chain `TeeVRFVerifier` contract verifies the proof using `ecrecover`.

The final random value is derived as `keccak256(gamma_x || gamma_y)`, where `gamma_x` and `gamma_y` are 32-byte big-endian encodings of the gamma point coordinates.

## Event message

```solidity
// Source: ITeeVrf.sol
struct VrfInstructionMessage {
    bytes32 walletId; // wallet id of the VRF key
    uint64 keyId;     // key id within the wallet
    bytes nonce;      // arbitrary nonce binding the proof to a specific request
}
```

## Fixed message

/

## Variable message

/

## Additional action data

/

## Action result

JSON-encoded response containing the wallet metadata, nonce, and VRF proof:

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

- `gamma` -- A curve point $(\gamma_x, \gamma_y)$, the VRF output: $\gamma = \mathrm{sk} \cdot \mathrm{HashToCurve}(\mathrm{nonce})$.
- `c` -- The challenge scalar.
- `s` -- The response scalar: $s = k - \mathrm{sk} \cdot c \mod N$.
- `u` -- Witness point $c \cdot \mathrm{pk} + s \cdot G$.
- `cGamma` -- Witness point $c \cdot \gamma$.
- `v` -- Witness point $c \cdot \gamma + s \cdot H$.
- `zInv` -- Field element $(\mathrm{cGamma}_x - v_x)^{-1} \mod P$.

## Notes

- **Validation:** The nonce must be non-empty; the processor rejects requests with an empty nonce. The key's signing algorithm must be `keccak256-secp256k1-vrf`; any other algorithm is rejected. If the specified `(walletId, keyId)` pair does not exist on the TEE machine, the request fails.
