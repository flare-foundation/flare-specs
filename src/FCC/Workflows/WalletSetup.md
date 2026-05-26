# WalletSetup

State machine for creating a project, configuring a wallet, distributing its keys across TEE machines, and enabling it for production use.

The flow is a composition of two nested machines: the wallet itself (`Created → Initialized → Production`, with a `Paused` side state) and a per-key sub-machine that runs the [KeyAdd](KeyAdd.md) state machine for every `keyId` the wallet wants to back.

For canonical concepts, see [Concepts/Wallets](../Concepts/Wallets.md) (data model) and [Concepts/Keys](../Concepts/Keys.md) (key custody). The contract surface lives in [`FlareTeeManager § Project Management`](../Reference/Contracts/FlareTeeManager.md#project-management) and [`§ Wallet Management`](../Reference/Contracts/FlareTeeManager.md#wallet-management).

## Preconditions

- The extension is configured ([Configuration](../FCE/Workflows/Configuration.md)) with the desired `(keyType, signingAlgo)` registered.
- At least one TEE machine of the extension is in `PRODUCTION` ([MachineRegistration](MachineRegistration.md)).
- The caller is allowlisted as a [project owner](../../Terminology/Roles.md#project-owner) on the extension.
- ECDSA key pairs exist for each intended admin; cosigner Flare addresses exist for the optional cosigners.

## States

- `NoProject` — no `projectId` exists for this caller's next project.
- `ProjectCreated` — `projectId` exists; `(extensionId, keyType, signingAlgo)` are pinned; no wallets yet.
- `WalletCreated` — `wallet.status = CREATED`; admins/cosigners can be set and changed.
- `WalletInitialized` — `wallet.status = INITIALIZED`; admins and cosigners are frozen; keys can be added.
- `WalletProduction` — `wallet.status = PRODUCTION`; multisig threshold met; the wallet accepts payment instructions.
- `WalletPaused` — `wallet.status = PAUSED`; on-chain pause that does not reach the TEE machines (those need [`setPausingAddresses`](../Reference/Contracts/FlareTeeManager.md#wallet-management) separately).

Per-key sub-state for each requested `keyId`: see [KeyAdd § States](KeyAdd.md#states) — `NotExists → Generated → Confirmed`.

## Initial State

`NoProject`.

## Transitions

### createProject: NoProject → ProjectCreated

- **Action**: [`FlareTeeManager.createProject(extensionId, keyType, signingAlgo)`](../Reference/Contracts/FlareTeeManager.md#project-management).
- **Caller**: an address on the extension's [project-owner allowlist](../Concepts/Machines.md#owner-allowlist).
- **Guards**: `keyType` and `signingAlgo` are supported on the extension.
- **Effects**:
  - Assigns `projectId = keccak256(abi.encode("PROJECT", msg.sender, counter))`.
  - Sets `owner = msg.sender`; pins `(extensionId, keyType, signingAlgo)` immutably.
  - Emits [`ProjectCreated`](../Reference/Contracts/FlareTeeManagerEvents.md#projectcreated).
  - _Optional_: the project owner may now set a backup manager with `setBackupManager(projectId, address)` ([`BackupManagerSet`](../Reference/Contracts/FlareTeeManagerEvents.md#backupmanagerset)).

### createWallet: ProjectCreated → WalletCreated

- **Action**: `FlareTeeManager.createWallet(projectId)`.
- **Caller**: project owner.
- **Effects**:
  - Assigns `walletId = keccak256(abi.encode("WALLET", owner, counter))`.
  - `wallet.status = CREATED`; wallet linked to `projectId`.
  - Emits [`WalletCreated`](../Reference/Contracts/FlareTeeManagerEvents.md#walletcreated).

### setAdmins: WalletCreated → WalletCreated (repeatable)

- **Action**: `FlareTeeManager.setAdmins(walletId, adminsPublicKeys, adminsThreshold)`.
- **Caller**: project owner.
- **Guards**:
  - `wallet.status = CREATED`.
  - `|adminsPublicKeys| ≥ adminsThreshold > 0`.
  - No duplicates; every key valid.
- **Effects**: replaces the prior admin set; emits [`WalletAdminsSet`](../Reference/Contracts/FlareTeeManagerEvents.md#walletadminsset).

### confirmAdmin: WalletCreated → WalletCreated (per admin)

- **Action**: `FlareTeeManager.confirmAdmin(walletId)`.
- **Caller**: an admin (the address derived from one of the configured `adminsPublicKeys`).
- **Guards**: `wallet.status = CREATED`; caller's address matches a still-unconfirmed admin public key.
- **Effects**: marks the admin as confirmed; emits [`WalletAdminConfirmed`](../Reference/Contracts/FlareTeeManagerEvents.md#walletadminconfirmed).

### setCosigners / confirmCosigner: WalletCreated → WalletCreated (optional)

- **Action**: `setCosigners(walletId, cosigners, cosignersThreshold)` (project owner) followed by `confirmCosigner(walletId)` from each cosigner address.
- **Guards**: `wallet.status = CREATED`; if cosigners is empty, threshold must be 0; otherwise `|cosigners| ≥ cosignersThreshold > 0`, no duplicates, no zero addresses.
- **Effects**: emits [`WalletCosignersSet`](../Reference/Contracts/FlareTeeManagerEvents.md#walletcosignersset) and (per cosigner) [`WalletCosignerConfirmed`](../Reference/Contracts/FlareTeeManagerEvents.md#walletcosignerconfirmed).

### closeWalletInitialization: WalletCreated → WalletInitialized

- **Action**: `FlareTeeManager.closeWalletInitialization(walletId)`.
- **Caller**: project owner.
- **Guards**:
  - At least one admin set; every admin and every cosigner has confirmed.
- **Effects**:
  - `wallet.status = INITIALIZED`; admins, cosigners, and their thresholds are now immutable.
  - Emits [`WalletInitialized`](../Reference/Contracts/FlareTeeManagerEvents.md#walletinitialized).

### setMultisigThreshold: WalletInitialized → WalletInitialized (repeatable)

- **Action**: `FlareTeeManager.setMultisigThreshold(walletId, multisigThreshold)`.
- **Caller**: project owner.
- **Guards**: `wallet.status = INITIALIZED`; `multisigThreshold > 0`.
- **Effects**: stores the new threshold; emits [`WalletMultisigThresholdSet`](../Reference/Contracts/FlareTeeManagerEvents.md#walletmultisigthresholdset). Can be changed any number of times before `enableWallet`.

### addKey, confirmKey: WalletInitialized → WalletInitialized (per `keyId`)

- Each `keyId` is governed by the [KeyAdd](KeyAdd.md) sub-state-machine; the wallet stays in `WalletInitialized` until `enableWallet`.

### enableWallet: WalletInitialized | WalletPaused → WalletProduction

- **Action**: `FlareTeeManager.enableWallet(walletId)`.
- **Caller**: project owner.
- **Guards**:
  - `wallet.status ∈ {INITIALIZED, PAUSED}`.
  - `multisigThreshold` has been set.
  - At least `multisigThreshold` keys are in `Confirmed` ([KeyAdd terminal state](KeyAdd.md#terminal-states)).
- **Effects**: `wallet.status = PRODUCTION`; emits [`WalletEnabled`](../Reference/Contracts/FlareTeeManagerEvents.md#walletenabled).

### pauseWallet: WalletProduction → WalletPaused

- **Action**: `FlareTeeManager.pauseWallet(walletId)`.
- **Caller**: project owner.
- **Effects**: `wallet.status = PAUSED`; emits [`WalletPaused`](../Reference/Contracts/FlareTeeManagerEvents.md#walletpaused). The wallet stops accepting payment instructions on chain. TEE-side key pausing requires the separate [`setPausingAddresses` / `resume`](../Reference/Contracts/FlareTeeManager.md#pausing-keys-at-the-tee) flow.

## Invariants

- `(extensionId, keyType, signingAlgo)` on a project is set once and never changes.
- After `closeWalletInitialization`, the wallet's admin set, cosigner set, and their thresholds cannot change for the wallet's lifetime.
- `wallet.status = PRODUCTION` implies at least `multisigThreshold` confirmed keys exist; if keys are deleted below the threshold the wallet must transition through `WalletPaused` before more changes.
- Two-step ownership transfer ([`proposeNewOwner`](../Reference/Contracts/FlareTeeManager.md#project-management) / `confirmOwnership`) preserves all wallet state; only the project's `owner` changes.

## Terminal States

`WalletProduction` is the goal of this workflow. From here the wallet is consumed by:

- [XrplMultisigConfiguration](../../PMW/Workflows/XrplMultisigConfiguration.md), [XrpPayment](../../PMW/Workflows/XrpPayment.md) for PMW use.
- [VrfProof](VrfProof.md) for VRF use.
- [KeyAdd](KeyAdd.md) / [KeyDelete](KeyDelete.md) / [KeyRestore](KeyRestore.md) for ongoing key-set management.

## Notes

- The project owner can transfer ownership via `proposeNewOwner` / `confirmOwnership` on the project at any time; the new owner inherits all wallets.
- `setDefaultWallet(projectId, walletId)` (project owner) marks one wallet as the default sink for project-scoped payments.
- TEE-side key pausing (`F_WALLET SET_PAUSING_ADDRESSES`, `F_WALLET RESUME`) is independent of on-chain `pauseWallet`; see [Wallets § Pausing Keys at the TEE](../Concepts/Wallets.md#pausing-keys-at-the-tee).
