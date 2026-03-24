# Post-Registration Machine Lifecycle

## Overview

After a TEE machine reaches `PRODUCTION` status (see [machine-registration.md](machine-registration.md)), the machine owner can perform management operations including pausing, updating settings, transferring ownership, confirming availability, and governance-level banning.
For full details, see [Ownership](../TEE%20Management/Ownership.md) and [State and Status](../TEE%20Management/State%20and%20Status.md).

### Status Transition Diagram

The following diagram shows the implemented machine statuses and the transitions between them:

```
                          register()
                              |
                              v
                        INITIALIZED
                              |
                    toProduction(proof)
                              |
                              v
                        PRODUCTION
                       /    |    \
                      /     |     \
                     v      v      v
              SUSPENDED  PAUSED  updateTeeMachineSettings()
                 |         |          |
                 |         |          v
                 |         |        PAUSED
                 |         |
                 +--pause()--> PAUSED
                 |
              PAUSED --- toProduction(proof) ---> PRODUCTION
                 ^
                 |
             SUSPENDED --- pause() ---> PAUSED

                PAUSED, SUSPENDED, or PRODUCTION
                        |
                    ban() (extension owner)
                        |
                        v
                     BANNED
                        |
                    unban() (extension owner)
                        |
                        v
                     PAUSED
```

For full status definitions, see the [Ownership specification](../TEE%20Management/Ownership.md#statuses).

## Prerequisites

- The TEE machine must be registered on the `TeeMachineRegistry` smart contract.
- For most operations, the machine should be in `PRODUCTION` status (completed via `toProduction(proof)` as described in [machine-registration.md](machine-registration.md)). Note that `toProduction(proof)` works from both `INITIALIZED` and `PAUSED` statuses and requires a valid `TeeAvailabilityCheck` proof and a supported code version.
- The caller must have the appropriate role (owner, governance, or anyone -- depending on the operation).
- For proof-based operations, a valid `TeeAvailabilityCheck` FDC2 proof is required (see [fdc2-attestation.md](fdc2-attestation.md)).

---

## Steps

### Step 1: Pause with Proof -- `TeeMachineRegistry.pauseWithProof()`

**Who can call:** Anyone.

**Parameters:**

- `proof` (`ITeeAvailabilityCheck.Proof`) -- a `TeeAvailabilityCheck` proof that is either invalid or shows a non-`OK` status.

**Requirements:**

- The machine must be in `PRODUCTION` status.
- The proof must be either invalid (fails verification) or have a non-`OK` response status.
- The proof timestamp must be $\geq$ `lastStatusChangeTs`.

**What happens:**

1. The caller submits a `TeeAvailabilityCheck` proof for the target machine.
2. The contract validates the proof timestamp against the machine's last status change.
3. The machine status changes to `SUSPENDED`.
4. `lastStatusChangeTs` is updated to `block.timestamp`.

**Events emitted:** `TeeMachineStatusChanged(teeId, newStatus)`

**Procedure:**

To obtain a non-availability proof and pause a machine:

1. Call `TeeVerification.requestTeeAttestation(teeId)` to trigger a TEE attestation on the target machine.
2. Call `TeeVerification.requestAvailabilityCheckAttestation(teeId, teeAttestInstructionId, externalTeeId)` to request an FDC2 availability check using an external TEE. Parse the `TeeInstructionsSent` event to obtain the `instructionId`.
3. Poll `<proxyUrl>/action/result/<instructionId>` until the proof is available.
4. Call `TeeMachineRegistry.pauseWithProof(proof)` with the retrieved proof.

**What happens automatically:**

The FDC2 verifier TEE challenges the target machine and determines its availability status. If the machine is unreachable or fails verification checks, the proof will contain status `DOWN`, which is required for `pauseWithProof()` to succeed. See [fdc2-attestation.md](fdc2-attestation.md) for details on the TeeAvailabilityCheck attestation process.

---

### Step 2: Owner Pause -- `TeeMachineRegistry.pause()`

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

**Events emitted:** `TeeMachineStatusChanged(teeId, newStatus)`

---

### Step 3: Batch Pause Inactive Machines

Batch pausing is not a single dedicated contract function. Instead, the `pause()` function can be called by anyone when a machine's code version is no longer supported by the extension. In practice, an operator or automated process can iterate over machines with unsupported code versions and call `pause(teeId)` for each one, effectively performing a batch pause of inactive or obsolete machines. Note that `pause()` works from both `PRODUCTION` and `SUSPENDED` statuses.

Additionally, `pauseWithProof()` can be called by anyone with a valid non-availability proof, allowing community-driven suspension of machines that have gone offline (moves `PRODUCTION` to `SUSPENDED`).

---

### Step 4: Machine Settings Update -- `TeeMachineRegistry.updateTeeMachineSettings()`

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

**Events emitted:** `TeeMachineSettingsUpdated(teeId, teeProxyId, url)` and `TeeMachineStatusChanged(teeId, PAUSED)` if the machine was in `PRODUCTION` or `SUSPENDED` status.

---

### Step 5: Machine Ownership Transfer -- `TeeMachineRegistry.proposeNewOwner()` and `TeeMachineRegistry.confirmOwnership()`

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

**Events emitted:** `NewOwnerProposed(teeId, oldOwner, newOwner)`

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

**Events emitted:** `NewOwnerConfirmed(teeId, newOwner)`

Note: A TEE id can only be transferred to a new owner through this ownership change process while registered. This prevents re-registration of the machine under other owners if it is temporarily unregistered.

---

### Step 6: Periodic Availability Confirmation -- `TeeVerification.confirmAvailability()`

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

**Events emitted:** `AvailabilityCheckValidityExtended(teeId, owner, endTs)` (only if the deadline was extended).

Note: When a machine enters `PRODUCTION` via `toProduction(proof)`, it is considered in production only up to the `availabilityCheckValidityEndTs` deadline. The `confirmAvailability()` function on the `TeeVerification` contract must be called periodically before this deadline to maintain eligibility.

---

### Step 7: Ban and Unban -- `TeeMachineRegistry.ban()` and `TeeMachineRegistry.unban()`

### Step 7a: Ban -- `ban()`

**Who can call:** Extension owner only.

**Parameters:**

- `teeId` (`address`) -- the TEE identity address of the machine to ban.

**Requirements:**

- The caller must be the owner of the extension to which the TEE is registered.
- The machine must be in `PAUSED`, `SUSPENDED`, or `PRODUCTION` status.

**What happens:**

1. The extension owner calls `ban(teeId)`.
2. The machine status changes to `BANNED`.
3. The machine cannot operate in any capacity.
4. `lastStatusChangeTs` is updated to `block.timestamp`.

**Events emitted:** `TeeMachineStatusChanged(teeId, BANNED)`

### Step 7b: Unban -- `unban()`

**Who can call:** Extension owner only.

**Parameters:**

- `teeId` (`address`) -- the TEE identity address of the machine to unban.

**Requirements:**

- The machine must be in `BANNED` status.
- The caller must be the owner of the extension to which the TEE is registered.

**What happens:**

1. The extension owner calls `unban(teeId)`.
2. The machine status changes from `BANNED` to `PAUSED`.
3. A new `TeeAvailabilityCheck` proof is required to return the machine to `PRODUCTION` via `toProduction(proof)`.
4. `lastStatusChangeTs` is updated to `block.timestamp`.

**Events emitted:** `TeeMachineStatusChanged(teeId, PAUSED)`

