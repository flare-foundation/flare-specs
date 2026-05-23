# OwnerTransfer

Two-step state machine for transferring ownership of a TEE machine or a wallet project. The same shape applies to both; the differences are in the entity identifier, the caller's allowlist, and the emitted events.

For the contract surface, see [`FlareTeeManager § Management Calls`](../Reference/Contracts/FlareTeeManager.md#management-calls) (machines) and [`§ Project Management`](../Reference/Contracts/FlareTeeManager.md#project-management) (projects).

## Preconditions

- The entity (machine or project) exists; its `owner` is recorded on chain.
- The intended new owner address is on the relevant allowlist:
  - For a machine: the extension's [machine-owner allowlist](../Concepts/Machines.md#owner-allowlist).
  - For a project: the extension's [project-owner allowlist](../Concepts/Machines.md#owner-allowlist).

## States

- `Owned` — current owner controls the entity; no proposal outstanding.
- `Proposed` — `proposedOwner` is set to the new candidate; the current owner still controls the entity.
- `Transferred` — the new owner has confirmed; `owner = proposedOwner`, `proposedOwner` cleared.

## Initial State

`Owned`.

## Transitions

### propose: Owned | Proposed → Proposed

- **Action**:
  - Machine: `FlareTeeManager.proposeNewOwner(teeId, newOwner)`.
  - Project: `FlareTeeManager.proposeNewOwner(projectId, newOwner)`.
- **Caller**: the current `owner` of the entity.
- **Guards**:
  - `newOwner` is on the relevant allowlist for the entity's `extensionId`.
  - `newOwner ≠ 0x0`.
- **Effects**:
  - `proposedOwner = newOwner` (overwriting any prior proposal).
  - Emits [`NewOwnerProposed(entityId, oldOwner, newOwner)`](../Reference/Contracts/FlareTeeManagerEvents.md#newownerproposed) (machine) or `NewOwnerProposed(projectId, newOwner)` (project).

### confirm: Proposed → Transferred

- **Action**:
  - Machine: `FlareTeeManager.confirmOwnership(teeId)`.
  - Project: `FlareTeeManager.confirmOwnership(projectId)`.
- **Caller**: `proposedOwner` (the address proposed in the most recent `propose`).
- **Guards**: `msg.sender = proposedOwner`.
- **Effects**:
  - `owner = proposedOwner`; `proposedOwner` cleared.
  - Emits [`NewOwnerConfirmed(entityId, newOwner)`](../Reference/Contracts/FlareTeeManagerEvents.md#newownerconfirmed) (machine) or `OwnershipConfirmed(projectId, newOwner)` (project).
  - All entity state — for a machine: status, keys, signing policy; for a project: wallets, backup manager, default wallet — persists unchanged; only the owner address rotates.

## Invariants

- At most one `proposedOwner` per entity at any time; a second `propose` overwrites the first without emitting a cancellation event.
- Only the current `owner` can `propose`; only the `proposedOwner` can `confirm`. The two-step design prevents transfer to an incorrect address from succeeding without the destination's consent.
- A new `propose` is rejected if the proposed address is not on the allowlist, even if the current owner had been admitted earlier (allowlist state can change between transfers).

## Terminal State

`Transferred`. The entity continues as-is under the new owner; for a machine, [MachineLifecycle](MachineLifecycle.md) resumes; for a project, [WalletSetup](WalletSetup.md) / [KeyAdd](KeyAdd.md) / [KeyDelete](KeyDelete.md) operations resume.

## Notes

- The current owner can cancel a pending proposal by calling `propose` again with a different (or zero?) address. The contract does not expose an explicit cancel; overwriting is the canonical way.
- For machines, ownership transfer is independent of operational status — a paused or suspended machine can be transferred without first returning it to `PRODUCTION`.
- For projects, the new owner inherits the entire wallet set under the project, including any wallets in `PAUSED` state.
