# Restore Key from Backup

## Overview

This workflow covers restoring a signing key from backup onto a new TEE machine.
Key restoration is necessary when a TEE machine becomes unavailable, is decommissioned, or when migrating keys between machines.
The process requires cooperation from both data providers and key admins.
For the backup scheme (Shamir secret sharing, packaging, and distribution), see [Key Management](../TEE%20Management/Key%20Management.md).

## Prerequisites

- The key must have been previously generated and confirmed (via [key-add.md](key-add.md) or [wallet-setup.md](wallet-setup.md) Steps 9–10).
- The target TEE machine must be in `PRODUCTION` status and belong to the same extension as the source machine.
- Data providers must be enrolled in the signing policy that was active when the backup was created.
- Key admins must have been set during wallet initialization (via `setAdmins`).
- A backup package must be available (either from the TEE proxy or uploaded to a URL).

---

## Steps

### Step 1: Initiate Key Restoration — `TeeWalletBackupManager.backupRestore()`

**Who can call:** Any Flare user (typically the backup manager address set on the project).

**Parameters:**
- `teeId` (`address`) — the identity address of the target TEE machine on which to restore the key. This must be a different machine from the one that created the backup.
- `backupId` (`BackupId`) — the identifier of the backup to restore.
- `backupUrl` (`string`) — URL where the backup package is hosted. If no URL exists, the caller fetches the backup package from the TEE proxy and uploads it first.

**Requirements:**
- The target TEE machine must be registered and confirmed (via [TeeAvailabilityCheck](fdc2-attestation.md) proof) in the same extension as the source machine. The proof must be recent (e.g., within $1$ day).
- The source machine (identified in the `backupId`) must have been confirmed in the same extension at least once.
- Smart contracts will only emit the `KEY_DATA_PROVIDER_RESTORE` instruction if the extensions of the target and source machines match.

**What happens:**
1. The contract emits a `KEY_DATA_PROVIDER_RESTORE` instruction, parameterized as `KEY_DATA_PROVIDER_RESTORE(teeId, backupId, backupUrl, nonce)`.
2. This signals the TEE network (data providers and key admins) to begin the share collection process.

**Events emitted:** `TeeInstructionsSent`

---

### Step 2: Share Collection — Data Providers and Key Admins Submit Shares

**Who participates:** Data providers and key admins who hold backup shares.

**Requirements:**
- The `KEY_DATA_PROVIDER_RESTORE` event must have been emitted from the blockchain with sufficient block confirmations (e.g., $3$ confirmations).
- The backup obtained from the provided URL must be consistent and match the backup ID (metadata, signatures, and TEE signature must all validate).

**What happens:**
1. Each data provider and key admin retrieves their holder backup package from the backup URL.
2. They decrypt their key share(s) using their private key.
3. They re-encrypt their share(s) under the public key of the target TEE machine (the `teeId` specified in Step 1).
4. They submit a TEE instruction containing the encrypted share:
   - `additionalFixedMessage`: the backup metadata.
   - `additionalVariableMessage`: the encrypted share.
5. The TEE proxy collects incoming shares with the `submissionTag` set to `end`, keeping voting open for the maximum duration to gather as many shares as possible.

---

### Step 3: TEE Reconstruction — Target TEE Decrypts and Recovers the Key

**What happens:**
1. Once the TEE proxy has received sufficient shares from both data providers (meeting the `providersThreshold` weight) and key admins (meeting the `adminsThreshold` count), it prepares the recovery action.
2. The proxy submits all collected encrypted shares to the target TEE machine.
3. The TEE machine decrypts all shares using its private key.
4. It recovers the data provider share $S_\mathrm{dp}$ and key admin share $S_\mathrm{ka}$ from the Shamir shares.
5. It reconstructs the original key $K = S_\mathrm{dp} + S_\mathrm{ka}$.
6. The TEE returns an action response indicating success or failure. If any share holders submitted invalid shares, the response includes a list of those entities.
7. If too many shares were invalid, key recovery fails, and this is indicated in the action response.

---

### Step 4: Confirm Restored Key — `TeeWalletKeyManager.confirmKey()`

**Who can call:** Project owner or backup manager.

**Parameters:**
- `proof` (`KeyExistence`) — a `TeeKeyExistence` proof from the target TEE machine containing:
  - `teeId` (`address`) — the target TEE's identity address.
  - `walletId` (`bytes32`) — the wallet ID.
  - `keyId` (`uint64`) — the key ID.
  - `nonce` (`uint256`) — must be greater than $0$ for restored keys.
  - `publicKey` (`bytes`) — must match the original key's public key.
  - `keyType` (`bytes32`) — must match the project's key type.
  - `signingAlgo` (`bytes32`) — must match the project's signing algorithm.
  - `configConstants` (`KeyConfigConstants`) — must match the wallet's admin and cosigner configuration.
  - `restored` (`bool`) — must be `true` for restored keys.
  - `settingsVersion` (`bytes32`) — TEE settings version.
  - `settings` (`bytes`) — TEE settings data.
- `teeSignature` (`bytes`) — signature from the TEE machine over the proof.

**Requirements:**
- The target TEE machine must be in `PRODUCTION` status.
- The key ID must already exist on the wallet (from the original `addKey` call).
- For restored keys: `nonce > 0` and `restored == true`.
- The public key must match the originally confirmed public key.
- The `configConstants` must match the wallet's current admin and cosigner settings.
- The TEE signature must be valid.

**What happens:**
1. The contract verifies the proof and TEE signature.
2. It confirms that the public key matches the existing key definition.
3. The target `teeId` is added to the key's TEE list, indicating the key now exists on an additional machine.
4. The key is marked as restored on this TEE.

**Events emitted:** `WalletKeyConfirmed`

---

## Notes

- **Key migration between TEEs:** Key migration moves a key from one TEE machine to another. This is a composite workflow: (1) restore the key on the new TEE using Steps 1-4 above, (2) confirm the restored key with `confirmKey()`, and (3) optionally [delete the key](key-delete.md) from the decommissioned machine. During migration, the key exists on both TEEs simultaneously until explicitly deleted from the old one, ensuring zero downtime for signing operations.
- **Extension binding:** Each `teeId` can be registered to at most one extension. Once the machine is confirmed via `TeeAvailabilityCheck`, its extension is fixed. Each wallet belongs to exactly one extension, and a backup is valid only if the source and target machines belong to the same extension.
- **Share submission verification:** Data providers and key admins should verify on-chain events and block confirmations before submitting shares, ensuring:
  - The `KEY_DATA_PROVIDER_RESTORE` event was emitted with sufficient confirmations.
  - The backup from the provided URL is consistent with the backup ID.
  - The `signature` and `teeSignature` fields in the backup package match the backup ID and metadata.
- For related workflows, see [key-add.md](key-add.md) for adding new keys, [key-delete.md](key-delete.md) for deleting keys, [wallet-setup.md](wallet-setup.md) for initial key creation, and [machine-lifecycle.md](machine-lifecycle.md) for TEE machine status management.
