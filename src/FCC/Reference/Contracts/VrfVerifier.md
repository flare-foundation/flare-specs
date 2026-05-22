# VrfVerifier

_Pending Phase B leaf cleaning._

Standalone Solidity contract that verifies VRF proofs produced by TEE machines holding `keccak256-secp256k1-vrf` keys. Uses `ecrecover` plus pre-computed witness points (`u`, `cGamma`, `v`, `zInv`) so on-chain verification stays cheap.

For the proof structure, see [`F_WALLET VRF`](../Operations/F_WALLET.md#vrf) and the [VrfProof workflow](../../Workflows/VrfProof.md). The randomness extracted on success is $\mathrm{keccak256}(\gamma_x \,\|\, \gamma_y)$.
