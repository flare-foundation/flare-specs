# KeyRestore

State machine for restoring a previously [confirmed](KeyAdd.md#terminal-states) wallet key from backup onto a new TEE machine.
Restoration is the recovery path when a TEE is paused, banned, decommissioned, or being migrated; it requires cooperation from a threshold of [data providers](../../Terminology/Roles.md#data-provider) and a threshold of [key admins](../../Terminology/Roles.md#key-admin), each holding a share from the original [backup](../Concepts/Keys.md#key-backup).

## Preconditions

- The `(walletId, keyId)` exists on chain with `publicKey ≠ 0` (it was previously generated and confirmed; see [KeyAdd](KeyAdd.md)).
- The backup is reachable: either it is already published at a known URL, or the caller has uploaded a copy fetched from the source TEE's [TEE proxy](../Reference/Components/Proxy.md).
- The target TEE machine is in `PRODUCTION` and registered to the same `extensionId` as the source machine and the project.
- The target machine does not already hold the key.
- The source machine (`backupId.teeId`) is not in `INITIALIZED` (cannot restore from a never-attested machine).

## States

- `Triggered` — the on-chain `BackupRestoreTriggered` has fired; data providers and key admins have begun share collection but no `(walletId, keyId)` material exists on the target TEE.
- `Reconstructing` — the [TEE proxy](../Reference/Components/Proxy.md) has gathered enough shares (both `providersThreshold` weight and `adminsThreshold` count) and has dispatched them to the target machine; the machine is decrypting and combining.
- `Restored` — the target TEE has reconstructed `K = S_dp + S_ka` and produced a fresh [`KeyExistence`](../Reference/Types/Abi/Key.md#keyexistence) proof.
- `Confirmed` — `confirmKey` has stored the new `teeId` in `key.teeIds`; the key is now usable on the target machine.

## Initial State

`Triggered`.

## Transitions

### backupRestore: NotTriggered → Triggered

- **Action**: [`FlareTeeManager.backupRestore(teeId, backupId, backupUrl, claimBackAddress)`](../Reference/Contracts/FlareTeeManager.md#key-custody) — payable.
- **Caller**: project owner or `project.backupManager`.
- **Guards**:
  - `key.publicKey ≠ 0` and `backupId.publicKey = key.publicKey`
  - `teeMachine(target).status = PRODUCTION`
  - `teeMachine(backupId.teeId).status ≠ INITIALIZED`
  - `target ∉ key.teeIds`
  - `project.extensionId = teeMachine(target).extensionId = teeMachine(backupId.teeId).extensionId`
  - `project.keyType = backupId.keyType` and `project.signingAlgo = backupId.signingAlgo`
  - `teeMachine(target).initialSigningPolicyId ≤ backupId.rewardEpochId ≤ currentRewardEpochId + 1`
  - `msg.value ≥ fee(F_WALLET, KEY_DATA_PROVIDER_RESTORE)`
- **Effects**:
  - Emits [`BackupRestoreTriggered`](../Reference/Contracts/FlareTeeManagerEvents.md#backuprestoretriggered) and [`TeeInstructionsSent`](../Reference/Contracts/FlareTeeManagerEvents.md#teeinstructionssent).
  - Sends a [`F_WALLET KEY_DATA_PROVIDER_RESTORE`](../Reference/Operations/F_WALLET.md#key_data_provider_restore) instruction to the target TEE machine, with `submissionTag = end` so voting stays open for the full window.

### submitShares: Triggered → Reconstructing

- **Action**: each data provider and key admin runs the [augmentation procedure](../Reference/Operations/F_WALLET.md#augmentation) and submits a signed share via its [relay client](../Reference/Components/RelayClient.md). Off-chain, no contract call.
- **Caller**: data providers (via [signing policy](../../FSP/SigningPolicy.md) at `backupId.rewardEpochId`) and the wallet's key admins.
- **Guards** (per submission):
  - The submitter's `BackupRestoreTriggered` and `TeeInstructionsSent` events have enough block confirmations to be considered final.
  - The fetched backup is consistent with `backupId` (metadata, signatures, TEE signature all validate).
  - The submitter holds a share addressed to itself.
- **Effects**:
  - Each share is encrypted under the target TEE's public key and forwarded to its proxy.
  - The proxy aggregates shares until both thresholds (`providersThreshold` weight and `adminsThreshold` count) are reached.

### reconstruct: Reconstructing → Restored

- **Action**: the target TEE machine decrypts the shares, reconstructs `S_dp` and `S_ka`, and computes `K = S_dp + S_ka mod N`. Returns an [`ActionResponse`](../Concepts/Actions.md#action-responses) carrying a fresh [`SignedKeyExistenceProof`](../Reference/Types/Wire/Key.md#signedkeyexistenceproof) (with `restored = true`).
- **Caller**: the target TEE machine itself (action processing).
- **Guards** (failures route the state machine back to `Triggered`):
  - Enough decrypted shares from each pool to meet the thresholds; invalid shares are listed in `additionalResultStatus`.
- **Effects**:
  - If recovery succeeds, the TEE produces a key-existence proof and posts it through the proxy.
  - If recovery fails, the action response reports it; the workflow remains in `Triggered` and a fresh `backupRestore` (with corrected inputs or more honest holders) is required.

### confirmKey: Restored → Confirmed

- **Action**: [`FlareTeeManager.confirmKey(proof, teeSignature)`](../Reference/Contracts/FlareTeeManager.md#key-custody) — non-payable.
- **Caller**: project owner or `project.backupManager`.
- **Guards**:
  - `proof.publicKey = key.publicKey` (matches existing definition).
  - `proof.nonce > 0`
  - `proof.restored = TRUE`
  - `teeId ∉ key.teeIds` (no duplicate insertion).
  - `teeSignature` recovers to `teeMachine(target).publicKey`.
- **Effects**:
  - Adds the target `teeId` to `key.teeIds`.
  - Emits [`WalletKeyConfirmed`](../Reference/Contracts/FlareTeeManagerEvents.md#walletkeyconfirmed).

## Invariants

- A key's `publicKey` is never overwritten by restoration; a successful confirmation only adds a new entry to `teeIds`.
- A restored key keeps the wallet's `configConstants` (admins, cosigners, thresholds) bit-identical to the original; the TEE rejects any backup whose metadata diverges.
- The source TEE's per-key nonce records survive on the source machine even if the key is deleted there, preventing a stale nonce from accepting a restore later (see [KeyDelete invariants](KeyDelete.md#invariants)).

## Terminal States

`Confirmed`. From here the key is usable on the target TEE — same observable behaviour as a freshly-generated key.

For key migration between TEEs, follow `KeyRestore` to add the new machine, then [KeyDelete](KeyDelete.md) to remove the key from the old one; during the overlap the key signs on both machines.

## Notes

- The voting model is the proxy-level exception described in [Concepts/Voting § Outcomes](../Concepts/Voting.md#outcomes): both `threshold` and `end` actions fire at vote-box close, so the machine receives every share submitted before close.
- The TEE proxy cannot validate share authenticity until decryption; if too many submitted shares are corrupt, the action response surfaces the bad-share list and reconstruction fails.
- For end-to-end backup mechanics (Shamir construction, ECIES envelopes, share distribution), see [Concepts/Keys § Key Backup](../Concepts/Keys.md#key-backup).