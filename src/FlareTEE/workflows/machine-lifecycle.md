# Post-Registration Machine Lifecycle

## Overview

After a TEE machine is registered and moved to `PRODUCTION` status (see [machine-registration.md](machine-registration.md)), the machine owner and other parties can perform a variety of management operations. These include pausing, updating settings, transferring ownership, confirming periodic availability, upgrading to new code versions, and governance-level banning.

All management functions are available on the `TeeMachineRegistry` smart contract. When any function changes the machine status, `lastStatusChangeTs` is updated to the current `block.timestamp`.

For full details, see the [Ownership specification](../TEE%20Management/Ownership.md) and [State and Status specification](../TEE%20Management/State%20and%20Status.md).

## Prerequisites

- The TEE machine must be registered on the `TeeMachineRegistry` smart contract.
- For most operations, the machine should be in `PRODUCTION` status (completed via `toProduction(proof)` as described in [machine-registration.md](machine-registration.md)). Note that `toProduction(proof)` works from both `INITIALIZED` and `PAUSED` statuses and requires a valid `TeeAvailabilityCheck` proof and a supported code version.
- The caller must have the appropriate role (owner, governance, or anyone -- depending on the operation).
- For proof-based operations, a valid `TeeAvailabilityCheck` FTDC proof is required (see [ftdc-attestation.md](ftdc-attestation.md)).

---

## Status Transition Diagram

The following diagram shows all 7 machine statuses and the transitions between them:

```
                          register()
                              |
                              v
                        INITIALIZED
                       /           \
          toProduction(proof)    replicateFrom() [NOT IMPLEMENTED]
                     /                 \
                    v                   v
              PRODUCTION           REPLICATING
             /    |    \
            /     |     \
           v      v      v
    SUSPENDED  PAUSED  updateTeeMachineSettings()
       |         |          |
       |         |          v
       |         |        PAUSED
       |         |
       |    toPauseForUpgrade() [NOT IMPLEMENTED]
       |         |
       |         v
       |   PAUSED_FOR_UPGRADE [NOT IMPLEMENTED]
       |         |
       |    replicateFrom() [NOT IMPLEMENTED]
       |         |
       |         v
       |    REPLICATING [NOT IMPLEMENTED]
       |
       +--pause()--> PAUSED
       |
    PAUSED --- toProduction(proof) ---> PRODUCTION
       ^
       |
   SUSPENDED --- pause() ---> PAUSED

          PAUSED, SUSPENDED, or PRODUCTION
                  |
              ban() (governance)
                  |
                  v
               BANNED
                  |
              unban() (governance)
                  |
                  v
               PAUSED
```

**Status summary:**

| Status | Description |
|--------|-------------|
| `INITIALIZED` | After registration, not yet verified. Can transition to `PRODUCTION` (or `REPLICATING`, but not implemented). |
| `PRODUCTION` | Fully operational, accepts all instructions. Can be paused, suspended, or banned. |
| `SUSPENDED` | Paused via `pauseWithProof()` based on a non-availability proof. Can transition to `PAUSED` via `pause()` or be banned. |
| `PAUSED` | Paused by owner, unsupported code version, settings update, or unban. Can return to `PRODUCTION` with a new availability proof. |
| `PAUSED_FOR_UPGRADE` | Not operational but can serve as replication source. **Contract exists but TEE command NOT IMPLEMENTED.** |
| `REPLICATING` | Currently being replicated to from another machine during an upgrade. **Contract exists but TEE command NOT IMPLEMENTED.** |
| `BANNED` | Banned by governance. Can only be reversed by `unban()`, which moves to `PAUSED`. |

---

## Step 1: Pause with Proof -- `TeeMachineRegistry.pauseWithProof()`

**Who can call:** Anyone.

**Parameters:**

- `proof` (`ITeeAvailabilityCheckProof`) -- a non-availability proof using the `TeeAvailabilityCheck` attestation type. The proof must show that the machine is not available (status `DOWN`).

**Requirements:**

- The machine must be in `PRODUCTION` status.
- The timestamp of the proof must not be older than 10 minutes.

**What happens:**

1. The caller submits a `TeeAvailabilityCheck` proof demonstrating that the target machine is unavailable.
2. The contract validates the proof timestamp is within the 10-minute window.
3. The machine status changes to `SUSPENDED`.
4. `lastStatusChangeTs` is updated to `block.timestamp`.

**Events emitted:** Status change event for the TEE machine.

**Procedure:**

To obtain a non-availability proof and pause a machine:

1. Call `TeeVerification.requestTeeAttestation(teeId)` to trigger a TEE attestation on the target machine.
2. Call `TeeVerification.requestAvailabilityCheckAttestation(teeId, teeAttestInstructionId, externalTeeId)` to request an FTDC availability check using an external TEE. Parse the `TeeInstructionsSent` event to obtain the `instructionId`.
3. Poll `<proxy_url>/action/result/<instructionId>` until the proof is available.
4. Call `TeeMachineRegistry.pauseWithProof(proof)` with the retrieved proof.

**What happens automatically:**

The FTDC verifier TEE challenges the target machine and determines its availability status. If the machine is unreachable or fails verification checks, the proof will contain status `DOWN`, which is required for `pauseWithProof()` to succeed. See [ftdc-attestation.md](ftdc-attestation.md) for details on the TeeAvailabilityCheck attestation process.

---

## Step 2: Owner Pause -- `TeeMachineRegistry.pause()`

**Who can call:** The machine owner. Also callable by anyone if the current TEE code version is no longer supported.

**Parameters:**

- `teeId` (`address`) -- the TEE identity address of the machine to pause.

**Requirements:**

- The machine must be in `PRODUCTION` or `SUSPENDED` status.

**What happens:**

1. The caller submits the pause request for the specified `teeId`.
2. The contract verifies the caller is the owner (or that the code version is unsupported).
3. The machine status changes to `PAUSED`.
4. `lastStatusChangeTs` is updated to `block.timestamp`.

**Events emitted:** Status change event for the TEE machine.

---

## Step 3: Batch Pause Inactive Machines

Batch pausing is not a single dedicated contract function. Instead, the `pause()` function can be called by anyone when a machine's code version is no longer supported by the extension. In practice, an operator or automated process can iterate over machines with unsupported code versions and call `pause(teeId)` for each one, effectively performing a batch pause of inactive or obsolete machines. Note that `pause()` works from both `PRODUCTION` and `SUSPENDED` statuses.

Additionally, `pauseWithProof()` can be called by anyone with a valid non-availability proof, allowing community-driven suspension of machines that have gone offline (moves `PRODUCTION` to `SUSPENDED`).

---

## Step 4: Machine Settings Update -- `TeeMachineRegistry.updateTeeMachineSettings()`

**Who can call:** The machine owner.

**Parameters:**

- `teeId` (`address`) -- the TEE identity address.
- `teeProxyId` (`address`) -- the new proxy identity address.
- `url` (`string`) -- the new URL of the TEE machine.

**Requirements:**

- The caller must be the machine owner.
- The machine must be in `PRODUCTION` or `SUSPENDED` status.

**What happens:**

1. The owner submits updated proxy ID and URL for the machine.
2. The contract updates the machine record with the new `teeProxyId` and `url`.
3. The machine status changes to `PAUSED`. A new `TeeAvailabilityCheck` proof is required to return it to `PRODUCTION` via `toProduction(proof)`.
4. `lastStatusChangeTs` is updated to `block.timestamp`.

**Events emitted:** Status change event and settings update event for the TEE machine.

---

## Step 5: Machine Ownership Transfer -- `TeeMachineRegistry.proposeNewOwner()` and `TeeMachineRegistry.confirmOwnership()`

This is a two-step process to prevent accidental transfers.

### Step 5a: Propose New Owner -- `proposeNewOwner()`

**Who can call:** The current machine owner.

**Parameters:**

- `teeId` (`address`) -- the TEE identity address.
- `newOwner` (`address`) -- the proposed new owner's Flare address.

**Requirements:**

- The caller must be the current owner.

**What happens:**

1. The owner proposes a new owner for the TEE machine.
2. The proposed owner address is recorded on the contract.
3. No status change occurs.

**Events emitted:** Ownership proposal event.

### Step 5b: Confirm Ownership -- `confirmOwnership()`

**Who can call:** The proposed new owner.

**Parameters:**

- `teeId` (`address`) -- the TEE identity address.

**Requirements:**

- The caller must be the address that was proposed as the new owner.

**What happens:**

1. The proposed new owner confirms acceptance of ownership.
2. The machine's `owner` field is updated to the new address.
3. The previous owner loses all management rights.

**Events emitted:** Ownership transfer event.

Note: A TEE id can only be transferred to a new owner through this ownership change process while registered. This prevents re-registration of the machine under other owners if it is temporarily unregistered.

---

## Step 6: Periodic Availability Confirmation -- `TeeVerification.confirmAvailability()`

**Who can call:** Anyone.

**Contract:** `TeeVerification` (not `TeeMachineRegistry`).

**Parameters:**

- `proof` (`ITeeAvailabilityCheckProof`) -- a valid `TeeAvailabilityCheck` proof for the machine.

**Requirements:**

- The machine must be in `PRODUCTION` status.
- The proof must be valid and demonstrate the machine is available (status `OK`).

**What happens:**

1. The caller submits a `TeeAvailabilityCheck` proof for the machine to the `TeeVerification` contract.
2. The contract validates the proof.
3. The `availabilityCheckValidityEndTs` deadline is extended.
4. If the deadline passes without confirmation, the machine becomes ineligible for reward shares (see Rewarding -- not yet published).

**Events emitted:** Availability confirmation event.

Note: When a machine enters `PRODUCTION` via `toProduction(proof)`, it is considered in production only up to the `availabilityCheckValidityEndTs` deadline. The `confirmAvailability()` function on the `TeeVerification` contract must be called periodically before this deadline to maintain eligibility.

---

## Step 7: Machine Upgrade Workflow

> **NOT IMPLEMENTED:** The machine upgrade workflow is planned but not yet implemented. The following documents the intended design from the specification.
>
> **Implementation Status Note:** The `REPLICATE_FROM` and `TO_PAUSE_FOR_UPGRADE` TEE-node commands are not yet active in the current code version. While the corresponding smart contract functions (`toPauseForUpgrade()`, `replicateFrom()`, `confirmReplicate()`) exist on the `teeReplication` contract on-chain, the TEE-side command processors for these operations are not registered in the node software (they are commented out in `op.go`). Attempting to trigger these workflows will result in the contract emitting instructions that the TEE node cannot process.

The upgrade procedure allows an owner to migrate a TEE machine to a new code version by replicating its state to a new machine. The essential parts of state that are replicated include the identity private key and all wallet private keys (excluding machine-specific variables such as nonces).

### Step 7a: Pause for Upgrade -- `toPauseForUpgrade()`

> **Not Yet Active:** The `TO_PAUSE_FOR_UPGRADE` command processor is not registered in the current TEE node code (commented out in `op.go`). The contract function exists but the TEE-side handling is inactive.

**Who can call:** The machine owner.

**Parameters:**

- `teeId` (`address`) -- the TEE identity address of the old machine.

**Requirements:**

- The machine status must be `PAUSED` or `PAUSED_FOR_UPGRADE`.
- If the status is `PAUSED`, can only be called after 10 minutes from the last status change.

**What happens:**

1. The owner calls `toPauseForUpgrade(oldMachineTeeId)` on the old machine.
2. The machine enters `PAUSED_FOR_UPGRADE` status.
3. The `TO_PAUSE_FOR_UPGRADE` [instruction](../Operations/Instructions.md) command is triggered.
4. `lastStatusChangeTs` is updated to `block.timestamp`.
5. This is a final status -- the machine can only serve as a replication source from this point.

**Events emitted:** Status change event.

### Step 7b: Replicate From -- `replicateFrom()`

> **Not Yet Active:** The `REPLICATE_FROM` command processor is not registered in the current TEE node code (commented out in `op.go`). The contract function exists but the TEE-side handling is inactive.

**Who can call:** The machine owner (on the new machine).

**Parameters:**

- `oldTeeId` (`address`) -- the TEE identity of the old machine to replicate from.
- `proof` (`ITeeAvailabilityCheckProof`) -- availability check proof for the new machine.
- `signedUpgradePath` -- signed upgrade path from the old to the new code version (see Governance -- not yet published).

**Requirements:**

- The new machine's status must be `INITIALIZED` or `REPLICATING` (for retries).
- The old machine must be in `PAUSED_FOR_UPGRADE` status.
- The proof must be valid for the new machine.

**What happens:**

1. The owner triggers the `REPLICATE_FROM` command on the new machine.
2. The new machine enters `REPLICATING` status.
3. The new machine receives the old machine's state (identity key, wallet keys).
4. `lastStatusChangeTs` is updated to `block.timestamp`.

**Events emitted:** Status change event and replication initiation event.

### Step 7c: Confirm Replicate -- `confirmReplicate()`

**Who can call:** The machine owner.

**Parameters:**

- `newTeeId` (`address`) -- the TEE identity of the new machine.
- `proof` (`ITeeAvailabilityCheckProof`) -- proof for the new machine with the old TEE id at the new machine's URL. The proof must have a timestamp later than both machines' timestamps.

**Requirements:**

- The new machine must be in `REPLICATING` status.
- The proof must show the new machine's URL with the old TEE id.

**What happens:**

1. The owner confirms that replication was successful.
2. The new machine is registered with the old TEE id.
3. The new machine's status changes to `PRODUCTION`.
4. `lastStatusChangeTs` is updated to `block.timestamp`.

**Events emitted:** Status change event and replication confirmation event.

### Full Upgrade Sequence

1. Register a new machine with the updated code version.
2. Call `toPauseForUpgrade(oldMachineTeeId)` -- old machine enters `PAUSED_FOR_UPGRADE`.
3. Call `replicateFrom(oldTeeId, proof, signedUpgradePath)` -- new machine enters `REPLICATING`.
4. The new machine identifies with the replicated identity.
5. Call `confirmReplicate(newTeeId, proof)` -- new machine enters `PRODUCTION` with the old TEE id.

---

## Step 8: Ban and Unban -- `TeeMachineRegistry.ban()` and `TeeMachineRegistry.unban()`

### Step 8a: Ban -- `ban()`

**Who can call:** Governance only.

**Parameters:**

- `teeId` (`address`) -- the TEE identity address of the machine to ban.

**Requirements:**

- The caller must have governance privileges.
- The machine must be in `PAUSED`, `SUSPENDED`, or `PRODUCTION` status.

**What happens:**

1. Governance calls `ban(teeId)`.
2. The machine status changes to `BANNED`.
3. The machine cannot operate in any capacity.
4. `lastStatusChangeTs` is updated to `block.timestamp`.

**Events emitted:** Status change event (ban).

### Step 8b: Unban -- `unban()`

**Who can call:** Governance only.

**Parameters:**

- `teeId` (`address`) -- the TEE identity address of the machine to unban.

**Requirements:**

- The machine must be in `BANNED` status.
- The caller must have governance privileges.

**What happens:**

1. Governance calls `unban(teeId)`.
2. The machine status changes from `BANNED` to `PAUSED`.
3. A new `TeeAvailabilityCheck` proof is required to return the machine to `PRODUCTION` via `toProduction(proof)`.
4. `lastStatusChangeTs` is updated to `block.timestamp`.

**Events emitted:** Status change event (unban).

---

## Further Resources

| Step | Reference Implementation |
|------|------------------------|
| Step 1 (pause with proof) | `e2e/pkg/utils/pause.go` (`PauseNode`) |
