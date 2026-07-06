# Key Management

Wallet keys generated and held inside TEE machines must remain available even when individual machines are paused, replaced, or banned.
Two systems ensure that availability:

- [Key existence proofs](#tee-key-existence-proof), produced by the TEE and verified on-chain, attest that a particular `(walletId, keyId)` currently exists on the machine.
- [Key backups](#key-backup), distributed as Shamir shares to [data providers](../../Terminology/Roles.md#data-provider) and [key admins](../../Terminology/Roles.md#key-admin), enable lost keys to be [restored](#key-restoration) onto another TEE.

For the on-chain data model around projects, wallets, and keys, see [Wallets](Wallets.md).
For the wallet-level entry points (`addKey`, `confirmKey`, `deleteKey`, `cleanUpTeeIds`, `backupRestore`), see [Wallet Keys](Wallets.md#wallet-keys).

## Wallet Private Key Data Structure

Each private key on a TEE machine is held alongside the following metadata:

- `walletId`, `keyId`: identifying the key within its [wallet](Wallets.md).
- `signingAlgo`, `keyType`: the [signing algorithm](#signing-algorithms) and [key types](#key-types) of the key.
- `privateKey`: the private key itself.
- `restored`: `true` if the key was produced by [restoration](#key-restoration), `false` if it was generated on-machine.
- `configConstants`: immutable; wallet [configuration](../Reference/Types/Abi/Key.md#keyconfigconstants) mirrored at key-generation. Carries the [key admin](../../Terminology/Roles.md#key-admin) information (`adminsPublicKeys` and `adminsThreshold`) and the optional [cosigner](Instructions.md#cosigners) set (`cosigners` and `cosignersThreshold`).

All fields except `configConstants` are defined at key generation; `configConstants` is fixed at key generation and enables [cosigner enforcement](../Reference/Components/Machine.md#cosigner-enforcement) on every system action that consumes the key.

### Signing Algorithms

The eligible signing algorithms are each identified by a `bytes32` hash of their name:

1. `keccak256-secp256k1-ecdsa`: ECDSA for EVM-compatible chains.
2. `sha512half-secp256k1-ecdsa`: ECDSA for XRP Ledger transactions.
3. `keccak256-secp256k1-vrf`: VRF proof generation (see [VRF Keys](#vrf-keys)).

### Key Types

1. `EVM`: keys for EVM-compatible signing.
2. `XRP`: keys for XRP Ledger signing.

### Wallet Key Variables

Independently of the above key data, every TEE machine maintains a per-key variable record that persists for the machine's lifetime (even after the key is deleted):

$$(\mathrm{walletId},\ \mathrm{keyId}) \Rightarrow (\mathrm{nonce},\ \mathrm{pauseNonce},\ \mathrm{status})$$

- `nonce`: replay-protection counter for state-changing operations (e.g. [`KEY_DELETE`](../Reference/Operations/F_WALLET.md#key_delete)).
- `pauseNonce`: random nonce reserved for [`PAUSE`](../Reference/Operations/F_WALLET.md) / [`RESUME`](../Reference/Operations/F_WALLET.md) operations.
- `status`: e.g. `active`, `paused`.

These variables are local to the TEE machine and are not included in its [backups](#key-backup).

## TEE Key Existence Proof

On key generation, the TEE machine produces a [`SignedKeyExistenceProof`](../Reference/Types/Wire/Key.md#signedkeyexistenceproof) for the new key in the form of a [`KeyExistence`](../Reference/Types/Abi/Key.md#keyexistence) struct signed by the TEE's identity key.
The proof binds the `(teeId, walletId, keyId, publicKey, keyType, signingAlgo, settingsVersion, settings)` tuple together with the key's nonce, restored flag, and [`configConstants`](../Reference/Types/Abi/Key.md#keyconfigconstants).
On-chain confirmation of the proof via `confirmKey` then writes the public key into the wallet's record (see [Wallets](Wallets.md#wallet-keys)).

The [TEE proxy](../Reference/Components/Proxy.md#key-data-store) refreshes its cached proofs for the machine's keys by combining [`KEY_INFO`](../Reference/Operations/F_GET.md#key_info) (returns `(walletId, keyId, nonce)` triples) with [`KEY_PROOF`](../Reference/Operations/F_GET.md#key_proof) (returns signed proofs for triples whose nonce changed since the last sync).

## VRF Keys

A TEE machine can also hold VRF keys, used for verifiable randomness.
VRF keys use the `keccak256-secp256k1-vrf` [signing algorithm](#signing-algorithms) and are managed by the same [`KEY_GENERATE`](../Reference/Operations/F_WALLET.md#key_generate) and [`KEY_DELETE`](../Reference/Operations/F_WALLET.md#key_delete) instructions as other wallet keys.
See [`F_WALLET VRF`](../Reference/Operations/F_WALLET.md#vrf) for the proof structure, on-chain verification, and randomness extraction.

## Key Backup

Every key is backed up at generation, with a fresh backup generated whenever the active [signing policy](../../FSP/SigningPolicy.md) changes at the TEE machine.

### Overview

The key $K$ is split in two levels.
First, it is split additively into two random shares.
Then, each share is split according to a secret sharing scheme:

$$K = S_\mathrm{dp} + S_\mathrm{ka} \pmod N$$

- $S_\mathrm{dp}$: the _data provider share_, which is further split using Shamir secret sharing over the active signing policy. Each provider receives a number of shares proportional to their weight, such that a $\mathrm{providersThreshold}$ proportion of weight can reconstruct the key.
- $S_\mathrm{ka}$: The _key admin share_, which is further split by an $(n, t)$-Shamir over the wallet's `adminsPublicKeys`, requiring `adminsThreshold` admins to reconstruct.

To recover $K$, both shares must be reconstructed.
Thus, the compromising the security of the backup requires compromising both the signing policy and at least $t$ key admins.

### Backup Metadata

Each key backup is identified by three values: its metadata, the [`BackupId`](../Reference/Types/Abi/Key.md#backupid), and the _backup hash_ (a $\mathrm{keccak256}$ hash of the ABI-encoded `BackupId`).

Metadata fields:

- `teeId`: identity of the TEE that holds the original key.
- `walletId`, `keyId`, `signingAlgo`, `keyType`, `publicKey`: information identifying the key.
- `rewardEpochId`: signing policy under which the backup was created (defines which data providers hold shares).
- `providersThreshold`: data provider threshold weight needed to recover $S_\mathrm{dp}$ (default $\approx 666/1000$).
- `adminsPublicKeys`, `adminsThreshold`: admin set and recovery threshold (mirror of the wallet's `configConstants`).
- `cosigners`, `cosignersThreshold`: cosigner information, if configured.
- `randomNonce`: a nonce produced by the TEE machine at backup time.

### Backup Procedure

To backup a key $K$ on a TEE machine with identity $\mathrm{TEE}_\mathrm{id}$, the following steps are performed:

1. Sample $S_\mathrm{dp}, S_\mathrm{ka}$ uniformly with $K = S_\mathrm{dp} + S_\mathrm{ka} \pmod N$.
2. Split $S_\mathrm{dp}$ into $1000$ shares using a Shamir Secret Sharing scheme with threshold $\lfloor \mathrm{providersThreshold} * 1000 \rfloor$. Shares are assigned to data providers so that a provider $j$ with weight $W_j$ in the active signing policy is assigned $\lfloor W_j * 1000 \rfloor$ shares.
3. Split $S_\mathrm{ka}$ using an $(N_\mathrm{admin},\ \mathrm{adminsThreshold})$-Shamir Secret Sharing scheme over the key admins. Each admin is assigned a single share.
4. For each recipient $i$, build a $\mathrm{pack}_i$ containing:
   - `shareData`: the share(s) for $i$.
   - `backupId`: the backup identifier.
   - `holdersPublicKey`: the holders public identity key $\text{pk}_i$.
   - `signature`: signature over the above data performed by the TEE machine using the key being backed up.
5. Encrypt $\mathrm{pack}_i$ under $\mathrm{pk}_i$ and wrap into a _holder backup package_ $\mathrm{Backup}_i = (\mathrm{Enc}_{\mathrm{pk}_i}(\mathrm{pack}_i),\ \mathrm{pk}_i)$.
6. Aggregate every $\mathrm{Backup}_i$ together with the [backup metadata](#backup-metadata) and two signatures (one by the key being backed up, one by the TEE identity) into a single backup package, served to the TEE proxy.

Recipients fetch their package from the TEE proxy's [backup API](../Reference/Components/Proxy.md#external-read-apis), decrypt their share(s), and store them off-chain.

### Key Restoration

Restoration is initiated by an authorized address (the wallet's [project owner](../../Terminology/Roles.md#project-owner) or its `backupManager`) calling [`backupRestore`](../Reference/Contracts/FlareTeeManager.md#key-custody) on [`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md) with the backup identifier, the URL to fetch it from, and the destination TEE machine (must differ from the original)..

The flow:

1. Each data provider and key admin extracts and decrypts its holder backup, recovering its share of $S_\mathrm{dp}$ or $S_\mathrm{ka}$.
2. Each holder re-encrypts the decrypted share under the destination TEE's public key, e.g. $\mathrm{Enc}_{\mathrm{TEE}_\mathrm{id}}({S_\mathrm{ka}}^{i})$.
3. Each holder submits a [`KEY_DATA_PROVIDER_RESTORE`](../Reference/Operations/F_WALLET.md#key_data_provider_restore) instruction with the backup metadata in `additionalFixedMessage` and the encrypted share in `additionalVariableMessage`.
4. The TEE proxy sets `submissionTag = end` so that [voting](Voting.md) on the backup instruction stays open for the full window. At the end of voting, if both recovery thresholds are met, the proxy delivers the recovery bundle to the destination TEE.
5. The TEE machine decrypts each share, reconstructs $S_\mathrm{dp}$ and $S_\mathrm{ka}$, and recovers $K = S_\mathrm{dp} + S_\mathrm{ka} \pmod N$.
6. The TEE machine returns an [action response](Actions.md#action-responses) indicating success or failure and, if any holders submitted invalid shares, names them.
7. The destination TEE machine produces a fresh [key existence proof](#tee-key-existence-proof) for the restored key.

The TEE proxy cannot tell whether a submitted share is valid until decryption; that is why step $6$ surfaces the bad-share list.
If too many shares were invalid, recovery fails and the action response reports it.
[Wallet key variables](#wallet-key-variables) (`nonce`, `pauseNonce`, `status`) are machine-local and are _not_ restored; they start fresh on the destination machine.

> **Note:** The wallet backup metadata received by the destination machine is unsigned. However, this does not present a security issue: to install incorrect backup meta data during restoration, malicious parties would require access to enough Shamir shares to issue a key restore action with incorrect metadata. However, such a large number of collaborating malicious parties is already ruled out by the security model; the secret shares required to do this would already be sufficient to recover the key directly.

## Direct Backup/Restore

A second backup and restore mechanism, known as direct backup and restore, allows for a key to be directly migrated between two TEE machines.
It is gated by a machine-path list signed by the [extension's](../FCE/Concepts.md#extension-data-structure) governance, designating pairs `source teeId, destination teeID` of machines for which direct backup and restore is permitted.

### Backup

The wallet owner or backup manager calls the `directBackup` function, specifying the source TEE machine, key to be backed up, and destination TEE machine.
Both machines must be registered to the extension.
A [`KEY_DIRECT_BACKUP`](../Reference/Operations/F_WALLET.md#key_direct_backup) instruction is submitted, with the source machine preparing an encrypted backup package for the destination machine.
The source TEE machine returns a `DirectBackupTriggered` event, returning the `instructionId` required to complete the restore process.

### Restore
The wallet owner or backup manager this time calls the `directRestore` function, including as arguments the `instructionID` as `BackupInstructionId` and the destination $\mathrm{TEE}_\mathrm{ID}$.
This dispatches a [`KEY_DIRECT_RESTORE`](../Reference/Operations/F_WALLET.md#key_direct_restore) instruction to the destination TEE machine.
The destination machine's proxy fetches the backup package from the source TEE machine and submits it to the destination machine, which returns a fresh [key existence proof](#tee-key-existence-proof) for the restored key.

