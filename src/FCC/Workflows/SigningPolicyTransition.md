# SigningPolicyTransition

State machine for installing a new [signing policy](../../FSP/SigningPolicy.md) on a TEE machine at the boundary of each [reward epoch](../../FSP/Epochs.md#reward-epoch). Runs once per machine per epoch; it is the synchronization barrier between the FSP voter-set rotation and the TEE machines' vote-verification logic.

For the FSP side, see [`SigningPolicy`](../../FSP/SigningPolicy.md); for the operation, [`F_POLICY UPDATE_POLICY`](../Reference/Operations/F_POLICY.md#update_policy).

## Preconditions

- The TEE machine is in `PRODUCTION` and knows the current signing policy as `lastSigningPolicyId` (per [Concepts § Signing Policy](../Concepts/Policy.md)).
- The FSP has finalized a new signing policy for the next reward epoch and emitted `SigningPolicyInitialized` on the FSP `Relay` contract.
- The destination machine's [TEE proxy](../Reference/Components/Proxy.md) has the FSP indexer configured and is reachable from the machine.

## States

- `Active` — the machine's `lastSigningPolicyId` matches the FSP's current reward-epoch policy; no transition pending.
- `Pending` — `SigningPolicyInitialized` has fired for an epoch beyond `lastSigningPolicyId`; the proxy has not yet pushed it.
- `Pushed` — the proxy has dispatched an [`UPDATE_POLICY`](../Reference/Operations/F_POLICY.md#update_policy) direct action targeting this machine; the action is enqueued.
- `Adopted` — the machine has processed `UPDATE_POLICY`; `lastSigningPolicyId` and `lastSigningPolicyHash` updated.

## Initial State

`Active` immediately after [MachineRegistration](MachineRegistration.md) completes (the initial policy is installed as part of the registration attestation).

## Transitions

### init: Active → Pending

- **Action**: FSP voters complete the signing-policy definition protocol; the FSP `Relay` contract emits `SigningPolicyInitialized(rewardEpochId, voters, weights, threshold, …)`.
- **Caller**: FSP signing-policy voters (data providers).
- **Effects**: a new signing policy is available on chain; from this point any subsequent instructions in the new reward epoch will require the new policy on the TEE machine.

### push: Pending → Pushed

- **Action**: the TEE proxy's [signing-policy updater](../Reference/Components/Proxy.md) observes `SigningPolicyInitialized` via the C-chain indexer and submits a direct action carrying the [`UpdatePolicyMessage`](../Reference/Operations/F_POLICY.md#update_policy) to the TEE machine's [internal queue API](../Reference/Components/Proxy.md#internal-apis).
- **Caller**: the TEE proxy (internal); the call originates from the proxy's signing-policy updater goroutine.
- **Guards**: the proxy holds a valid copy of the new signing policy; no `UPDATE_POLICY` is already in flight for the same `rewardEpochId`.
- **Effects**: action enqueued on the machine's `policy` processing queue.

### install: Pushed → Adopted

- **Action**: TEE machine pulls and processes the `UPDATE_POLICY` direct action.
- **Caller**: TEE machine (`F_POLICY` handler).
- **Guards**:
  - signed-by-prior-policy chain valid: the new policy's signatures recover under the machine's _current_ `lastSigningPolicyId` voter set with the prior policy's threshold.
  - `rewardEpochId` = `lastSigningPolicyId` + 1.
- **Effects**: machine's `lastSigningPolicyId` and `lastSigningPolicyHash` advance to the new policy; subsequent instruction verification uses the new voter set and thresholds.

### refresh: Adopted → Active

- **Action**: implicit at the start of the next FSP signing-policy round; the machine is once again synchronized.

## Invariants

- A machine in `PRODUCTION` accepts instructions whose `rewardEpochId` is at most one epoch behind `lastSigningPolicyId`; older epochs are stale (per [Machine validation](../Reference/Components/Machine.md#validation)).
- `UPDATE_POLICY` is a direct action — it bypasses the [instruction voting](../Concepts/Voting.md) flow because it is signed by the _prior_ policy's voters; the machine independently re-verifies that chain.
- Only the TEE proxy (or the [system instructions sender](../FCE/Concepts.md), through `sendSystemInstructions`) can push `UPDATE_POLICY`; arbitrary parties cannot rotate a machine's view of the signing policy.

## Terminal State

`Adopted`. The transition repeats once per reward epoch for the lifetime of the machine.

## Notes

- A machine that fails to install before the next epoch's instructions arrive rejects them as stale; the proxy retries `push` until the machine is caught up or until the next epoch overtakes it.
- Cross-protocol coupling: this workflow depends on the FSP's signing-policy lifecycle, which is out of scope here (see [FSP § SigningPolicy](../../FSP/SigningPolicy.md)).