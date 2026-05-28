# FlareTeeManager

The `FlareTeeManager` contract is the Flare-side hub of FCC: a [diamond](https://eips.ethereum.org/EIPS/eip-2535) contract whose facets manage [extensions](../../FCE/README.md), [TEE machines](../../Concepts/Machines.md), [instructions](../../Concepts/Instructions.md), wallets and keys, attestation verification, and governance.

For the concepts these calls implement, see [Machines](../../Concepts/Machines.md), [Wallets](../../Concepts/Wallets.md), and [Keys](../../Concepts/Keys.md).

## Facets

Each concern is implemented as an independent facet:

- `InstructionsFacet`: instruction submission and system-instructions-sender registration.
- `ExtensionManagerFacet`: extension registration (including governance-reserved IDs), per-extension contract updates, system-supported platforms and key types.
- `ExtensionGovernanceFacet`: per-extension governance signer-set management.
- `ExtensionPausingFacet`: governance-signed pausing-address records.
- `MachineManagerFacet`: TEE machine registration, status transitions, ownership.
- `MachineEmergencyPauseFacet`: per-extension [emergency stop](#emergency-pause) and its pauser/unpauser lists.
- `MachinePathManagerFacet`: governance-signed authorized `(sourceTeeIds, destinationTeeIds)` paths used by direct backup/restore.
- `VerificationFacet`: on-chain verification of TEE attestations and FDC2 proofs.
- `OperationFeesFacet`: per-operation fee configuration.
- `UpgradeManagerFacet`: TEE upgrade flow.
- `WalletManagerFacet`, `WalletKeyManagerFacet`, `WalletBackupManagerFacet`, `WalletProjectPauseFacet`, `WalletResumeFacet`, `WalletProjectManagerFacet`: protocol-managed-wallet lifecycle (`WalletBackupManagerFacet` includes both the legacy admin-cosigner `backupRestore` and the path-list-gated `directBackup`/`directRestore`; `WalletProjectPauseFacet` adds the per-project [wallet pauser/unpauser](../../../Terminology/Roles.md#wallet-pauser-and-unpauser) lists and the batch `pauseWallets`/`unpauseWallets` actions).
- `VrfFacet`, `SystemStateVerifierFacet`, `ReplicationFacet`: VRF, state verification, and replication.
- `DiamondGovernanceFacet`, `OwnerAllowlistFacet`, `ExternalAddressesFacet`: governance, the extension-owner / machine-owner / project-owner allowlists, and external-address plumbing.

Event signatures are listed in [Events](FlareTeeManagerEvents.md).

## Sending Instructions

`InstructionsFacet` exposes two entry points that emit a [`TeeInstructionsSent`](FlareTeeManagerEvents.md#teeinstructionssent) event after caller validation, payload validation, and fee collection:

- `sendInstructions(teeIds, instructionParams)`.
- `sendSystemInstructions(instructionId, teeMachines | teeIds, instructionParams)`: lets a system instructions sender supply an explicit `instructionId`.

### Caller Validation

For `sendInstructions`, `msg.sender` must satisfy one of:

- registered as a _system instructions sender_ (`Instructions.isSystemInstructionsSender(msg.sender)`): any op-type, any extension.
- equal to the destination extension's registered instructions sender (`ExtensionManager.getExtensionInstructionsSender(extensionId)`): non-[system op-types](../../FCE/Concepts.md#system-vs-custom-extensions) only (`F_` prefix forbidden).

The destination extension is determined by the first destination TEE machine (`MachineManager.getExtensionId(teeMachines[0].teeId)`).
All other destination TEE machines must belong to the same extension.

The [system extension](../../FCE/System.md) (`extensionId == 0`) cannot have its own registered instructions sender: extension id $0$ is unassignable (public `register` allocates ids from `nextPublicExtensionId`, which starts at $65536$; governance can reserve ids $1$–$65535$ via `registerReserved` but never $0$), and `setExtensionContracts` rejects `_extensionId == 0`.
Its TEE machines are reachable only via a system instructions sender.

`sendSystemInstructions` requires `msg.sender` to be a system instructions sender.
The set is managed by [governance](../../../Terminology/Roles.md#governance) via `registerSystemInstructionsSenders` and `unregisterSystemInstructionsSenders`.

### Payload Validation

The library further enforces:

- at least one destination TEE machine.
- non-empty `opType`, `opCommand`, and `message`.
- $\mathrm{cosignersThreshold} \leq \mathrm{cosigners.length}$.
- all destination TEE machines belong to the same extension.
- the destination extension is not [emergency-paused](#emergency-pause).
- for non-system op-types, every destination TEE machine is in `PRODUCTION` status.
- `msg.value` is at least the operation's calculated fee; the fee is forwarded to the reward manager for the current reward epoch.

### Event Field Origins

Fields of the emitted [`TeeInstructionsSent`](FlareTeeManagerEvents.md#teeinstructionssent) event:

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

Three allowlists on `OwnerAllowlistFacet` (see [Concepts/Machines § Owner Allowlist](../../Concepts/Machines.md#owner-allowlist) for what the roles mean):

- _machine owner_ (per-extension) — gates `register`, `proposeNewOwner` / `confirmOwnership` on machines.
- _wallet [project owner](../../../Terminology/Roles.md#project-owner)_ (per-extension) — gates `createProject`.
- _[extension owner](../../../Terminology/Roles.md#extension-owner)_ (global) — gates `register`, `proposeNewOwner` / `confirmOwnership` on extensions.

Extension owners manage the two per-extension lists for their own extension:

- `addAllowedTeeMachineOwners`, `removeAllowedTeeMachineOwners`, `allowAllTeeMachineOwners`.
- `addAllowedTeeWalletProjectOwners`, `removeAllowedTeeWalletProjectOwners`, `allowAllTeeWalletProjectOwners`.

Immediate [governance](../../../Terminology/Roles.md#governance) manages the global extension-owner list:

- `addAllowedExtensionOwners`, `removeAllowedExtensionOwners`, `allowAllExtensionOwners`, `disallowAllExtensionOwners`.

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

Successful registration places the machine in [`INITIALIZED`](../../Concepts/Machines.md#statuses); reaching `PRODUCTION` requires a valid [`TeeAvailabilityCheck`](../../../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md) proof submitted via `toProduction(proof)`.

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

Status transitions emit `TeeMachineStatusChanged` ([events doc](FlareTeeManagerEvents.md)).

## Emergency Pause

`MachineEmergencyPauseFacet` is a per-extension emergency stop, separate from per-machine [statuses](../../Concepts/Machines.md#statuses) and per-wallet pausing. While an extension is emergency-paused, [`sendInstructions` / `sendSystemInstructions`](#sending-instructions) reject every dispatch — regular **and** system op-types — to its machines with `EmergencyPauseActive`. Machine statuses, the active sets, and the read getters are untouched, so off-chain consumers must also check `isExtensionEmergencyPaused(extensionId)`. Clearing the flag restores dispatch immediately.

Two per-extension address lists, managed by the [extension owner](../../../Terminology/Roles.md#extension-owner), delegate the stop without ceding ownership — an _emergency pauser_ may pause, an _emergency unpauser_ may unpause, and the extension owner may do both:

- `addExtensionEmergencyPausers` / `removeExtensionEmergencyPausers`, `addExtensionEmergencyUnpausers` / `removeExtensionEmergencyUnpausers` — extension-owner only.
- `emergencyPauseExtension(extensionId)` — extension owner or a pauser; reverts `ExtensionAlreadyEmergencyPaused` if already set.
- `emergencyUnpauseExtension(extensionId)` — extension owner or an unpauser; reverts `ExtensionNotEmergencyPaused` if not set. Records the unpause timestamp, opening the grace window below.
- `setEmergencyUnpauseGracePeriodSeconds(seconds)` — immediate [governance](../../../Terminology/Roles.md#governance) only, timelocked; bounded $30\,\mathrm{min}$–$24\,\mathrm{h}$ (`GracePeriodTooShort` / `GracePeriodTooLong`).
- Views: `isExtensionEmergencyPaused`, `getLastUnpauseTs`, `getEmergencyUnpauseGracePeriodSeconds`, `getExtensionEmergency{Pausers,Unpausers}`, `isExtensionEmergency{Pauser,Unpauser}`.

### Unpause Grace Window

After unpause, a global grace window (default $\sim 2\,\mathrm{h}$) blocks only the third-party expired-availability branch of [`pause(teeId)`](#management-calls) — revert `EmergencyProtectionActive` — so owners can refresh attestations before a stranger suspends a still-`PRODUCTION` machine. The window covers the longer of the machine's own extension and the [system extension](../../FCE/System.md) (id 0), since an availability refresh needs both an own-extension attestation and an FDC2 attestation routed to system-extension machines. Owner-initiated `pause`, disabled-version pause, and `pauseWithProof` are unaffected.

Events: [Emergency Pause](FlareTeeManagerEvents.md#emergency-pause).

## Replication

`ReplicationFacet` replaces the enclave behind an existing machine without changing the machine's on-chain identity, transferring keys from old to new enclave under enclave-to-enclave attestation. Conceptual overview: [Concepts/Machines § Replication](../../Concepts/Machines.md#replication); per-machine state machine: [`MachineReplication`](../../Workflows/MachineReplication.md).

Calls (the caller must own the affected machine — and both machines for `replicateFrom` / `confirmReplicate`):

- `toPauseForUpgrade(teeId, claimBackAddress)` — payable; moves a `PAUSED` machine to `PAUSED_FOR_UPGRADE`. Requires $\mathrm{now} - \mathrm{lastStatusChangeTs} \geq \mathrm{pauseBeforeUpgradeMinDurationSeconds}$ (the governance-tunable dwell). Dispatches a `TO_PAUSE_FOR_UPGRADE` instruction.
- `replicateFrom(oldTeeId, proof, teeUpgradeId, claimBackAddress)` — payable; ties a freshly-registered successor `B` to an existing `PAUSED_FOR_UPGRADE` machine `A`. `A` and `B` must share the same owner and extension; the `(A, B)` pair must match a registered upgrade path (`teeUpgradeId`); `B`'s availability proof must be `OK` with `state.systemStateVersion ≠ 0`. Records `replicatingTeeIds[A] = B`, moves `B` to `REPLICATING`, dispatches `REPLICATE_FROM` to both.
- `confirmReplicate(newTeeId, proof)` — accepts when `A` is `PAUSED_FOR_UPGRADE`, `B` is `REPLICATING`, `replicatingTeeIds[A] = B`, and `proof` is an `OK` availability proof for `A` from the successor enclave. Copies `B`'s hardware-fingerprint fields (`initialTeeId`, `teeProxyId`, `codeHash`, `platform`, `url`, `initialSigningPolicyId`) into `A`'s slot, deletes `B`'s record, clears `replicatingTeeIds[A]`, moves `A` to `PRODUCTION`, and extends availability from the proof.

View: `getReplicatingTeeId(oldTeeId)` returns the in-progress successor (or `address(0)`).

Governance: `setPauseBeforeUpgradeMinDurationSeconds(seconds)` (timelocked) sets the dwell window.

Events: [`TeeMachinePausedForUpgrade`](FlareTeeManagerEvents.md#teemachinepausedforupgrade), [`TeeMachineReplicationTriggered`](FlareTeeManagerEvents.md#teemachinereplicationtriggered), [`TeeMachineReplicationConfirmed`](FlareTeeManagerEvents.md#teemachinereplicationconfirmed), and [`TeeMachineStatusChanged`](FlareTeeManagerEvents.md#teemachinestatuschanged) for each transition.

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

Events: [`ProjectCreated`](FlareTeeManagerEvents.md#projectcreated), [`BackupManagerSet`](FlareTeeManagerEvents.md#backupmanagerset), [`NewOwnerProposed`](FlareTeeManagerEvents.md#newownerproposed), [`OwnershipConfirmed`](FlareTeeManagerEvents.md#ownershipconfirmed).

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

Status transitions and the call that triggers each:

1. `CREATED → INITIALIZED` — `closeWalletInitialization` (project owner), after every admin and every cosigner has confirmed via `confirmAdmin` / `confirmCosigner`.
2. `INITIALIZED → PRODUCTION` — `enableWallet` (project owner), once `multisigThreshold` is set and at least that many keys are [confirmed](../../Concepts/Keys.md#tee-key-existence-proof).
3. `PRODUCTION ↔ PAUSED` — `pauseWallets` / `unpauseWallets`, batched across any of the project's wallets and callable by the project owner **or** an address on the corresponding [wallet pauser/unpauser](../../../Terminology/Roles.md#wallet-pauser-and-unpauser) list. Each batch emits one event.

Events: [`WalletCreated`](FlareTeeManagerEvents.md#walletcreated), [`WalletAdminsSet`](FlareTeeManagerEvents.md#walletadminsset), [`WalletAdminConfirmed`](FlareTeeManagerEvents.md#walletadminconfirmed), [`WalletCosignersSet`](FlareTeeManagerEvents.md#walletcosignersset), [`WalletCosignerConfirmed`](FlareTeeManagerEvents.md#walletcosignerconfirmed), [`WalletInitialized`](FlareTeeManagerEvents.md#walletinitialized), [`WalletEnabled`](FlareTeeManagerEvents.md#walletenabled), [`WalletsPaused`](FlareTeeManagerEvents.md#walletspaused), [`WalletsUnpaused`](FlareTeeManagerEvents.md#walletsunpaused).

### Pausing Keys at the TEE

`pauseWallets` only changes on-chain status; to pause keys at their TEE machines, the project owner additionally calls (both payable; fee refundable via `claimBackAddress` if the instruction does not execute):

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
