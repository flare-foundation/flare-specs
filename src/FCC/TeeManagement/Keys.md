# Key Management

Wallet keys generated and held inside TEE machines must remain available even when individual machines are paused, replaced, or banned.
Two systems give that availability:

- [Key existence proofs](#tee-key-existence-proof), produced by the TEE and verified on-chain, attest that a particular `(walletId, keyId)` still exists on the machine.
- [Key backups](#key-backup), distributed as Shamir shares to [data providers](../../Terminology/Roles.md#data-provider) and [key admins](../../Terminology/Roles.md#key-admin), let the key be [restored](#key-restoration) onto another TEE.

For the on-chain data model around projects, wallets, and keys, see [Wallets](Wallets.md).
For the wallet-level entry points (`addKey`, `confirmKey`, `deleteKey`, `cleanUpTeeIds`, `backupRestore`), see [Wallets — Wallet Keys](Wallets.md#wallet-keys).

## Wallet Private Key Data Structure

Each private key on a TEE machine is held alongside this structure:

- `walletId`, `keyId`: identifying the key within its [wallet](Wallets.md).
- `signingAlgo`, `keyType`: see [Signing Algorithms](#signing-algorithms) and [Key Types](#key-types).
- `privateKey`: the key material itself.
- `restored`: `true` if the key was produced by [restoration](#key-restoration), `false` if it was generated on-machine.
- `configConstants`: immutable wallet-side configuration mirrored at key-generation time — see [`KeyConfigConstants`](../Reference/Types/Abi/Key.md#keyconfigconstants).
  Carries the [key admins](../../Terminology/Roles.md#key-admin) (`adminsPublicKeys` and `adminsThreshold`) and the optional [cosigner](../Concepts/Instructions.md#cosigners) set (`cosigners` and `cosignersThreshold`).

All fields except `configConstants` are set at key generation; `configConstants` is fixed at key generation and is what [cosigner enforcement](../Reference/Components/Machine.md#cosigner-enforcement) compares against on every system action that consumes the key.

### Signing Algorithms

Each algorithm is identified by a `bytes32` hash of its name:

1. `keccak256-secp256k1-ecdsa`: ECDSA for EVM-compatible chains.
2. `sha512half-secp256k1-ecdsa`: ECDSA for XRP Ledger transactions.
3. `keccak256-secp256k1-vrf`: VRF proof generation (see [VRF Keys](#vrf-keys)).

### Key Types

1. `EVM`: keys for EVM-compatible signing.
2. `XRP`: keys for XRP Ledger signing.

### Wallet Key Variables

Independently of the key data above, every TEE machine maintains a per-key variable record that persists for the machine's lifetime (even after the key is deleted):

$$(\mathrm{walletId},\ \mathrm{keyId}) \Rightarrow (\mathrm{nonce},\ \mathrm{pauseNonce},\ \mathrm{status},\ \mathrm{expiry})$$

- `nonce`: replay-protection counter for state-changing operations (e.g. [`KEY_DELETE`](../Reference/Operations/F_WALLET.md#key_delete)).
- `pauseNonce`: random nonce reserved for [`PAUSE`](../Reference/Operations/F_WALLET.md) / [`RESUME`](../Reference/Operations/F_WALLET.md) operations.
- `status`: e.g. `active`, `paused`.
- `expiry`: TEE-side expiry time. After this timestamp the key is deleted automatically.

These variables are machine-local and are _not_ included in [backups](#key-backup) — they live with the machine, not with the key.

## TEE Key Existence Proof

On key generation, the TEE machine produces a [`KeyExistence`](../Reference/Types/Abi/Key.md#keyexistence) struct signed by the TEE's identity key — the [`SignedKeyExistenceProof`](../Reference/Types/Wire/Key.md#signedkeyexistenceproof).
The proof binds the `(teeId, walletId, keyId, publicKey)` tuple together with the key's nonce, restored flag, and [`configConstants`](../Reference/Types/Abi/Key.md#keyconfigconstants); on-chain confirmation via `confirmKey` writes the public key into the wallet's record (see [Wallets](Wallets.md#wallet-keys)).

The [TEE proxy](../Reference/Components/Proxy.md#key-data-store) refreshes its cached proofs by combining [`KEY_INFO`](../Reference/Operations/F_GET.md#key_info) (returns `(walletId, keyId, nonce)` triples) with [`KEY_PROOF`](../Reference/Operations/F_GET.md#key_proof) (returns signed proofs for triples whose nonce changed since the last sync).

## VRF Keys

A TEE machine can also hold VRF keys, used for verifiable randomness.
VRF keys use the `keccak256-secp256k1-vrf` [signing algorithm](#signing-algorithms) and are managed by the same [`KEY_GENERATE`](../Reference/Operations/F_WALLET.md#key_generate) and [`KEY_DELETE`](../Reference/Operations/F_WALLET.md#key_delete) instructions as other wallet keys.
See [`F_WALLET VRF`](../Reference/Operations/F_WALLET.md#vrf) for the proof structure, on-chain verification, and randomness extraction.

## Key Backup

Every key is backed up at generation, and re-backed up whenever the [signing policy](../../FSP/SigningPolicy.md) changes at the holding TEE.

### Overview

The key $K$ is split into two random additive shares:

$$K = S_\mathrm{dp} + S_\mathrm{ka} \pmod N$$

- $S_\mathrm{dp}$ (the _data-provider share_) is further split with Shamir secret sharing over the active signing policy, weighted by provider weight, so a $\mathrm{providersThreshold}$ proportion of weight can reconstruct it.
- $S_\mathrm{ka}$ (the _key-admin share_) is further split with $(n, t)$-Shamir over the wallet's `adminsPublicKeys`, requiring `adminsThreshold` admins to reconstruct.

To recover $K$, both shares must be reconstructed; either signing-policy compromise alone or admin compromise alone is insufficient.

### Backup Metadata

Each backup is identified by three values: the metadata, the [`BackupId`](../Reference/Types/Abi/Key.md#backupid), and the _backup hash_ ($\mathrm{keccak256}$ of the ABI-encoded `BackupId`).

Metadata fields:

- `teeId`: identity of the TEE that holds the original key.
- `walletId`, `keyId`, `signingAlgo`, `keyType`, `publicKey`: identifying the key.
- `rewardEpochId`: signing policy under which the backup was created (fixes which data providers hold shares).
- `providersThreshold`: data-provider threshold weight needed to recover $S_\mathrm{dp}$ (default $\approx 666/1000$).
- `adminsPublicKeys`, `adminsThreshold`: admin set and recovery threshold (mirror of the wallet's `configConstants`).
- `cosigners`, `cosignersThreshold`: cosigner set, if configured.
- `randomNonce`: a nonce produced by the TEE at backup time.

### Backup Procedure

For a key $K$ on TEE $\mathrm{TEE}_\mathrm{id}$:

1. Sample $S_\mathrm{dp}, S_\mathrm{ka}$ uniformly with $K = S_\mathrm{dp} + S_\mathrm{ka} \pmod N$.
2. Split $S_\mathrm{dp}$ into $1000$ Shamir shares with threshold $\lfloor \mathrm{providersThreshold} * 1000 \rfloor$.
   Each provider with weight $W_j$ in the active signing policy is assigned $\lfloor W_j * 1000 \rfloor$ of those shares.
3. Split $S_\mathrm{ka}$ with $(N_\mathrm{admin},\ \mathrm{adminsThreshold})$-Shamir over the wallet admins; admin $i$ receives share $S_\mathrm{ka}^{i}$.
4. For each recipient $i$, build a $\mathrm{pack}_i$ containing:
   - `shareData`: the share(s) for $i$.
   - `backupId`: the backup identifier.
   - `holdersPublicKey`: $\mathrm{pk}_i$.
   - `signature`: signature over the above with the key being backed up.
5. Encrypt $\mathrm{pack}_i$ under $\mathrm{pk}_i$ and wrap into a _holder backup package_ $\mathrm{Backup}_i = (\mathrm{Enc}_{\mathrm{pk}_i}(\mathrm{pack}_i),\ \mathrm{pk}_i)$.
6. Aggregate every $\mathrm{Backup}_i$ together with the [backup metadata](#backup-metadata) and two signatures (one by the key being backed up, one by the TEE identity) into a single backup package, served to the TEE proxy.

Recipients fetch their package from the TEE proxy's [backup API](../Reference/Components/Proxy.md#external-read-apis), decrypt their share(s), and store them.

### Key Restoration

Restoration is initiated by an authorized address (the wallet's [project owner](../../Terminology/Roles.md#project-owner) or its `backupManager`) calling `backupRestore` on [`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md):

```solidity
backupRestore(backupId, backupURL, teeId, randomNonce)
```

- `backupId`: identifies the backup to restore.
- `backupURL`: where the backup package can be fetched. If the URL does not already exist, the caller uploads the package fetched from the source TEE proxy.
- `teeId`: destination TEE machine (must differ from the original TEE).
- `randomNonce`: nonce used at backup time.

The flow:

1. Each data provider and key admin extracts and decrypts the holder backup package addressed to it, recovering its share of $S_\mathrm{dp}$ or $S_\mathrm{ka}$.
2. Each holder re-encrypts the decrypted share under the destination TEE's public key, e.g. $\mathrm{Enc}_{\mathrm{TEE}_\mathrm{id}}(S_\mathrm{ka}^{i})$.
3. Each holder submits an [`KEY_DATA_PROVIDER_RESTORE`](../Reference/Operations/F_WALLET.md#key_data_provider_restore) instruction with the backup metadata in `additionalFixedMessage` and the encrypted share in `additionalVariableMessage`.
   Data providers go through their [relay client](../Reference/Components/RelayClient.md) (see [`KEY_DATA_PROVIDER_RESTORE` augmentation](../Reference/Operations/F_WALLET.md#augmentation)); admins without a relay client use an equivalent offline tool.
4. The TEE proxy sets `submissionTag = end` so [voting](../Concepts/Voting.md) stays open for the full window. At the end of voting, if both share sets meet their thresholds, the proxy delivers the bundle to the destination TEE.
5. The destination TEE decrypts each share, reconstructs $S_\mathrm{dp}$ and $S_\mathrm{ka}$, and recovers $K = S_\mathrm{dp} + S_\mathrm{ka} \pmod N$.
6. The TEE returns an [action response](../Concepts/Actions.md#action-responses) indicating success or failure and, if any holders submitted invalid shares, names them.
7. The destination TEE produces a fresh [key existence proof](#tee-key-existence-proof) for the restored key.

The TEE proxy cannot tell whether a submitted share is valid until decryption; that is why step $6$ surfaces the bad-share list.
If too many shares were invalid, recovery fails and the action response reports it.

> **Note:** [Wallet key variables](#wallet-key-variables) (`nonce`, `pauseNonce`, `status`, `expiry`) are machine-local and are _not_ restored; they start fresh on the destination machine.
