# MachineReplication

State machine for replacing the hardware behind a TEE machine while preserving its on-chain identity. A successor machine takes over an existing $\mathrm{TEE}_\mathrm{ID}$'s state — key set, signing policy, wallet bindings — so all references to the original $\mathrm{TEE}_\mathrm{ID}$ continue to work after the swap.

For the underlying status definitions see [Concepts/Machines § Statuses](../Concepts/Machines.md#statuses); for the contract surface, [`FlareTeeManager § Replication`](../Reference/Contracts/FlareTeeManager.md#management-calls).

## Preconditions

- An "old" machine $A$ exists with `status ∈ {PRODUCTION, PAUSED}` on extension $X$.
- $A$'s owner has access to a freshly registered "new" machine $B$ with `status = INITIALIZED` on the same extension $X$ and the same owner.
- $B$'s `(codeHash, platform)` is supported on $X$, and the pair $(A, B)$ is compatible per the registered [TEE upgrade path](../FCE/Workflows/Configuration.md) (`teeUpgradeId`).
- $B$ holds a fresh [`TeeAvailabilityCheck`](../../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md) `OK` proof with `responseBody.state.systemStateVersion ≠ 0`.
- Governance has set `pauseBeforeUpgradeMinDurationSeconds`.

## States

- `Production` — $A$ is operational; no replication in progress.
- `Paused` — $A$ has been paused; the upgrade dwell timer is running.
- `PausedForUpgrade` — $A$ is in `PAUSED_FOR_UPGRADE` after the dwell, awaiting `replicateFrom`.
- `Replicating` — $A$ in `PAUSED_FOR_UPGRADE`, $B$ in `REPLICATING`; `replicatingTeeIds[A] = B`; the `REPLICATE_FROM` instruction has been dispatched to both machines.
- `Confirmed` — `confirmReplicate` accepted; $A$'s slot now holds $B$'s hardware fields, $B$'s slot is deleted, $A$ is back in `PRODUCTION`.

## Initial State

`Production` (or `Paused` if the owner has already paused $A$ for an unrelated reason).

## Transitions

### pause: Production → Paused

- **Action**: `FlareTeeManager.pause(teeId_A)`.
- **Caller**: $A$'s machine owner.
- **Effects**: $A$.status = `PAUSED`; `lastStatusChangeTs` = now; emits [`TeeMachineStatusChanged(teeId_A, PAUSED)`](../Reference/Contracts/FlareTeeManagerEvents.md#teemachinestatuschanged).

### toPauseForUpgrade: Paused → PausedForUpgrade

- **Action**: [`FlareTeeManager.toPauseForUpgrade(teeId_A, claimBackAddress)`](../Reference/Contracts/FlareTeeManager.md#management-calls) — payable.
- **Caller**: $A$'s machine owner.
- **Guards**:
  - $A$.status = `PAUSED`.
  - `now − A.lastStatusChangeTs ≥ pauseBeforeUpgradeMinDurationSeconds`.
- **Effects**:
  - $A$.status = `PAUSED_FOR_UPGRADE`.
  - Sends a `TO_PAUSE_FOR_UPGRADE` instruction to $A$.
  - Emits `TeeMachinePausedForUpgrade(teeId_A)` and `TeeMachineStatusChanged(teeId_A, PAUSED_FOR_UPGRADE)`.

### resendToPauseForUpgrade: PausedForUpgrade → PausedForUpgrade

- **Action**: `toPauseForUpgrade(teeId_A, claimBackAddress)` — payable.
- **Caller**: $A$'s machine owner.
- **Guards**: $A$.status = `PAUSED_FOR_UPGRADE`.
- **Effects**: re-sends the `TO_PAUSE_FOR_UPGRADE` instruction; status unchanged. Used when the original instruction was lost or the dwell window must be refreshed.

### replicateFrom: PausedForUpgrade → Replicating

- **Action**: `FlareTeeManager.replicateFrom(oldTeeId_A, proof_B, teeUpgradeId, claimBackAddress)` — payable.
- **Caller**: machine owner of both $A$ and $B$ (must be the same address).
- **Guards**:
  - $A$.status = `PAUSED_FOR_UPGRADE`.
  - $B$.status = `INITIALIZED`, _or_ ($B$.status = `REPLICATING` and `replicatingTeeIds[A] = B`) for a retry.
  - $A$ and $B$ share `extensionId`.
  - $B$'s `(codeHash, platform)` is supported on the extension.
  - `(A, B)` matches the registered `teeUpgradeId`.
  - `proof_B.requestBody.teeId = B`, `proof_B.responseBody.status = OK`, `proof_B.header.timestamp ≥ B.lastStatusChangeTs`.
  - `proof_B.responseBody.state.systemStateVersion ≠ 0`.
- **Effects**:
  - `replicatingTeeIds[A] = B`.
  - $B$.status = `REPLICATING`.
  - Sends a `REPLICATE_FROM` instruction to both $A$ and $B$, carrying both machines' attestation data.
  - Emits `TeeMachineReplicationTriggered(A, B, teeUpgradeId)` and `TeeMachineStatusChanged(B, REPLICATING)`.

### confirmReplicate: Replicating → Confirmed

- **Action**: `FlareTeeManager.confirmReplicate(newTeeId_B, proof_A)`.
- **Caller**: machine owner of both $A$ and $B$.
- **Guards**:
  - `replicatingTeeIds[A] = B`.
  - $A$.status = `PAUSED_FOR_UPGRADE`; $B$.status = `REPLICATING`.
  - `proof_A.requestBody.teeId = A`, `proof_A.responseBody.status = OK`.
  - `proof_A.responseBody.state.systemStateVersion ≠ 0`.
  - $A$.owner = $B$.owner; $A$.extensionId = $B$.extensionId.
  - $B$'s `(codeHash, platform)` is supported.
- **Effects**:
  - $A$'s slot copies hardware fields from $B$: `initialTeeId = B`, `teeProxyId`, `codeHash`, `platform`, `url`, `initialSigningPolicyId`.
  - $B$'s slot is deleted.
  - `replicatingTeeIds[A]` is cleared.
  - $A$.status = `PRODUCTION`; availability deadline extended from `proof_A`.
  - Emits `TeeMachineReplicationConfirmed(A, B)` and `TeeMachineStatusChanged(A, PRODUCTION)`.

## Invariants

- `replicatingTeeIds[A] = B` ⟺ exactly one machine is in `REPLICATING` and points to $A$.
- A machine in `REPLICATING` has been reached only via `replicateFrom`, never via `register`.
- The persistent on-chain identity $A$ is preserved across the entire workflow; only its hardware fingerprint (`initialTeeId`, `codeHash`, `platform`, `teeProxyId`, `url`) changes.
- The owner address of $A$ never changes during replication (enforced by both `replicateFrom` and `confirmReplicate`).

## Terminal State

`Confirmed`. $A$ is in `PRODUCTION` backed by $B$'s hardware; $B$'s slot is gone. From here $A$ resumes its position in [MachineLifecycle](MachineLifecycle.md).

## Notes

- Key transfer happens off-chain: the TEE machines exchange their key set via the `REPLICATE_FROM` instruction's TEE-side handling, gated by enclave-to-enclave attestation (see [`F_REG`](../Reference/Operations/F_REG.md)).
- A failed `confirmReplicate` (rejected proof, mismatched extension) leaves the `Replicating` state in place; the owner can either re-attempt `replicateFrom` (the retry branch) with a fresh proof, or run `pause` on both machines and unwind.
- After `Confirmed`, $A$'s `initialTeeId` field records the successor's original identity — useful for tracing the hardware-refresh chain.
