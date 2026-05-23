# TeeBackup

Lifecycle of one wallet-key backup from creation inside a TEE machine to consumption during a [KeyRestore](KeyRestore.md). A single backup may be created once, stored externally, and consumed any number of times — each consumption restores the key onto a different TEE machine.

For the cryptographic construction (Shamir secret sharing + ECIES under the data providers' public keys), see [Concepts/Keys § Backup Procedure](../Concepts/Keys.md#backup-procedure); for the operations, [`F_GET TEE_BACKUP`](../Reference/Operations/F_GET.md#tee_backup) and [`F_WALLET KEY_DATA_PROVIDER_RESTORE`](../Reference/Operations/F_WALLET.md#key_data_provider_restore).

## Preconditions

- A wallet exists in `INITIALIZED` or `PRODUCTION` (per [WalletSetup](WalletSetup.md)).
- The project owner has set a `backupManager` for the project via `setBackupManager(projectId, backupManager)`, or accepts the project owner itself in that role.
- The wallet's `(walletId, keyId)` is being added on some TEE machine $T$ via [KeyAdd](KeyAdd.md).

## States

- `NoBackup` — `(walletId, keyId)` is being generated; no encrypted package yet.
- `Generated` — TEE machine $T$ has produced an encrypted backup package as part of the [`KEY_GENERATE`](../Reference/Operations/F_WALLET.md#key_generate) action response.
- `Stored` — `backupManager` has fetched the package from $T$'s proxy and uploaded it to external storage at `backupUrl`.
- `Consumed` — `backupRestore` has been called for some target machine, triggering [KeyRestore](KeyRestore.md). The backup is _not_ destroyed; the state simply tracks that a restore has been initiated. The backup may be consumed again.

## Initial State

`NoBackup`, on entering the [KeyAdd](KeyAdd.md) workflow.

## Transitions

### generate: NoBackup → Generated

- **Action**: TEE machine $T$ runs the [`KEY_GENERATE`](../Reference/Operations/F_WALLET.md#key_generate) handler as part of [KeyAdd](KeyAdd.md); the action response carries the encrypted backup package plus the `BackupId` (`teeId`, `walletId`, `keyId`, `keyType`, `signingAlgo`, `publicKey`, `rewardEpochId`, `randomNonce`).
- **Caller**: TEE machine.
- **Effects**: the backup is present in the action response served by $T$'s proxy; `BackupId` becomes the immutable handle for this backup.

### store: Generated → Stored

- **Action**: `backupManager` retrieves the action response from $T$'s proxy and uploads the encrypted package to external storage controlled by the backup manager.
- **Caller**: `backupManager` (off-chain).
- **Effects**: the package is reachable at a stable `backupUrl`.

### fetch: Stored → Stored

- **Action**: any party issues a [`F_GET TEE_BACKUP`](../Reference/Operations/F_GET.md#tee_backup) instruction targeting $T$; $T$ re-emits the same backup package.
- **Caller**: any instruction issuer (paying the instruction fee).
- **Effects**: backup re-served via $T$'s proxy. Used when the external storage is missing or stale and the backup must be re-uploaded. Status unchanged.

### restore: Stored → Consumed

- **Action**: [`TeeWalletBackupManager.backupRestore(teeId_target, backupId, backupUrl, claimBackAddress)`](../Reference/Contracts/FlareTeeManager.md#wallet-management) — payable.
- **Caller**: `backupManager` of the wallet's project.
- **Guards**:
  - `backupId.walletId` exists; the key is not already available on `teeId_target`.
  - `backupId.rewardEpochId` is within the supported range for current data-provider participation.
  - `teeId_target` is in `PRODUCTION` on the wallet's extension.
- **Effects**:
  - Emits [`BackupRestoreTriggered(teeId_target, walletId, keyId, nonce)`](../Reference/Contracts/FlareTeeManagerEvents.md#backuprestoretriggered).
  - Dispatches a [`F_WALLET KEY_DATA_PROVIDER_RESTORE`](../Reference/Operations/F_WALLET.md#key_data_provider_restore) instruction to `teeId_target`; signers reconstruct the share-encryption secret and the TEE machine reassembles the key. See [KeyRestore](KeyRestore.md) for the rest of the flow.

## Invariants

- The `BackupId` uniquely identifies a backup; two distinct keys never share a `BackupId` even if they share `(walletId, keyId)` due to the `randomNonce`.
- A backup cannot be modified after `generate`; only re-uploads to `backupUrl` are possible. Trust in the backup is the trust in the data providers' threshold (per [Concepts/Keys § Backup Procedure](../Concepts/Keys.md#backup-procedure)).
- `backupManager = 0x0` disables the role; in that mode the project owner is the only address that can call `backupRestore`.

## Terminal States

`Stored` (steady state for a backup that has not been needed) or `Consumed` (a restore has been initiated). Neither is truly terminal; the same backup can be fetched and restored any number of times until the key itself is deleted via [KeyDelete](KeyDelete.md).

## Notes

- The backup's encryption is per-data-provider: only the share-holders' private keys can decrypt their respective shares, so external storage being compromised does not leak the key — recovery still requires a threshold of cooperating data providers under the recorded `rewardEpochId`.
- A backup tied to a stale `rewardEpochId` becomes unusable once enough share-holders have rotated out of the active signing policy; project owners should periodically issue [`F_GET TEE_BACKUP`](../Reference/Operations/F_GET.md#tee_backup) with a fresh `rewardEpochId` to refresh the share assignment.
- Backups stored externally are public ciphertext; the backup manager only needs to ensure availability, not confidentiality.
