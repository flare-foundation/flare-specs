# Key Lifecycle Operations

## Overview

This workflow covers managing wallet keys after initial setup -- deletion, backup, restoration, and migration between TEE machines. The key backup system uses a two-round Shamir secret sharing scheme to ensure keys can be recovered even if a TEE machine becomes unavailable. Key restoration requires cooperation from both data providers and key admins, preserving the distributed trust model.

For full details on key data structures and backup cryptography, see the [Key Management specification](../TEE%20Management/Key%20Management.md).

## Prerequisites

- Wallet must be in `PRODUCTION` status with at least one confirmed key. See [wallet-setup.md](wallet-setup.md) for the initial wallet creation and key generation flow.
- TEE machines referenced in key operations must be in `PRODUCTION` status.
- For backup restoration, data providers must be enrolled in the signing policy that was active when the backup was created.
- Key admins must have been set during wallet initialization (via `setAdmins`).

---

## Step 1: Delete Key -- `TeeWalletKeyManager.deleteKey()`

**Who can call:** Project owner or wallet admin.

**Parameters:**
- `teeId` (`address`) -- the identity address of the TEE machine from which the key should be deleted.
- `walletId` (`bytes32`) -- the wallet ID containing the key.
- `keyId` (`uint64`) -- the key ID to delete from the specified TEE.

**Requirements:**
- The TEE machine identified by `teeId` must be in `PRODUCTION` status.
- The key must exist on the specified TEE (i.e., `teeId` must be in the key's TEE list).

**What happens:**
1. The contract sends a `KEY_DELETE` instruction to the specified TEE machine, parameterized as `KEY_DELETE(teeId, walletId, keyId)`.
2. The TEE machine removes the private key material from its memory.
3. The `teeId` is removed from the key's TEE list on-chain.
4. The key definition itself remains on the wallet -- only the association with the specific TEE is removed. The key may still exist on other TEE machines.
5. On the TEE machine, the wallet key variables (`nonce`, `pauseNonce`, `status`, `expiry`) for that key are retained even after deletion.

**Events emitted:** `WalletKeyDeleted`

> **Note:** Deleting a key from all TEEs does not remove the key definition from the wallet. The key can be restored via the backup process described below.

---

## Step 2: Automatic Key Backup -- Shamir Secret Sharing

Key backup is triggered automatically by the TEE machine in two cases:
- When a new key is generated (via `addKey`).
- When the signing policy is updated at the TEE machine (triggers re-backup of all keys on the machine).

There is no user-facing contract call for triggering a backup.

**What happens:**

The backup process for a key $K$ uses a two-round secret sharing scheme:

### Round 1: (2,2)-Secret Sharing

1. The TEE generates a random value $d_1$ as the data provider share $S_\mathrm{dp}$.
2. It computes $d_2 = K - d_1$ as the key admin share $S_\mathrm{ka}$.
3. Both shares are required to reconstruct the original key.

### Round 2: Threshold Splitting of Each Share

4. The data provider share $S_\mathrm{dp}$ is split into 1000 shares using a $(1000, \lfloor \mathrm{providersThreshold} \times 1000 \rfloor)$-Shamir secret sharing scheme. Each data provider receives $\lfloor W_j \times 1000 \rfloor$ shares proportional to its weight $W_j$ in the current signing policy. The default `providersThreshold` is 66%.
5. The key admin share $S_\mathrm{ka}$ is split into $N_\mathrm{admin}$ shares using an $(N_\mathrm{admin}, \mathrm{adminsThreshold})$-Shamir secret sharing scheme. Each admin receives exactly one share.

### Packaging and Distribution

6. For each recipient (data provider or key admin), a package is prepared containing:
   - `shareData` -- the share or shares for the recipient.
   - `backupID` -- the identifier for this backup (see below).
   - `holdersPublicKey` -- the public key of the receiving entity.
   - `signature` -- signature of the above fields with the private key being backed up.
7. Each package is encrypted under the recipient's public key to produce a holder backup package: $\mathrm{Backup}_i = (\text{Enc}_{\mathrm{pk}_i}(\mathrm{pack}_i), \mathrm{pk}_i)$.
8. All holder backup packages are combined with the backup metadata and signed twice (once by the key being backed up, once by the TEE's identity key) to form the full backup package.
9. The backup package is sent to the TEE proxy for distribution.

### BackupId Structure

The backup is identified by a `BackupId` struct:

```solidity
struct BackupId {
    address teeId;
    bytes32 walletId;
    uint64 keyId;
    bytes32 keyType;
    bytes32 signingAlgo;
    bytes publicKey;
    uint24 rewardEpochId;
    uint256 randomNonce;
}
```

The backup hash is `keccak256(abi.encode(backupId))`.

### Backup Metadata

The full backup metadata contains all `BackupId` fields plus:
- `configConstants` -- the key's configuration constants, including `providersThreshold` (also known as `dpThreshold`), `adminsPublicKeys`, `adminsThreshold`, `cosigners`, and `cosignersThreshold`.

**Events emitted:** None (backup is handled internally by the TEE machine and proxy).

> **Note:** The wallet key variables (`nonce`, `pauseNonce`, `status`, `expiry`) are not included in the backup. These values are managed independently on each TEE machine.

---

## Step 3: Initiate Key Restoration -- `TeeWalletBackupManager.backupRestore()`

**Who can call:** Any Flare user (typically the backup manager address set on the project).

**Parameters:**
- `teeId` (`address`) -- the identity address of the target TEE machine on which to restore the key. This must be a different machine from the one that created the backup.
- `backupId` (`BackupId`) -- the identifier of the backup to restore.
- `backupUrl` (`string`) -- URL where the backup package is hosted. If no URL exists, the caller fetches the backup package from the TEE proxy and uploads it first.

**Requirements:**
- The target TEE machine must be registered and confirmed (via `TeeAvailabilityCheck` proof) in the same extension as the source machine. The proof must be recent (e.g., within 1 day).
- The source machine (identified in the `backupId`) must have been confirmed in the same extension at least once.
- Smart contracts will only emit the `KEY_DATA_PROVIDER_RESTORE` instruction if the extension of the target and source machines match.

**What happens:**
1. The contract emits a `KEY_DATA_PROVIDER_RESTORE` instruction, parameterized as `KEY_DATA_PROVIDER_RESTORE(teeId, backupId, backupUrl, nonce)`.
2. This signals the TEE network (data providers and key admins) to begin the share collection process.

**Events emitted:** `TeeInstructionsSent`

---

## Step 4: Share Collection -- Data Providers and Key Admins Submit Shares

**Who can call:** Data providers and key admins who hold backup shares.

**Requirements:**
- The `KEY_DATA_PROVIDER_RESTORE` event must have been emitted from the blockchain with sufficient block confirmations (e.g., 3 confirmations).
- The backup obtained from the provided URL must be consistent and match the backup ID (metadata, signatures, and TEE signature must all validate).

**What happens:**
1. Each data provider and key admin retrieves their holder backup package from the backup URL.
2. They decrypt their key share(s) using their private key.
3. They re-encrypt their share(s) under the public key of the target TEE machine (the `teeId` specified in step 3).
4. They submit a TEE instruction containing the encrypted share:
   - `additionalFixedMessage`: the backup metadata.
   - `additionalVariableMessage`: the encrypted share.
5. The TEE proxy collects incoming shares with the `submissionTag` set to `end`, keeping voting open for the maximum duration to gather as many shares as possible.

**Events emitted:** None (shares are submitted as instructions processed by the proxy).

---

## Step 5: TEE Reconstruction -- Target TEE Decrypts and Recovers the Key

**What happens:**
1. Once the TEE proxy has received sufficient shares from both data providers (meeting the `providersThreshold` weight) and key admins (meeting the `adminsThreshold` count), it prepares the recovery action.
2. The proxy submits all collected encrypted shares to the target TEE machine.
3. The TEE machine decrypts all shares using its private key.
4. It recovers the data provider share $S_\mathrm{dp}$ and key admin share $S_\mathrm{ka}$ from the Shamir shares.
5. It reconstructs the original key $K = S_\mathrm{dp} + S_\mathrm{ka}$.
6. The TEE returns an action response indicating success or failure. If any share holders submitted invalid shares, the response includes a list of those entities.
7. If too many shares were invalid, key recovery fails, and this is indicated in the action response.

**Events emitted:** None (internal TEE processing).

> **Testing:** The `KEY_DATA_PROVIDER_RESTORE_TEST` command can be used to test the key restoration process without affecting production keys.

---

## Step 6: Confirm Restored Key -- `TeeWalletKeyManager.confirmKey()`

**Who can call:** Project owner or backup manager.

**Parameters:**
- `proof` (`KeyExistence`) -- a `TeeKeyExistence` proof from the target TEE machine containing:
  - `teeId` (`address`) -- the target TEE's identity address.
  - `walletId` (`bytes32`) -- the wallet ID.
  - `keyId` (`uint64`) -- the key ID.
  - `nonce` (`uint256`) -- must be greater than 0 for restored keys.
  - `publicKey` (`bytes`) -- must match the original key's public key.
  - `keyType` (`bytes32`) -- must match the project's key type.
  - `signingAlgo` (`bytes32`) -- must match the project's signing algorithm.
  - `configConstants` (`KeyConfigConstants`) -- must match the wallet's admin and cosigner configuration.
  - `restored` (`bool`) -- must be `true` for restored keys.
  - `settingsVersion` (`bytes32`) -- TEE settings version.
  - `settings` (`bytes`) -- TEE settings data.
- `teeSignature` (`bytes`) -- signature from the TEE machine over the proof.

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

## Step 7: Key Migration Between TEEs

Key migration moves a key from one TEE machine to another. This is a composite workflow using the operations described above.

**What happens:**
1. **Add key on the new TEE** -- either:
   - Use `addKey()` to generate a fresh key on the new TEE (this creates a new key, not a migration), or
   - Use backup restore (steps 3-6 above) to reconstruct the existing key on the new TEE.
2. **If restoring via backup:**
   - Initiate restoration with `backupRestore()` targeting the new TEE (step 3).
   - Wait for share collection from data providers and key admins (step 4).
   - Target TEE reconstructs the key (step 5).
   - Confirm the restored key with `confirmKey()` (step 6).
3. **Optionally delete key from the old TEE** -- use `deleteKey()` (step 1) to remove the key from the decommissioned or retired machine.

> **Note:** During migration, the key exists on both TEEs simultaneously until explicitly deleted from the old one. This ensures zero downtime for signing operations.

---

## Step 8: Clean Up Stale TEE IDs -- `TeeWalletKeyManager.cleanUpTeeIds()`

**Who can call:** Project owner or wallet admin.

**Parameters:**
- `walletId` (`bytes32`) -- the wallet ID.
- `keyId` (`uint64`) -- the key ID whose TEE list should be cleaned.

**Requirements:**
- The key must exist on the wallet.
- There must be stale TEE IDs in the key's TEE list (TEEs that no longer hold the key or have been decommissioned).

**What happens:**
1. The contract iterates through the TEE IDs associated with the specified key.
2. TEE IDs corresponding to machines that no longer hold the key are removed from the key definition's TEE list.
3. This is typically used after a TEE machine has been decommissioned or retired from the network.

**Events emitted:** None specified in the contract interface.

---

## Backup and Restore Security Considerations

- Each `teeId` can be registered to at most one extension. Once the machine is confirmed via `TeeAvailabilityCheck`, its extension is fixed.
- Each wallet belongs to exactly one extension.
- A backup is valid only if the source and target machines belong to the same extension.
- Data providers and key admins should verify on-chain events and block confirmations before submitting shares, ensuring:
  - The `KEY_DATA_PROVIDER_RESTORE` event was emitted with sufficient confirmations.
  - The backup from the provided URL is consistent with the backup ID.
  - The `signature` and `teeSignature` fields in the backup package match the backup ID and metadata.

---

## Cross-References

- [wallet-setup.md](wallet-setup.md) -- initial key creation via `addKey()` and `confirmKey()` during wallet setup.
- [machine-lifecycle.md](machine-lifecycle.md) -- TEE machine registration, production status, and decommissioning.
- [ftdc-attestation.md](ftdc-attestation.md) -- `TeeAvailabilityCheck` attestation required for target TEE during restoration.
- [Key Management specification](../TEE%20Management/Key%20Management.md) -- full specification of key data structures, backup cryptography, and security model.
- [Projects and Ownership](../Operations/Projects%20and%20Ownership.md) -- key definitions, key types, and project configuration.
