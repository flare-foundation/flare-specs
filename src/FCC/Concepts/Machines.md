# Machines

A _TEE machine_ is one TEE-running node registered with FCC.
Each machine is identified by a unique $\mathrm{TEE}_\mathrm{ID}$ — the address derived from its identity public key, generated inside the enclave at boot.
Around that identity, the machine carries state that a fresh replica running the same code would not share by default: keys, signing policies, status, and any extension-defined state.

This page covers identity, the state model, the attestation procedure, registration, the status lifecycle, and the management calls available to TEE operators.

## Identity Key and Initial Identity

The boot-time key pair $(\mathrm{TEE}_\mathrm{pk}, \mathrm{TEE}_\mathrm{sk})$ never leaves the enclave; $\mathrm{TEE}_\mathrm{ID}$ is the public key's Ethereum-style address.
On Flare, $\mathrm{TEE}_\mathrm{pk}$ is represented as a [`PublicKey`](../Reference/Types/Abi/Common.md#publickey) struct on the [`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md) contract.

Each machine also has an _initial identity_ $\mathrm{TEE}_\mathrm{ID}^*$.
For a fresh registration $\mathrm{TEE}_\mathrm{ID}^* = \mathrm{TEE}_\mathrm{ID}$; for a [replica](#tee-state) taking over from a TEE with identity $\mathrm{TEE}_\mathrm{ID}^{\prime}$, $\mathrm{TEE}_\mathrm{ID}^* = \mathrm{TEE}_\mathrm{ID}^{\prime}$.
Owners are recorded separately and updated via the [ownership transfer flow](#management-calls).

## Signing Policy

A TEE machine cannot accept signed instructions unless it knows the current [signing policy](../../FSP/SigningPolicy.md).
The first signing policy is installed at registration time as part of the initial [attestation](#attestation); subsequent policies are pushed by the [TEE proxy](../Reference/Components/Proxy.md) via [`UPDATE_POLICY`](../Reference/Operations/F_POLICY.md#update_policy) at every reward-epoch boundary.

## TEE State

The TEE's state is the part of its content that a fresh replica running the same code would not share by default:

- The identity key pair $(\mathrm{TEE}_\mathrm{pk}, \mathrm{TEE}_\mathrm{sk})$.
- All [wallet keys](Keys.md) and key backups held for [PMW](../PMW/README.md) (or any other key-custody [FCE](../FCE/README.md)).
- System state variables: initial and current signing policies, the machine's status, the configuration nonce, the pausing nonce.
- Any [extension-defined state](../FCE/Concepts.md) added by the FCE the machine is registered to.

On a [replication](../Reference/Operations/F_REG.md) upgrade, the essential state — the identity key pair, and all wallet keys and backups — is transferred to the new machine that takes over the identity.
Machine-local nonces are not carried over.

### Encoding

State is serialized into the [`TeeState`](../Reference/Types/Abi/TeeMachine.md#teestate) struct used inside attestations.
It has two parts:

- **System state**: defined by Flare; covers FCC-framework state variables. Version-specific.
- **Extension state**: defined by the FCE the machine is registered to; surfaced through the FCE's `/state` endpoint. Version-specific.

Each version of `systemState` and `state` is keyed by a `bytes32` version hash (`systemStateVersion`, `stateVersion`).
Version `0` (32-byte zero) encodes both bodies as empty `bytes`.

## Attestation

A TEE machine attests to elements of its [state](#tee-state) — identity key, signing policies, FCE state, timestamp — when challenged.
The attestation chain ends in a signature produced by the TEE platform operator (Google for Intel TDX and AMD SEV), so the response format is platform-specific.

### Challenge and Response

A _challenger_ — any entity that wants to verify a machine's state — provides a $32$-byte challenge.
The machine builds an [`Attestation`](../Reference/Types/Abi/TeeMachine.md#attestation) struct from the challenge and its own state:

- `publicKey`: TEE identity public key.
- `initialSigningPolicyId`, `lastSigningPolicyId`: first and most recent signing policies known to the machine.
- `state`: ABI-encoded [`TeeState`](../Reference/Types/Abi/TeeMachine.md#teestate) at the moment of attestation.
- `teeTimestamp`: local machine timestamp at attestation time.
- `challenge`: the challenger's $32$-byte input.

The machine ABI-encodes the struct, hashes it ($\mathrm{hash}(\mathrm{Attestation})$), and passes the digest to the platform operator's attestation service.
The platform's signed response binds the digest to the hardware-attested boot state and is returned to the challenger.

For the FDC2 attestation type that wraps this procedure into an on-chain proof, see [`TeeAvailabilityCheck`](../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md).

## Owner Allowlist

Per-extension allowlists gate two roles:

- _machine owner_: the Flare address that registers and owns a TEE machine on the extension.
- _wallet [project owner](../../Terminology/Roles.md#project-owner)_: the Flare address that creates wallet projects under the extension.

The allowlist is checked by:

- `register`: caller must be an allowed machine owner for the target extension.
- `proposeNewOwner` / `confirmOwnership` on the machine: the proposed (and confirming) owner must still be allowlisted (or `address(0)` to cancel).
- `createProject` on a wallet project: caller must be an allowed wallet project owner.

The extension owner manages each list via `addAllowedTeeMachineOwners` / `removeAllowedTeeMachineOwners` and `addAllowedTeeWalletProjectOwners` / `removeAllowedTeeWalletProjectOwners`, or opens it up entirely with `allowAllTeeMachineOwners` / `allowAllTeeWalletProjectOwners`.

## Registration

The TEE operator submits:

```solidity
register(teeMachineData, signature, teeProxyId, url, claimBackAddress)
```

on [`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md).
The call is payable; `msg.value` covers the TEE attestation request enqueued automatically as part of registration, and `claimBackAddress` may reclaim the fee if attestation fails.

`teeMachineData` carries:

| Field | Description |
|---|---|
| `extensionId` | Extension the machine joins. |
| `initialOwner` | Caller (`msg.sender == initialOwner` is enforced). |
| `codeHash` | Hash of the code deployed inside the machine. Must be a [supported `(codeHash, platform)` combination](../FCE/Concepts.md#management-calls). |
| `platform` | Attestation platform (e.g. `GOOGLE_INTEL_TDX`, `GOOGLE_AMD_SEV`). |
| `publicKey` | TEE identity public key. |

`signature` is a proof-of-possession over $\mathrm{keccak256}(\mathrm{abi.encode}(\mathrm{teeMachineData}))$ produced inside the enclave following the [Ethereum Signed Message](../../Utilities/Signing.md) convention.
The contract recovers the signer and requires it to equal `address(publicKey)`, which it then stores as the machine's `teeId`.

The machine enters [`INITIALIZED`](#statuses).
To reach `PRODUCTION` it must then present a valid [`TeeAvailabilityCheck`](../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md) proof via `toProduction(proof)`.

### TEE ID Derivation

`teeId` is the Ethereum-style address of the TEE's identity public key — the last $20$ bytes of $\mathrm{keccak256}(\mathrm{publicKey})$.
It is _not_ the address of the caller of `register`: the caller (the [TEE operator](../../Terminology/Roles.md#tee-operator)) is recorded separately as the machine's owner.

This binding is what makes the signature in `register` necessary: without it, a caller could register a `teeId` whose private key they do not control.

### Machine Record

`FlareTeeManager` stores per-machine state in a `TeeMachineState` record:

- `extensionId`, `owner`, `teeProxyId`, `url`.
- `teePublicKey`, `initialTeeId` (used during [replication](#tee-state)), `initialSigningPolicyId`.
- `codeHash`, `platform`.
- `status`, `lastStatusChangeTs`.

Inspect machines via `getTeeMachine(teeId)` and the active-set queries `getAllActiveTeeMachines`, `getActiveTeeMachines(extensionId)`.

## Statuses

A registered machine moves through five statuses:

1. **`INITIALIZED`** — set by `register`. The machine has no rights yet; transition to `PRODUCTION` via `toProduction(proof)`.
2. **`PRODUCTION`** — fully operational; receives any instruction. Owner may pause; anyone may suspend after the [availability deadline](#availability-deadline) expires.
3. **`SUSPENDED`** — set by `pauseWithProof(proof)` against a non-`OK` [`TeeAvailabilityCheck`](../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md) proof, or by `pause(teeId)` after the availability deadline. Can return to `PRODUCTION` via `toProduction(proof)` with a fresh availability proof, be paused by the owner, or be banned.
4. **`PAUSED`** — owner-initiated stop, or automatic on settings update / unsupported code. No instructions are accepted. Return to `PRODUCTION` with a fresh availability proof.
5. **`BANNED`** — set by `ban(teeId)`; only reversible via `unban(teeId)` (which lands the machine in `PAUSED`).

`lastStatusChangeTs` is bumped to `block.timestamp` on every transition.
Each transition emits `TeeMachineStatusChanged`.

### Availability Deadline

Each [`TeeAvailabilityCheck`](../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md) proof extends the machine's deadline `availabilityCheckValidityEndTs`.
Before the deadline anyone may submit a fresh proof via `confirmAvailability(proof)`; after it the machine stays in `PRODUCTION` but:

- its actions stop entitling its owner to [rewards](../../FSP/Rewarding.md).
- anyone may call `pause(teeId)` to send it to `SUSPENDED`; a fresh availability proof through `toProduction(proof)` brings it back.

Operators must refresh availability before expiry to avoid downtime.

## Management Calls

All calls live on the [`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md) diamond:

- `register(teeMachineData, signature, teeProxyId, url, claimBackAddress)`: see [Registration](#registration).
- `toProduction(proof)`: moves a machine to `PRODUCTION` given a valid availability proof. Owner-callable from `INITIALIZED` or `PAUSED`; anyone-callable from `SUSPENDED`.
- `pause(teeId)`: see [Statuses](#statuses) for the per-caller transition rules.
- `pauseWithProof(proof)`: suspends a `PRODUCTION` machine on a non-`OK` availability proof whose `timestamp` is no older than $10$ minutes. Callable by anyone.
- `proposeNewOwner(teeId, newOwner)` / `confirmOwnership(teeId)`: two-step ownership transfer (proposed owner must be allowlisted).
- `updateTeeMachineSettings(teeId, teeProxyId, url)`: updates the proxy ID or URL. Requires `PRODUCTION` or `SUSPENDED` status; the machine automatically transitions to `PAUSED` and needs a fresh availability proof to return.
- `ban(teeId)` / `unban(teeId)`: extension-owner only; `unban` lands the machine in `PAUSED`.
- `confirmAvailability(proof)`: extends the availability deadline (no status change). Callable by anyone.

Once registered, a `teeId` belongs to its owner permanently; ownership changes only through `proposeNewOwner` / `confirmOwnership`, which prevents re-registration under a different owner.
