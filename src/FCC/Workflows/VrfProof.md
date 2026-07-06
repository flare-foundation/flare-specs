# VrfProof

State machine for generating a verifiable random number from a VRF key held inside a TEE machine, and verifying the resulting proof on chain.

For canonical VRF key semantics, see [Concepts/Keys § VRF Keys](../Concepts/Keys.md#vrf-keys); the operation reference is [`F_WALLET VRF`](../Reference/Operations/F_WALLET.md#vrf); the on-chain verifier is [`VrfVerifier`](../Reference/Contracts/VrfVerifier.md).

## Preconditions

- A TEE machine holding the target key is in `PRODUCTION`.
- The wallet is in `PRODUCTION` ([WalletSetup](WalletSetup.md)).
- A key for `(walletId, keyId)` exists on the wallet with `signingAlgo = keccak256-secp256k1-vrf`.
- The wallet's VRF authorisation address has been set (via the `VrfFacet`'s `setVrfAuthorizationAddress`, [project owner](../../Terminology/Roles.md#project-owner) only).
- The caller holds that authorisation address.

## States

- `Idle` — no VRF instruction is in flight for this nonce.
- `Requested` — [`VrfFacet.requestVrf`](../Reference/Contracts/FlareTeeManager.md#facets) has emitted the [`F_WALLET VRF`](../Reference/Operations/F_WALLET.md#vrf) instruction; voting is in progress.
- `Signed` — the TEE machine has produced the proof and returned it through its proxy.
- `Verified` — the proof has been submitted to [`VrfVerifier`](../Reference/Contracts/VrfVerifier.md) and accepted; the randomness $\mathrm{keccak256}(\gamma_x \,\|\, \gamma_y)$ has been extracted via [`randomnessFromProof`](../Reference/Contracts/VrfVerifier.md#randomnessfromproof).

## Initial State

`Idle`.

## Transitions

### requestVrf: Idle → Requested

- **Action**: `FlareTeeManager.requestVrf(walletId, keyId, nonce, claimBackAddress)` (`VrfFacet`) — payable.
- **Caller**: the wallet's VRF authorisation address.
- **Guards**:
  - `wallet.status = PRODUCTION`
  - `nonce` is non-empty
  - `key.teeIds` contains at least one machine in `PRODUCTION`
  - `msg.value ≥ fee(F_WALLET, VRF)`
- **Effects**: emits [`VrfRequested`](../Reference/Contracts/FlareTeeManagerEvents.md#vrfrequested) and [`TeeInstructionsSent`](../Reference/Contracts/FlareTeeManagerEvents.md#teeinstructionssent); dispatches the instruction to every TEE in `key.teeIds`.

### voteAndSign: Requested → Signed

- **Action**: standard [voting](../Concepts/Voting.md) plus TEE-side ECVRF proof generation per [F_WALLET VRF](../Reference/Operations/F_WALLET.md#vrf).
- **Caller**: [data providers](../../Terminology/Roles.md#data-provider) (relay clients); the TEE machine performs the cryptographic work.
- **Guards**: data-provider weight $\geq$ signing-policy threshold (no cosigner term unless the wallet configured one).
- **Effects**:
  - TEE machine computes $H = \mathrm{HashToCurve}(\mathrm{nonce})$, $\gamma = \mathrm{sk} \cdot H$, challenge $c$, response $s$, and pre-computes witness points $u, c\gamma, v, z_{\mathrm{inv}}$ (see [F_WALLET VRF action result](../Reference/Operations/F_WALLET.md#vrf)).
  - The resulting JSON `proof` is posted to the TEE proxy as the [action result](../Concepts/Actions.md#action-results).

### retrieve: Signed → Verified (off-chain step)

- **Action**: the caller reads the result from the proxy (`GET /action/result/<instructionId>`) and submits it to [`VrfVerifier.verifyRandomness`](../Reference/Contracts/VrfVerifier.md#verifyrandomness).
- **Caller**: anyone with the proof.
- **Guards**: the four ecrecover-based checks in `verifyRandomness` (`u`, `cGamma`, `v`, `c`) all pass; see [VrfVerifier § verifyRandomness](../Reference/Contracts/VrfVerifier.md#verifyrandomness).
- **Effects**: on success the caller derives the randomness via [`randomnessFromProof(γ_x, γ_y)`](../Reference/Contracts/VrfVerifier.md#randomnessfromproof). On failure the verifier reverts with one of the [errors](../Reference/Contracts/VrfVerifier.md#errors); the state machine stays in `Signed`.

## Invariants

- The challenge $c$ committed by the TEE machine is bit-identical to the one the verifier recomputes; both follow $c = \mathrm{HashToZn}(G, H, \mathrm{pk}, \gamma, u, v)$.
- The randomness is purely a function of $\gamma$ (and hence of `(sk, nonce)`); identical `(walletId, keyId, nonce)` triples yield identical randomness across re-runs.
- A successful `verifyRandomness` is a sufficient condition for the proof — neither `walletId`, `keyId`, nor the on-chain key bookkeeping enters the on-chain check beyond the public key.

## Terminal States

`Verified`. The extracted `bytes32` randomness is the workflow's output.

## Notes

- Repeated VRF requests on the same `(walletId, keyId, nonce)` produce the same randomness — the VRF is deterministic.
- The TEE machine rejects the action if `HashToCurve` fails to find a valid point within $256$ iterations (probability $\approx 2^{-256}$) or if the pre-computed `zInv` would be undefined.
- For the proof structure and on-machine generation algorithm, see [`F_WALLET VRF`](../Reference/Operations/F_WALLET.md#vrf). The ECVRF scheme follows "Making NSEC5 Practical for DNSSEC" (Cryptology ePrint Archive, Report 2017/099).
