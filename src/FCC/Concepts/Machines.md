# Machines

A _TEE machine_ is a container running the [node app](../Reference/Components/Machine.md) (and, for custom extensions, an [extension app](../Reference/Components/Machine.md)) inside a hardware-attested enclave on a cloud TEE platform.

## Identity

- _Identity key pair_ $(\mathrm{TEE}_\mathrm{pub}, \mathrm{TEE}_\mathrm{priv})$ — public and private keys generated inside the enclave at boot; $\mathrm{TEE}_\mathrm{priv}$ never leaves it.
- $\mathrm{TEE}_\mathrm{ID}$ — the [address](../../Terminology/Concepts.md#addresses-accounts-and-keys) of $\mathrm{TEE}_\mathrm{pub}$. Distinct from the registering [TEE operator](../../Terminology/Roles.md#tee-operator)'s address (recorded separately; see [Owner Allowlist](#owner-allowlist)).
- $\mathrm{TEE}_\mathrm{pub}$ is held as a [`PublicKey`](../Reference/Types/Abi/Common.md#publickey) struct on [`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md).
- _Initial identity_ $\mathrm{TEE}_\mathrm{ID}^*$ — the [`initialTeeId`](../Reference/Types/Abi/TeeMachine.md#teemachinewithattestationdata) field: the $\mathrm{TEE}_\mathrm{ID}$ under which the enclave currently running the machine was first registered. Equal to $\mathrm{TEE}_\mathrm{ID}$ for an unreplicated machine. [Replication](../Workflows/MachineReplication.md) transfers the identity key to a fresh enclave, so $\mathrm{TEE}_\mathrm{ID}$ stays the machine's permanent on-chain identity while $\mathrm{TEE}_\mathrm{ID}^*$ becomes that enclave's own original $\mathrm{TEE}_\mathrm{ID}$ — fingerprinting the enclave now behind the machine.

## TEE State

The TEE's state is the part of its content that a fresh replica would not share by default:

- Identity key pair $(\mathrm{TEE}_\mathrm{pub}, \mathrm{TEE}_\mathrm{priv})$.
- All [wallet keys](Keys.md) and key backups held for [PMW](../../PMW/README.md) or any other key-custody [FCE](../FCE/README.md).
- System state variables — initial and current [signing policies](Policy.md), machine status, configuration nonce, pausing nonce.
- Any [extension-defined state](../FCE/Concepts.md) added by the FCE the machine is registered to.

On replication, the identity key pair and all wallet keys and backups transfer to the successor; machine-local nonces do not.

## Attestation

A TEE machine attests to elements of its [state](#tee-state) when challenged.
A _challenger_ provides a $32$-byte challenge; the machine builds an [`Attestation`](../Reference/Types/Abi/TeeMachine.md#attestation) binding that challenge to its [identity public key](#identity), the first and most recent signing policies it knows, a snapshot of its [state](#tee-state), and its local timestamp.

The machine ABI-encodes the struct, hashes it ($\mathrm{hash}(\mathrm{Attestation})$), and passes the digest to the TEE platform's attestation service (Google for Intel TDX and AMD SEV).
The platform's signed response binds the digest to the hardware-attested boot state.

For the FDC2 attestation type that wraps this procedure into an on-chain proof, see [`TeeAvailabilityCheck`](../../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md).

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
