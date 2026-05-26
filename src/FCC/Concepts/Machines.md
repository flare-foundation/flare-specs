# Machines

A _TEE machine_ is one TEE-running node registered with FCC, identified by a unique $\mathrm{TEE}_\mathrm{ID}$ — the address of its identity public key, generated inside the enclave at boot.
Around that identity, the machine carries state a fresh replica would not share by default: keys, signing policies, status, and any extension-defined state.

This page covers identity, the state model, the attestation procedure, registration, and the status lifecycle.
For the contract surface (function signatures, struct fields, management-call catalog), see [`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md).

## Identity

- Boot-time key pair $(\mathrm{TEE}_\mathrm{pk}, \mathrm{TEE}_\mathrm{sk})$ generated inside the enclave; $\mathrm{TEE}_\mathrm{sk}$ never leaves it.
- $\mathrm{TEE}_\mathrm{ID}$ — the last $20$ bytes of $\mathrm{keccak256}(\mathrm{TEE}_\mathrm{pk})$. _Not_ the address of the registering operator (the [TEE operator](../../Terminology/Roles.md#tee-operator), recorded separately as the machine's [owner](#owner-allowlist)).
- On Flare, $\mathrm{TEE}_\mathrm{pk}$ is held as a [`PublicKey`](../Reference/Types/Abi/Common.md#publickey) struct on [`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md).
- _Initial identity_ $\mathrm{TEE}_\mathrm{ID}^*$ — equal to $\mathrm{TEE}_\mathrm{ID}$ for a fresh registration; after [replication](../Workflows/MachineReplication.md), the persistent slot's $\mathrm{TEE}_\mathrm{ID}^*$ records the _successor_'s original $\mathrm{TEE}_\mathrm{ID}$ (the identity of the new hardware now backing the slot).
- Owner changes go through the two-step ownership-transfer flow on [`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md#management-calls).

## Signing Policy

A TEE machine cannot accept signed instructions unless it knows the current [signing policy](../../FSP/SigningPolicy.md).
The first policy is installed at registration as part of the initial [attestation](#attestation); subsequent policies are pushed by the [TEE proxy](../Reference/Components/Proxy.md) via [`UPDATE_POLICY`](../Reference/Operations/F_POLICY.md#update_policy) at every reward-epoch boundary.

## TEE State

The TEE's state is the part of its content that a fresh replica would not share by default:

- Identity key pair $(\mathrm{TEE}_\mathrm{pk}, \mathrm{TEE}_\mathrm{sk})$.
- All [wallet keys](Keys.md) and key backups held for [PMW](../../PMW/README.md) or any other key-custody [FCE](../FCE/README.md).
- System state variables — initial and current signing policies, machine status, configuration nonce, pausing nonce.
- Any [extension-defined state](../FCE/Concepts.md) added by the FCE the machine is registered to.

On replication, the identity key pair and all wallet keys and backups transfer to the successor; machine-local nonces do not.

### Encoding

State is serialized as a [`TeeState`](../Reference/Types/Abi/TeeMachine.md#teestate) struct with two parts:

- **System state** — defined by Flare; covers FCC-framework variables.
- **Extension state** — defined by the FCE; surfaced through the FCE's `/state` endpoint.

Each part is keyed by a `bytes32` version hash (`systemStateVersion`, `stateVersion`); version `0` (32-byte zero) encodes both bodies as empty `bytes`.

## Attestation

A TEE machine attests to elements of its [state](#tee-state) when challenged.
A _challenger_ provides a $32$-byte challenge; the machine builds an [`Attestation`](../Reference/Types/Abi/TeeMachine.md#attestation) struct from the challenge and its own state:

- `challenge` — the challenger's $32$-byte input.
- `publicKey` — TEE identity public key.
- `initialSigningPolicyId`, `initialSigningPolicyHash` — first signing policy known to the machine.
- `lastSigningPolicyId`, `lastSigningPolicyHash` — most recent signing policy known to the machine.
- `state` — ABI-encoded [`TeeState`](../Reference/Types/Abi/TeeMachine.md#teestate) at attestation time.
- `teeTimestamp` — local machine timestamp at attestation time.

The machine ABI-encodes the struct, hashes it ($\mathrm{hash}(\mathrm{Attestation})$), and passes the digest to the TEE platform operator's attestation service (Google for Intel TDX and AMD SEV); the platform's signed response binds the digest to the hardware-attested boot state.

For the FDC2 attestation type that wraps this procedure into an on-chain proof, see [`TeeAvailabilityCheck`](../../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md).

## Owner Allowlist

Three allowlists gate the FCC owner roles:

- _machine owner_ — the Flare address that registers and owns a TEE machine on an extension. Per-extension list maintained by the [extension owner](../../Terminology/Roles.md#extension-owner).
- _wallet [project owner](../../Terminology/Roles.md#project-owner)_ — the Flare address that creates wallet projects under an extension. Per-extension list maintained by the extension owner.
- _[extension owner](../../Terminology/Roles.md#extension-owner)_ — the Flare address that registers and owns an extension (`register`, two-step ownership transfer). Single global list maintained by immediate [governance](../../Terminology/Roles.md#governance).

Checked on registration, ownership changes, and project creation; each list has an "allow-all" toggle for fully public participation.

For the management calls, see [`FlareTeeManager § Owner Allowlist`](../Reference/Contracts/FlareTeeManager.md#owner-allowlist).

## Registration

A TEE operator [registers](../Reference/Contracts/FlareTeeManager.md#registration) a machine by submitting:

- a `teeMachineData` struct — extension to join, code hash and platform, identity public key, initial owner.
- a signature by the identity key proving possession of the corresponding private key.

The contract recovers the signer and stores it as the machine's `teeId`; the signature is what prevents an operator from registering a `teeId` whose private key they do not control.
A freshly-registered machine sits in [`INITIALIZED`](#statuses); it cannot serve traffic until it presents a valid [`TeeAvailabilityCheck`](../../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md) proof.

## Statuses

A registered machine moves through seven statuses:

1. **`INITIALIZED`** — set by `register`. No rights yet; transition to `PRODUCTION` requires a valid availability proof.
2. **`PRODUCTION`** — fully operational; accepts instructions. Owner may pause; anyone may suspend after the [availability deadline](#availability-deadline) expires.
3. **`SUSPENDED`** — set on a non-`OK` [`TeeAvailabilityCheck`](../../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md) proof or after the availability deadline. Can return to `PRODUCTION` with a fresh proof, be paused, or be banned.
4. **`PAUSED`** — owner-initiated stop, or automatic on settings update or unsupported code. No instructions accepted. Return to `PRODUCTION` requires a fresh availability proof.
5. **`PAUSED_FOR_UPGRADE`** — owner-initiated, prepares the machine for [replication](../Workflows/MachineReplication.md). Entered from `PAUSED` after a minimum dwell.
6. **`REPLICATING`** — a successor machine is taking over this machine's identity and key set; reached from `PAUSED_FOR_UPGRADE` on a successful availability proof from the successor.
7. **`BANNED`** — extension-owner only; reversal lands the machine in `PAUSED`.

Each transition emits `TeeMachineStatusChanged`.

### Availability Deadline

Each [`TeeAvailabilityCheck`](../../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md) proof extends the machine's validity deadline — the `endTs` field of its `AvailabilityCheckValidity` record.
Before the deadline anyone may submit a fresh proof; after it the machine stays in `PRODUCTION` but:

- its actions stop entitling its owner to [rewards](../../FSP/Rewarding.md).
- anyone may suspend it; a fresh proof brings it back.

Operators must refresh availability before expiry to avoid downtime.

For per-call rules, see [`FlareTeeManager § Management Calls`](../Reference/Contracts/FlareTeeManager.md#management-calls).
