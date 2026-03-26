# Restore Key from Backup

## Overview

This workflow covers restoring a signing key from backup onto a new TEE machine.
Key restoration is necessary when a TEE machine becomes unavailable, is decommissioned, or when migrating keys between machines.
The process requires cooperation from both data providers and key admins.
For the backup scheme (Shamir secret sharing, packaging, and distribution), see [Key Management](../TEE Management/Key Management.md).

## Prerequisites

- The key must have been previously generated and confirmed (public key must exist on-chain).
- The target TEE machine must be in `PRODUCTION` status.
- The source machine (identified in the backup ID) must not be in `INITIALIZED` status.
- The key must not already be available on the target TEE machine.
- The extension IDs of the project, source TEE, and target TEE must all match.
- The backup's `keyType` and `signingAlgo` must match the project configuration.
- The backup's `rewardEpochId` must be within valid bounds.
- A backup package must be available (either from the TEE proxy or uploaded to a URL).

---

## Steps

### Step 1: Initiate Key Restoration — `TeeWalletBackupManager.backupRestore()`

**Who can call:** Project owner or backup manager (`onlyOwnerOrBackupManager`).

**Parameters:**
- `teeId` (`address`) — the identity address of the target TEE machine on which to restore the key.
- `backupId` (`BackupId`) — the identifier of the backup to restore.
- `backupUrl` (`string`) — URL where the backup package is hosted. If no URL exists, the caller fetches the backup package from the TEE proxy and uploads it first.
- `claimBackAddress` (`address`) — address to claim back unused instruction fees.

**Requirements:**
- The target TEE machine must be in `PRODUCTION` status.
- The source machine (identified in `backupId.teeId`) must not be in `INITIALIZED` status.
- The key must not already be available on the target TEE machine.
- The key must have been confirmed (public key must exist on-chain).
- The `publicKey` in the backup ID must match the on-chain key.
- The target TEE's `initialSigningPolicyId` must be $\leq$ the backup's `rewardEpochId`.
- The backup's `rewardEpochId` must be $\leq$ the current reward epoch ID $+ 1$.
- The backup's `keyType` and `signingAlgo` must match the project configuration.
- The extension IDs of the project, source TEE, and target TEE must all match.
- The function is `payable` — sufficient value must be included to cover the instruction fee.

**What happens:**
1. The contract emits a [`KEY_DATA_PROVIDER_RESTORE`](../commands/F_WALLET--KEY_DATA_PROVIDER_RESTORE.md) instruction to the target TEE machine.
2. This signals the TEE network (data providers and key admins) to begin the share collection process.

**Events emitted:** [`BackupRestoreTriggered`](../Events.md#backuprestoretriggered), [`TeeInstructionsSent`](../Events.md#teeinstructionssent)

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
- `proof` (`KeyExistence`) — a key existence proof from the target TEE machine.
- `teeSignature` (`Signature`) — signature from the TEE machine over the proof.

**Requirements:**
- The target TEE machine must be in `PRODUCTION` status.
- The key ID must already exist on the wallet (from the original `addKey` call).
- The `teeId` must not already be in the key's TEE list.
- The proof must be consistent with the on-chain wallet and project configuration.
- The TEE signature must be valid.

**What happens:**
1. The contract verifies the proof and TEE signature.
2. It confirms that the public key matches the existing key definition.
3. The target `teeId` is added to the key's TEE list, indicating the key now exists on an additional machine.
4. The nonce for this `teeId` is recorded on-chain for future replay protection.

**Events emitted:** [`WalletKeyConfirmed`](../Events.md#walletkeyconfirmed)

---

## Notes

- **Key migration between TEEs:** Key migration moves a key from one TEE machine to another. This is a composite workflow: (1) restore the key on the new TEE using Steps 1-4 above, (2) confirm the restored key with `confirmKey()`, and (3) optionally [delete the key](key-delete.md) from the decommissioned machine. During migration, the key exists on both TEEs simultaneously until explicitly deleted from the old one, ensuring zero downtime for signing operations.
- **Extension binding:** Each `teeId` can be registered to at most one extension. Once the machine is confirmed via [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md), its extension is fixed. Each wallet belongs to exactly one extension, and a backup is valid only if the source and target machines belong to the same extension.
- **Share submission verification:** Data providers and key admins should verify on-chain events and block confirmations before submitting shares, ensuring:
  - The [`BackupRestoreTriggered`](../Events.md#backuprestoretriggered) and [`TeeInstructionsSent`](../Events.md#teeinstructionssent) events were emitted with sufficient confirmations.
  - The backup from the provided URL is consistent with the backup ID.
  - The `signature` and `teeSignature` fields in the backup package match the backup ID and metadata.
- For related workflows, see [key-add.md](key-add.md) for adding new keys, [key-delete.md](key-delete.md) for deleting keys, [wallet-setup.md](wallet-setup.md) for initial key creation, and [machine-lifecycle.md](machine-lifecycle.md) for TEE machine status management.
