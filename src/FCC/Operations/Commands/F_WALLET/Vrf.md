# F_WALLET VRF

[Instruction action](../../Actions.md#instruction-actions) that produces a verifiable randomness proof using a stored VRF key.
The TEE machine loads the private key identified by `(walletId, keyId)` and computes an ECVRF proof over the supplied `nonce`.

The on-chain `VrfVerifier` contract verifies the proof using `ecrecover`; the four witness points (`u`, `cGamma`, `v`, `zInv`) in the response are pre-computed off-chain to avoid expensive secp256k1 scalar multiplications inside the EVM.
The final random value is $\mathrm{keccak256}(\gamma_x \,\|\, \gamma_y)$, where $\gamma_x, \gamma_y$ are 32-byte big-endian encodings of the `gamma` point coordinates.

## Event message

[`VrfInstructionMessage`](../../../Types/Abi/Key.md#vrfinstructionmessage).

## Action result

JSON object:

- `walletId`, `keyId`, `nonce`: copied from the request.
- `proof`: an object with the following fields ($G$ is the secp256k1 generator, $\mathrm{sk}$ the private key, $\mathrm{pk}$ the public key, $H = \mathrm{HashToCurve}(\mathrm{nonce})$, $N$ the curve order, $P$ the field prime):
  - `gamma`: a curve point $\gamma = \mathrm{sk} * H$ (the VRF output).
  - `c`: the challenge scalar.
  - `s`: the response scalar, $s = k - \mathrm{sk} * c \mod N$.
  - `u`: witness point $c * \mathrm{pk} + s * G$.
  - `cGamma`: witness point $c * \gamma$.
  - `v`: witness point $c * \gamma + s * H$.
  - `zInv`: field element $(\mathrm{cGamma}_x - v_x)^{-1} \mod P$.

## Validation

- The `(walletId, keyId)` must identify a key stored on the machine.
- That key's `signingAlgo` must be `keccak256-secp256k1-vrf`.
- `nonce` must be non-empty.
