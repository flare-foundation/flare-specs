# FlareTeeManager

The `FlareTeeManager` contract is the Flare-side hub of FCC: a [diamond](https://eips.ethereum.org/EIPS/eip-2535) contract whose facets manage [extensions](../../FCE/README.md), [TEE machines](../../Concepts/Machines.md), [instructions](../../Concepts/Instructions.md), wallets and keys, attestation verification, and governance.

For the concepts these calls implement, see [Machines](../../Concepts/Machines.md), [Wallets](../../Concepts/Wallets.md), and [Keys](../../Concepts/Keys.md).

## Facets

Each concern is implemented as an independent facet:

- `InstructionsFacet`: instruction submission and system-instructions-sender registration.
- `ExtensionManagerFacet`: extension registration, per-extension contract updates, system-supported platforms and key types.
- `ExtensionGovernanceFacet`: per-extension governance signers and pausing addresses.
- `MachineManagerFacet`: TEE machine registration, status transitions, ownership.
- `VerificationFacet`: on-chain verification of TEE attestations and FDC2 proofs.
- `OperationFeesFacet`: per-operation fee configuration.
- `UpgradeManagerFacet`: TEE upgrade flow.
- `WalletManagerFacet`, `WalletKeyManagerFacet`, `WalletBackupManagerFacet`, `WalletResumeFacet`, `WalletProjectManagerFacet`: protocol-managed-wallet lifecycle.
- `VrfFacet`, `SystemStateVerifierFacet`, `ReplicationFacet`: VRF, state verification, and replication.
- `DiamondGovernanceFacet`, `OwnerAllowlistFacet`, `ExternalAddressesFacet`: governance and external-address plumbing.

Event signatures are listed under [`Types/Abi/Events/`](../Types/Abi/Events).

## Sending Instructions

`InstructionsFacet` exposes two entry points that emit a [`TeeInstructionsSent`](../Types/Abi/Events/TeeExtensionRegistry.md#teeinstructionssent) event after caller validation, payload validation, and fee collection:

- `sendInstructions(teeIds, instructionParams)`.
- `sendSystemInstructions(instructionId, teeMachines | teeIds, instructionParams)`: lets a system instructions sender supply an explicit `instructionId`.

### Caller Validation

For `sendInstructions`, `msg.sender` must satisfy one of:

- registered as a _system instructions sender_ (`Instructions.isSystemInstructionsSender(msg.sender)`): any op-type, any extension.
- equal to the destination extension's registered instructions sender (`ExtensionManager.getExtensionInstructionsSender(extensionId)`): non-[system op-types](../../FCE/Concepts.md#system-vs-custom-extensions) only (`F_` prefix forbidden).

The destination extension is determined by the first destination TEE machine (`MachineManager.getExtensionId(teeMachines[0].teeId)`).
All other destination TEE machines must belong to the same extension.

The [system extension](../../FCE/System.md) (`extensionId == 0`) cannot have its own registered instructions sender: `extensionsCounter` is initialized to $1$, so `register` never assigns id $0$, and `setExtensionContracts` rejects `_extensionId == 0`.
Its TEE machines are reachable only via a system instructions sender.

`sendSystemInstructions` requires `msg.sender` to be a system instructions sender.
The set is managed by [governance](../../../Terminology/Roles.md#governance) via `registerSystemInstructionsSenders` and `unregisterSystemInstructionsSenders`.

### Payload Validation

The library further enforces:

- at least one destination TEE machine.
- non-empty `opType`, `opCommand`, and `message`.
- $\mathrm{cosignersThreshold} \leq \mathrm{cosigners.length}$.
- all destination TEE machines belong to the same extension.
- for non-system op-types, every destination TEE machine is in `PRODUCTION` status.
- `msg.value` is at least the operation's calculated fee; the fee is forwarded to the reward manager for the current reward epoch.

### Event Field Origins

Fields of the emitted [`TeeInstructionsSent`](../Types/Abi/Events/TeeExtensionRegistry.md#teeinstructionssent) event:

| Field | Origin |
|---|---|
| `extensionId` | `MachineManager.getExtensionId(teeMachines[0].teeId)` — the extension owning the destination TEE machines. |
| `instructionId` | Auto-generated as $\mathrm{keccak256}(\mathrm{abi.encode}(\mathrm{extensionId},\ n,\ \mathrm{blockhash}(b - 1)))$ where $n$ is the per-extension counter and $b$ the emitting block number; or caller-supplied (only via `sendSystemInstructions`). See [Hashes](../../Concepts/Instructions.md#hashes). |
| `rewardEpochId` | `FlareSystemsManager.getCurrentRewardEpochId()` narrowed to `uint32`. |
| `teeMachines` | Caller argument (passed directly, or resolved from `teeIds` via `MachineManager.getTeeMachine`). |
| `opType` | Caller argument (`instructionParams.opType`). |
| `opCommand` | Caller argument (`instructionParams.opCommand`). |
| `message` | Caller argument (`instructionParams.message`). |
| `cosigners` | Caller argument (`instructionParams.cosigners`). |
| `cosignersThreshold` | Caller argument (`instructionParams.cosignersThreshold`). |
| `claimBackAddress` | Caller argument (`instructionParams.claimBackAddress`). |
| `fee` | `msg.value`, forwarded to the reward manager. |

Each [instructions sender](../../Concepts/Instructions.md#instructions-senders) contract defines how it derives the caller-argument fields from the call its own users make.

## Owner Allowlist

Per-extension allowlists gate two roles (see [Concepts/Machines § Owner Allowlist](../../Concepts/Machines.md#owner-allowlist) for what the roles mean):

- _machine owner_ — gates `register`, `proposeNewOwner` / `confirmOwnership` on machines.
- _wallet [project owner](../../../Terminology/Roles.md#project-owner)_ — gates `createProject`.

Extension-owner-only management of each list:

- `addAllowedTeeMachineOwners`, `removeAllowedTeeMachineOwners`, `allowAllTeeMachineOwners`.
- `addAllowedTeeWalletProjectOwners`, `removeAllowedTeeWalletProjectOwners`, `allowAllTeeWalletProjectOwners`.

## Machine Management

### Registration

```solidity
register(teeMachineData, signature, teeProxyId, url, claimBackAddress)
```

Payable. `msg.value` covers the auto-enqueued TEE attestation request; `claimBackAddress` may reclaim the fee if attestation fails.

`teeMachineData` carries:

| Field | Description |
|---|---|
| `extensionId` | Extension the machine joins. |
| `initialOwner` | Caller (`msg.sender == initialOwner` is enforced). |
| `codeHash` | Hash of the code deployed inside the machine. Must be a [supported `(codeHash, platform)` combination](../../FCE/Concepts.md#management-calls). |
| `platform` | Attestation platform (e.g. `GOOGLE_INTEL_TDX`, `GOOGLE_AMD_SEV`). |
| `publicKey` | TEE identity public key. |

`signature` is a proof-of-possession over $\mathrm{keccak256}(\mathrm{abi.encode}(\mathrm{teeMachineData}))$ produced inside the enclave following the [Ethereum Signed Message](../../../Utilities/Signing.md) convention.
The contract recovers the signer and requires it to equal `address(publicKey)`, which it stores as the machine's `teeId`.

Successful registration places the machine in [`INITIALIZED`](../../Concepts/Machines.md#statuses); reaching `PRODUCTION` requires a valid [`TeeAvailabilityCheck`](../../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md) proof submitted via `toProduction(proof)`.

### Machine Record

Per-machine state stored in a `TeeMachineState` record:

- `extensionId`, `owner`, `teeProxyId`, `url`.
- `teePublicKey`, `initialTeeId` (used during [replication](../../Concepts/Machines.md#tee-state)), `initialSigningPolicyId`.
- `codeHash`, `platform`.
- `status`, `lastStatusChangeTs`.

Inspection: `getTeeMachine(teeId)`, `getAllActiveTeeMachines()`, `getActiveTeeMachines(extensionId)`.

### Management Calls

All calls live on the diamond:

- `register(teeMachineData, signature, teeProxyId, url, claimBackAddress)`: see [Registration](#registration).
- `toProduction(proof)`: moves a machine to `PRODUCTION` given a valid availability proof. Owner-callable from `INITIALIZED` or `PAUSED`; anyone-callable from `SUSPENDED`.
- `pause(teeId)`: see [Concepts/Machines § Statuses](../../Concepts/Machines.md#statuses) for the per-caller transition rules.
- `pauseWithProof(proof)`: suspends a `PRODUCTION` machine on a non-`OK` availability proof whose `timestamp` is no older than $10$ minutes. Callable by anyone.
- `proposeNewOwner(teeId, newOwner)` / `confirmOwnership(teeId)`: two-step ownership transfer (proposed owner must be allowlisted).
- `updateTeeMachineSettings(teeId, teeProxyId, url)`: updates the proxy ID or URL. Requires `PRODUCTION` or `SUSPENDED`; transitions the machine to `PAUSED`.
- `ban(teeId)` / `unban(teeId)`: extension-owner only; `unban` lands the machine in `PAUSED`.
- `confirmAvailability(proof)`: extends the [availability deadline](../../Concepts/Machines.md#availability-deadline) (no status change). Callable by anyone.

Once registered, a `teeId` belongs to its owner permanently; ownership changes only through `proposeNewOwner` / `confirmOwnership`, which prevents re-registration under a different owner.

Status transitions emit `TeeMachineStatusChanged` ([events doc](../Types/Abi/Events/TeeMachineRegistry.md)).

## Project Management

A project is created by an allowlisted [project owner](../../../Terminology/Roles.md#project-owner) calling:

```solidity
createProject(extensionId, keyType, signingAlgo)
```

The `projectId` is `keccak256(abi.encode("PROJECT", msg.sender, counter))` and the caller becomes the project owner.

Project record:

| Field | Description |
|---|---|
| `owner` | Current project owner address; changes only through `proposeNewOwner` / `confirmOwnership` (two-step). |
| `extensionId` | The FCE the project lives under; immutable. |
| `keyType`, `signingAlgo` | The [key type and algorithm](../../Concepts/Keys.md#signing-algorithms) shared by every wallet in the project; immutable. |
| `backupManager` | Optional second address authorized to trigger [key restoration](../../Concepts/Keys.md#key-restoration); set with `setBackupManager`. |

Both owner roles are gated against the FCE's [owner allowlist](#owner-allowlist) at every state-changing call.

Events: [`ProjectCreated`](../Types/Abi/Events/TeeWalletProjectManager.md#projectcreated), [`BackupManagerSet`](../Types/Abi/Events/TeeWalletProjectManager.md#backupmanagerset), [`NewOwnerProposed`](../Types/Abi/Events/TeeWalletProjectManager.md#newownerproposed), [`OwnershipConfirmed`](../Types/Abi/Events/TeeWalletProjectManager.md#ownershipconfirmed).

## Wallet Management

A wallet is created when the project owner calls:

```solidity
createWallet(projectId)
```

The `walletId` is `keccak256(abi.encode("WALLET", owner, counter))` and the wallet enters the `CREATED` status.

Wallet record:

| Field | Description |
|---|---|
| `projectId` | The parent project. |
| `adminsPublicKeys`, `adminsThreshold` | The [key admin](../../../Terminology/Roles.md#key-admin) public keys and $k$-of-$n$ threshold; set with `setAdmins`; finalized when the wallet leaves `CREATED`. |
| `cosigners`, `cosignersThreshold` | Optional [cosigner](../../Concepts/Instructions.md#cosigners) set and its threshold; set with `setCosigners`; finalized at close. |
| `multisigThreshold` | Minimum number of confirmed keys required to sign with the wallet; set with `setMultisigThreshold`. |
| `status` | One of `CREATED`, `INITIALIZED`, `PRODUCTION`, `PAUSED`. |

### Wallet Lifecycle

Status transitions and the call that triggers each (project owner only):

1. `CREATED → INITIALIZED` — `closeWalletInitialization`, after every admin and every cosigner has confirmed via `confirmAdmin` / `confirmCosigner`.
2. `INITIALIZED → PRODUCTION` — `enableWallet`, once `multisigThreshold` is set and at least that many keys are [confirmed](../../Concepts/Keys.md#tee-key-existence-proof).
3. `PRODUCTION → PAUSED` — `pauseWallet`.
4. `PAUSED → PRODUCTION` — `enableWallet` (no multisig recheck).

Events: [`WalletCreated`](../Types/Abi/Events/TeeWalletManager.md#walletcreated), [`WalletAdminsSet`](../Types/Abi/Events/TeeWalletManager.md#walletadminsset), [`WalletAdminConfirmed`](../Types/Abi/Events/TeeWalletManager.md#walletadminconfirmed), [`WalletCosignersSet`](../Types/Abi/Events/TeeWalletManager.md#walletcosignersset), [`WalletCosignerConfirmed`](../Types/Abi/Events/TeeWalletManager.md#walletcosignerconfirmed), [`WalletInitialized`](../Types/Abi/Events/TeeWalletManager.md#walletinitialized), [`WalletEnabled`](../Types/Abi/Events/TeeWalletManager.md#walletenabled), [`WalletPaused`](../Types/Abi/Events/TeeWalletManager.md#walletpaused).

### Pausing Keys at the TEE

`pauseWallet` only changes on-chain status; to pause keys at their TEE machines, the project owner additionally calls (both payable; fee refundable via `claimBackAddress` if the instruction does not execute):

- `setPausingAddresses(walletId, pausingAddresses, claimBackAddress)` — emits `F_WALLET SET_PAUSING_ADDRESSES` to every machine holding a copy of the wallet's keys.
- `resume(walletId, keysData, claimBackAddress)` — emits `F_WALLET RESUME` for the listed `(teeId, keyId, nonce)` triples.

## Key Custody

For each `(walletId, keyId)` the contract tracks:

| Field | Description |
|---|---|
| `publicKey` | Set when the first TEE machine [confirms](../../Concepts/Keys.md#tee-key-existence-proof) the generated key. |
| `teeIds` | The set of TEE machines that hold a copy. |
| `nonces` | Per-machine replay counters used by state-changing commands (`KEY_DELETE`, `RESUME`). |

Calls:

- `addKey(walletId, keyDataPerTee, claimBackAddress)` — payable; emits a `KEY_GENERATE` instruction to each listed machine and assigns a sequential `keyId`.
- `confirmKey(proof)` — on-chain entry for a TEE-signed [key existence proof](../../Concepts/Keys.md#tee-key-existence-proof). The first confirmation fixes `publicKey`; later machines join `teeIds`.
- `deleteKey(walletId, keyId, teeId, claimBackAddress)` — payable; emits `KEY_DELETE` for the specified `(walletId, keyId)` on the target machine and removes the machine from `teeIds`.
- `cleanUpTeeIds(walletId, keyId)` — drops machines from `teeIds` whose nonces show the key is no longer present.

Key restoration is initiated via:

```solidity
backupRestore(backupId, backupURL, teeId, randomNonce)
```

Callable by the project owner or its `backupManager`. Emits a `KEY_DATA_PROVIDER_RESTORE` instruction. See [Concepts/Keys § Key Restoration](../../Concepts/Keys.md#key-restoration) for the recovery procedure.

VRF proofs are produced from a `keccak256-secp256k1-vrf` key via the regular wallet-key path; verification is on-chain in [`VrfVerifier`](VrfVerifier.md).
