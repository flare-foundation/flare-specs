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
- For most operations, the machine should be in `PRODUCTION` status (completed via `toProduction(proof)` as described in [machine-registration.md](machine-registration.md)). Note that `toProduction(proof)` works from both `INITIALIZED` and `PAUSED` statuses and requires a valid [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md) proof and a supported code version.
- The caller must have the appropriate role (owner, governance, or anyone -- depending on the operation).
- For proof-based operations, a valid [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md) FDC2 proof is required (see [fdc2-attestation.md](fdc2-attestation.md)).

---

## Steps

### Step 1: Pause with Proof -- `TeeMachineRegistry.pauseWithProof()`

**Who can call:** Anyone.

**Parameters:**

- `proof` (`ITeeAvailabilityCheck.Proof`) -- a [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md) proof that is either invalid or shows a non-`OK` status.

**Requirements:**

- The machine must be in `PRODUCTION` status.
- The proof must be either invalid (fails verification) or have a non-`OK` response status.
- The proof timestamp must be $\geq$ `lastStatusChangeTs`.

**What happens:**

1. The caller submits a [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md) proof for the target machine.
2. The contract validates the proof timestamp against the machine's last status change.
3. The machine status changes to `SUSPENDED`.
4. `lastStatusChangeTs` is updated to `block.timestamp`.

**Events emitted:** [`TeeMachineStatusChanged`](../Events.md#teemachinestatuschanged)

**Procedure:**

To obtain a non-availability proof and pause a machine:

1. Call `TeeVerification.requestTeeAttestation(teeId, claimBackAddress)` to trigger a TEE attestation on the target machine.
2. Call `TeeVerification.requestAvailabilityCheckAttestation(teeId, instructionId, testOnTeeId, proofOwner, claimBackAddress)` to request an FDC2 availability check. Parse the [`TeeInstructionsSent`](../Events.md#teeinstructionssent) event to obtain the `instructionId`.
3. Poll `<proxyUrl>/action/result/<instructionId>` until the proof is available.
4. Call `TeeMachineRegistry.pauseWithProof(proof)` with the retrieved proof.

**What happens automatically:**

The FDC2 verifier TEE challenges the target machine and determines its availability status. If the machine is unreachable or fails verification checks, the proof will contain status `DOWN`, which is required for `pauseWithProof()` to succeed. See [fdc2-attestation.md](fdc2-attestation.md) for details on the TeeAvailabilityCheck attestation process.

---

### Step 2: Pause -- `TeeMachineRegistry.pause()`

The `pause()` function handles two distinct paths depending on the caller and conditions:

**Parameters:**

- `teeId` (`address`) -- the TEE identity address of the machine to pause.

**Path 1 — Owner or disabled code version → `PAUSED`:**

**Who can call:** The machine owner, or anyone if the machine's code version has been disabled.

**Requirements:**
- The machine must be in `PRODUCTION` or `SUSPENDED` status.

**What happens:**
1. The machine status changes to `PAUSED`.
2. The machine is removed from the active pools.
3. `lastStatusChangeTs` is updated to `block.timestamp`.

**Path 2 — Expired availability deadline → `SUSPENDED`:**

**Who can call:** Anyone.

**Requirements:**
- The machine must be in `PRODUCTION` status.
- The machine's availability check deadline (`endTs`) must have expired.

**What happens:**
1. The machine status changes to `SUSPENDED`.
2. The machine is removed from the active pools.
3. `lastStatusChangeTs` is updated to `block.timestamp`.

**Events emitted:** [`TeeMachineStatusChanged`](../Events.md#teemachinestatuschanged)

---

### Step 3: Batch Pause Inactive Machines

Batch pausing is not a single dedicated contract function.
Anyone can batch-call `pause(teeId)` in two scenarios:

- **Disabled code version:** If a machine's code version is no longer supported, anyone can call `pause()` to move it from `PRODUCTION` or `SUSPENDED` to `PAUSED`.
- **Expired availability deadline:** If a machine's availability check deadline has expired, anyone can call `pause()` to move it from `PRODUCTION` to `SUSPENDED`.

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
- `teeProxyId` must not be the zero address.
- `url` must not be empty.

**What happens:**

1. The contract updates the machine record with the new `teeProxyId` and `url`.
2. If the machine is in `PRODUCTION` or `SUSPENDED` status, the status changes to `PAUSED`, the machine is removed from the active pools, and a new [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md) proof is required to return to `PRODUCTION`.
3. If the machine is in any other status (`INITIALIZED`, `PAUSED`), only the settings are updated — no status change occurs.

**Events emitted:** [`TeeMachineSettingsUpdated`](../Events.md#teemachinesettingsupdated), and [`TeeMachineStatusChanged`](../Events.md#teemachinestatuschanged) if the machine was in `PRODUCTION` or `SUSPENDED` status.

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
- The `newOwner` must be allowlisted for the extension via the `TeeOwnerAllowlist` contract, or `address(0)` to cancel a pending proposal.

**What happens:**

1. The owner proposes a new owner for the TEE machine.
2. The proposed owner address is recorded on the contract.
3. No status change occurs.

**Events emitted:** [`NewOwnerProposed`](../Events.md#newownerproposed)

### Step 5b: Confirm Ownership -- `confirmOwnership()`

**Who can call:** The proposed new owner.

**Parameters:**

- `teeId` (`address`) -- the TEE identity address.

**Requirements:**

- The caller must be the address that was proposed as the new owner.
- The caller must still be allowlisted for the extension at confirmation time.

**What happens:**

1. The proposed new owner confirms acceptance of ownership.
2. The machine's `owner` field is updated to the new address.
3. The previous owner loses all management rights.

**Events emitted:** [`NewOwnerConfirmed`](../Events.md#newownerconfirmed)

Note: A TEE id can only be transferred to a new owner through this ownership change process while registered. This prevents re-registration of the machine under other owners if it is temporarily unregistered.

---

### Step 6: Periodic Availability Confirmation -- `TeeVerification.confirmAvailability()`

**Who can call:** Anyone.

**Contract:** `TeeVerification` (not `TeeMachineRegistry`).

**Parameters:**

- `proof` (`ITeeAvailabilityCheck.Proof`) -- a valid [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md) proof for the machine.

**Requirements:**

- The machine must be in `PRODUCTION` status.
- The proof's `responseBody.status` must be `OK`.
- The machine's `codeHash` and `platform` must still be supported by the extension.
- The proof must be valid and match the machine's current data.

**What happens:**

1. The caller submits a [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md) proof for the machine to the `TeeVerification` contract.
2. The contract validates the proof.
3. The `availabilityCheckValidityEndTs` deadline is extended.
4. The contract updates `lastSigningPolicyId` from the proof's response body.
5. If the deadline passes without confirmation, the machine becomes ineligible for reward shares.

**Events emitted:** [`AvailabilityCheckValidityExtended`](../Events.md#availabilitycheckvalidityextended) (only if the deadline was extended).

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
3. The machine is removed from the active pools, preventing it from being selected for any tasks.
4. `lastStatusChangeTs` is updated to `block.timestamp`.

**Events emitted:** [`TeeMachineStatusChanged`](../Events.md#teemachinestatuschanged)

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
3. A new [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md) proof is required to return the machine to `PRODUCTION` via `toProduction(proof)`.
4. `lastStatusChangeTs` is updated to `block.timestamp`.

**Events emitted:** [`TeeMachineStatusChanged`](../Events.md#teemachinestatuschanged)

