# MachineLifecycle

State machine for a registered TEE machine after [MachineRegistration](MachineRegistration.md): availability refresh, owner-initiated and automated pauses, settings updates, ownership transfer, and governance ban/unban.

For canonical semantics, see [Concepts/Machines § Statuses](../Concepts/Machines.md#statuses) and [Availability Deadline](../Concepts/Machines.md#availability-deadline); contract surface in [`FlareTeeManager § Management Calls`](../Reference/Contracts/FlareTeeManager.md#management-calls).

## Preconditions

- The machine is registered on [`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md) with a `status` in `{INITIALIZED, PRODUCTION, SUSPENDED, PAUSED, BANNED}`.

## States

The same set the contract tracks (see [Concepts/Machines § Statuses](../Concepts/Machines.md#statuses)):

- `INITIALIZED` — registered, no availability proof yet.
- `PRODUCTION` — operational; accepts instructions; may be earning rewards.
- `SUSPENDED` — automatically downgraded (failed availability proof, expired deadline, or `pauseWithProof`); recoverable.
- `PAUSED` — owner-initiated or settings-update stop; recoverable.
- `BANNED` — extension-owner stop; only reversible via `unban` (lands the machine in `PAUSED`).

## Initial State

The status the machine has at the moment the workflow starts — usually `PRODUCTION` after a successful [MachineRegistration](MachineRegistration.md).

## Transitions

### confirmAvailability: PRODUCTION → PRODUCTION (deadline refresh)

- **Action**: [`FlareTeeManager.confirmAvailability(proof)`](../Reference/Contracts/FlareTeeManager.md#management-calls) — non-payable.
- **Caller**: anyone (extends the deadline on behalf of the machine; commonly automated by the operator or rewards bot).
- **Guards**:
  - `proof.status = OK`.
  - The machine's current `codeHash` and `platform` remain in the extension's supported set.
  - `proof.lastSigningPolicyId` matches or advances the machine's record.
- **Effects**:
  - Extends `availabilityCheckValidityEndTs`.
  - Updates `lastSigningPolicyId` from the proof.
  - Emits [`AvailabilityCheckValidityExtended`](../Reference/Contracts/FlareTeeManagerEvents.md#availabilitycheckvalidityextended).
  - The machine remains eligible for rewards.

### pauseByOwner: PRODUCTION | SUSPENDED → PAUSED

- **Action**: [`FlareTeeManager.pause(teeId)`](../Reference/Contracts/FlareTeeManager.md#management-calls) — non-payable.
- **Caller**: machine owner (or anyone if the machine's code version is currently disabled).
- **Guards**: `status ∈ {PRODUCTION, SUSPENDED}`.
- **Effects**: status → `PAUSED`; machine removed from the active set; emits [`TeeMachineStatusChanged`](../Reference/Contracts/FlareTeeManagerEvents.md#teemachinestatuschanged).

### pauseOnDeadlineExpiry: PRODUCTION → SUSPENDED

- **Action**: [`FlareTeeManager.pause(teeId)`](../Reference/Contracts/FlareTeeManager.md#management-calls) — non-payable.
- **Caller**: anyone.
- **Guards**: `status = PRODUCTION` and `block.timestamp > availabilityCheckValidityEndTs`. If the caller is not the machine owner, also requires that the extension is not emergency paused or in a post-unpause grace window.
- **Effects**: status → `SUSPENDED`; emits [`TeeMachineStatusChanged`](../Reference/Contracts/FlareTeeManagerEvents.md#teemachinestatuschanged).

### pauseWithProof: PRODUCTION → SUSPENDED

- **Action**: [`FlareTeeManager.pauseWithProof(proof)`](../Reference/Contracts/FlareTeeManager.md#management-calls) — non-payable.
- **Caller**: anyone with a non-`OK` [`TeeAvailabilityCheck`](../../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md) proof for the machine.
- **Guards**:
  - `status = PRODUCTION`.
  - `proof.timestamp ≥ lastStatusChangeTs`.
  - Proof either fails verification or carries a non-`OK` `responseBody.status` (e.g. `DOWN`).
- **Effects**: status → `SUSPENDED`; emits [`TeeMachineStatusChanged`](../Reference/Contracts/FlareTeeManagerEvents.md#teemachinestatuschanged).
- **Procedure**: obtain the proof by running the [Fdc2Attestation](../../FDC2/Workflows/Fdc2Attestation.md) sub-workflow with `attestationType = TeeAvailabilityCheck` targeting the suspect machine.

### toProduction: INITIALIZED | SUSPENDED | PAUSED → PRODUCTION

- **Action**: [`FlareTeeManager.toProduction(proof)`](../Reference/Contracts/FlareTeeManager.md#management-calls) — non-payable.
- **Caller**: machine owner (from `INITIALIZED` or `PAUSED`); anyone (from `SUSPENDED`).
- **Guards**:
  - `proof.status = OK`.
  - The machine's current `codeHash` and `platform` remain in the extension's supported set.
- **Effects**: status → `PRODUCTION`; deadline reset from the proof; emits [`TeeMachineStatusChanged`](../Reference/Contracts/FlareTeeManagerEvents.md#teemachinestatuschanged).
- **Procedure**: obtain the proof via [Fdc2Attestation](../../FDC2/Workflows/Fdc2Attestation.md) with `attestationType = TeeAvailabilityCheck`.

### updateSettings: PRODUCTION | SUSPENDED → PAUSED (settings change)

- **Action**: [`FlareTeeManager.updateTeeMachineSettings(teeId, teeProxyId, url)`](../Reference/Contracts/FlareTeeManager.md#management-calls) — non-payable.
- **Caller**: machine owner.
- **Guards**: `teeProxyId ≠ 0`; `url` non-empty; `status ∈ {PRODUCTION, SUSPENDED, INITIALIZED, PAUSED}`.
- **Effects**:
  - Records the new `teeProxyId` and `url`.
  - If `status ∈ {PRODUCTION, SUSPENDED}`, transitions to `PAUSED`; emits [`TeeMachineSettingsUpdated`](../Reference/Contracts/FlareTeeManagerEvents.md#teemachinesettingsupdated) and [`TeeMachineStatusChanged`](../Reference/Contracts/FlareTeeManagerEvents.md#teemachinestatuschanged).
  - Otherwise only the settings event fires.
  - Returning to `PRODUCTION` requires a fresh `toProduction(proof)`.

### proposeNewOwner / confirmOwnership: any → any (ownership change, no status change)

- **Action**: [`FlareTeeManager.proposeNewOwner(teeId, newOwner)`](../Reference/Contracts/FlareTeeManager.md#management-calls) followed by `confirmOwnership(teeId)` from `newOwner`.
- **Caller**: current owner (propose), proposed owner (confirm).
- **Guards**: the proposed owner must be allowlisted for the extension (or `address(0)` to cancel a pending proposal); the confirmer must still be allowlisted at confirmation time.
- **Effects**: emits [`NewOwnerProposed`](../Reference/Contracts/FlareTeeManagerEvents.md#newownerproposed) at propose; emits [`NewOwnerConfirmed`](../Reference/Contracts/FlareTeeManagerEvents.md#newownerconfirmed) and updates `owner` at confirm. The machine status is unchanged.

### ban: PRODUCTION | SUSPENDED | PAUSED → BANNED

- **Action**: [`FlareTeeManager.ban(teeId)`](../Reference/Contracts/FlareTeeManager.md#management-calls) — non-payable.
- **Caller**: extension owner.
- **Effects**: status → `BANNED`; machine removed from the active set; emits [`TeeMachineStatusChanged`](../Reference/Contracts/FlareTeeManagerEvents.md#teemachinestatuschanged). No automatic return is possible.

### unban: BANNED → PAUSED

- **Action**: [`FlareTeeManager.unban(teeId)`](../Reference/Contracts/FlareTeeManager.md#management-calls) — non-payable.
- **Caller**: extension owner.
- **Effects**: status → `PAUSED`; emits [`TeeMachineStatusChanged`](../Reference/Contracts/FlareTeeManagerEvents.md#teemachinestatuschanged). Returning to `PRODUCTION` requires a fresh `toProduction(proof)`.

## Invariants

- `lastStatusChangeTs` updates on every status transition.
- A machine is in the active set exactly when its `status = PRODUCTION`.
- `BANNED` is reachable from `{PRODUCTION, SUSPENDED, PAUSED}` and exits only to `PAUSED` via `unban`.
- After `updateSettings` from `PRODUCTION`/`SUSPENDED`, an availability proof is mandatory to return to `PRODUCTION`.

## Terminal States

None of the running states are terminal — the machine can be cycled through them indefinitely. `BANNED` is sticky (only `unban` exits), but not terminal.

## Notes

- The "batch pause" idiom is simply calling `pauseByOwner` or `pauseOnDeadlineExpiry` over many machines in one transaction or many; the contract has no dedicated bulk entry.
- The `confirmAvailability` deadline refresh is what keeps a `PRODUCTION` machine reward-eligible; operators typically automate it on a schedule shorter than the deadline window.