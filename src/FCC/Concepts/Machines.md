# Machines

A _TEE machine_ is a container running the [node app](../Reference/Components/Machine.md) (and, for custom extensions, an [extension app](../Reference/Components/Machine.md)) inside a hardware-attested enclave on a cloud [TEE platform](../../Terminology/Concepts.md#tee-substrate).

## Identity

- _Identity key pair_ $(\mathrm{TEE}_\mathrm{pub}, \mathrm{TEE}_\mathrm{priv})$ — public and private keys generated inside the enclave at boot; $\mathrm{TEE}_\mathrm{priv}$ is never exposed outside an attested enclave.
- $\mathrm{TEE}_\mathrm{ID}$ — the [address](../../Terminology/Concepts.md#addresses-accounts-and-keys) of $\mathrm{TEE}_\mathrm{pub}$; the machine's permanent on-chain identity.
- $\mathrm{TEE}_\mathrm{pub}$ is held as a [`PublicKey`](../Reference/Types/Abi/Common.md#publickey) struct on [`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md).

## TEE State

State the enclave holds for the machine:

- Identity key pair $(\mathrm{TEE}_\mathrm{pub}, \mathrm{TEE}_\mathrm{priv})$.
- All [wallet keys](Keys.md) and key backups held for [PMW](../../PMW/README.md) or any other key-custody [FCE](../FCE/README.md).
- System state variables — initial and current [signing policies](Policy.md), configuration nonce, pausing nonce.
- Any [extension-defined state](../FCE/Concepts.md) added by the FCE the machine is registered to.

For what transfers when a machine's enclave is swapped, see [Replication](#replication).

## Attestation

A TEE machine attests to its [state](#tee-state) when challenged. The proof bundles the challenger's input with the machine's [identity public key](#identity), both the [initial and active signing policies](Policy.md) it knows, a state snapshot, and a timestamp; the TEE platform's attestation service signs over the bundle, anchoring the result to hardware-attested boot state.

On-chain verifiers match the proof's [`initialTeeId`](../Reference/Types/Abi/TeeMachine.md#teemachinewithattestationdata) against the machine record, binding the proof to the on-record enclave across any past [replication](#replication).

For the [`Attestation`](../Reference/Types/Abi/TeeMachine.md#attestation) struct itself, see the type doc; for the FDC2 wrapper that turns this into an on-chain proof, see [`TeeAvailabilityCheck`](../../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md).

## Owner Allowlist

Three allowlists gate the FCC owner roles:

- _machine owner_ — the address that owns a registered TEE machine (a [TEE operator](../../Terminology/Roles.md#tee-operator)). Per-extension list, maintained by the [extension owner](../../Terminology/Roles.md#extension-owner).
- [project owner](../../Terminology/Roles.md#project-owner) — creates wallet projects under an extension. Per-extension list, maintained by the extension owner.
- [extension owner](../../Terminology/Roles.md#extension-owner) — registers and owns an extension. Single global list, maintained by immediate [governance](../../Terminology/Roles.md#governance).

Checked on registration, ownership changes, and project creation; each list has an "allow-all" toggle for fully public participation.

Owner changes use the two-step [ownership-transfer flow](../Workflows/OwnerTransfer.md) on [`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md#management-calls).

For the management calls, see [`FlareTeeManager § Owner Allowlist`](../Reference/Contracts/FlareTeeManager.md#owner-allowlist).

## Registration

A TEE operator [registers](../Reference/Contracts/FlareTeeManager.md#registration) a machine by submitting its `teeMachineData` together with a signature by the identity key proving possession of the corresponding private key.
The contract recovers the signer and stores it as the machine's `teeId`, so a caller cannot register a `teeId` whose private key it does not control.
A freshly-registered machine starts in [`INITIALIZED`](#statuses) and needs a valid [`TeeAvailabilityCheck`](../../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md) proof to reach `PRODUCTION`.

## Statuses

A registered machine moves through seven statuses:

1. **`INITIALIZED`** — set by `register`. No rights yet; transition to `PRODUCTION` requires a valid availability proof.
2. **`PRODUCTION`** — fully operational; accepts instructions. Owner may pause; anyone may suspend after the [availability deadline](#availability-deadline) expires.
3. **`SUSPENDED`** — set on a non-`OK` [`TeeAvailabilityCheck`](../../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md) proof or after the availability deadline. Can return to `PRODUCTION` with a fresh proof, be paused, or be banned.
4. **`PAUSED`** — owner-initiated stop, or automatic on settings update or unsupported code. No instructions accepted. Return to `PRODUCTION` requires a fresh availability proof.
5. **`PAUSED_FOR_UPGRADE`** — owner-initiated, prepares the machine for [replication](../Workflows/MachineReplication.md). Entered from `PAUSED`.
6. **`REPLICATING`** — a successor machine is taking over this machine's identity and key set; reached from `PAUSED_FOR_UPGRADE`.
7. **`BANNED`** — extension-owner only; reversal lands the machine in `PAUSED`.

Each transition emits `TeeMachineStatusChanged`.

An extension-wide [emergency pause](../Reference/Contracts/FlareTeeManager.md#emergency-pause) is a separate overlay: while set, it blocks instruction dispatch to every machine in the extension without changing any machine's status.

### Availability Deadline

Each [`TeeAvailabilityCheck`](../../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md) proof refreshes two freshness bounds the contract records together:

- a time deadline (`endTs`), extended by a fixed window past the proof's timestamp.
- the [signing policy](Policy.md) the proof attested to (`lastSigningPolicyId`), considered fresh for a fixed number of reward epochs.

Anyone may submit a fresh proof at any time. A machine becomes permissionlessly suspendable as soon as **either** bound expires — `endTs < now` or `lastSigningPolicyId` falls outside the signing-policy window. In that state the machine stays in `PRODUCTION` but:

- its actions stop entitling its owner to [rewards](../../FSP/Rewarding.md).
- anyone may suspend it; a fresh proof brings it back.

Operators must refresh availability before either bound expires to avoid downtime.

For per-call rules, see [`FlareTeeManager § Management Calls`](../Reference/Contracts/FlareTeeManager.md#management-calls).

## Replication

A TEE machine's underlying enclave can be replaced — for hardware refresh, code upgrade, or operator-controlled migration — without changing the machine's on-chain identity. The persistent $\mathrm{TEE}_\mathrm{ID}$ stays the same; what changes is the enclave behind it.

The successor enclave receives the [identity key pair](#identity), all [wallet keys](Keys.md) and backups, and the signing-policy state, so it can continue signing as the same machine without re-doing wallet setup or signing-policy installation. Machine-local nonces (configuration, pausing) do not transfer; transfer of [extension-defined state](../FCE/Concepts.md) is FCE-specific.

For the per-machine state machine, see [`MachineReplication` workflow](../Workflows/MachineReplication.md); for the contract surface, see [`FlareTeeManager § Replication`](../Reference/Contracts/FlareTeeManager.md#replication).
