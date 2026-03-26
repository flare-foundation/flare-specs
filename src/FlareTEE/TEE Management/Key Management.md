# Key Management
In order to ensure consistent availability of the keys stored inside TEE machines, two systems are in place.
Firstly, TEEs provide *key existence* proofs to verify the existence of private keys.
Secondly, in case of any unexpected issues with the TEE machines, a key backup process is in place to restore lost keys.
This page describes these processes.
Related content on the data structures surrounding keys can be found [here](../Operations/Projects and Ownership.md).

## Wallet Private Key Data Structure
Each private key on a TEE machine is described by the following data structure:

- `walletId`: Wallet ID of the key.
- `keyId`: Key ID within the wallet.
- `signingAlgo`: The [signing algorithm](#signing-algorithms) for the key.
- `keyType`: The [key type](#key-type).
- `privateKey`: The private key.
- `restored`: A flag indicating whether the key was generated (`false`) or restored through backup restore (`true`).
- `configConstants`: Immutable wallet config settings, including:
	- `adminsPublicKeys`: A list of public keys used for encrypting Shamir secret shares for backup and for multisig confirmation of changes in config settings.
	- `adminsThreshold`: Threshold for operations with `adminsPublicKeys`.
	- `cosigners`: An (optional) list of cosigner addresses. If set, provides additional multisig confirmation needed to execute instructions.
	- `cosignersThreshold`: The (optional) threshold for cosigning.

All fields except `configConstants` are set at key generation. The `configConstants` are set separately as part of wallet configuration.

### Signing Algorithms
Three signing algorithms are supported, each identified by a `bytes32` hash of the algorithm string:

1. `keccak256-secp256k1-ecdsa`: ECDSA signing for EVM-compatible chains.
2. `sha512half-secp256k1-ecdsa`: ECDSA signing for XRP Ledger transactions.
3. `keccak256-secp256k1-vrf`: Signing for VRF proof generation (see [VRF Keys](#vrf-keys)).

### Key Types
Two key types are supported:

1. `EVM`: Keys intended for EVM-compatible signing operations.
2. `XRP`: Keys intended for XRP Ledger signing operations.

### Wallet Key Variables
On a TEE machine there is a persistent mapping of wallet key variables for every key that has ever existed on the machine.
Even if the key is deleted, the variable values are retained. The mapping is:

$$(\text{walletId}, \text{keyId}) \Rightarrow (\text{nonce}, \text{pauseNonce}, \text{status}, \text{expiry})$$

Where the fields represent:

- `nonce`: The key nonce, used for replay protection in state-changing operations such as `KEY_DELETE`.
- `pauseNonce`: A randomly generated nonce reserved for future `PAUSE` and `RESUME` operations.
- `status`: The key status (e.g. `active`, `paused`).
- `expiry`: The expiry time of the key. After the expiry time is reached, the key is automatically deleted from the machine.

> **Note:** When key data is backed up, the `configConstants` and wallet key variables are excluded.
## TEE Key Existence Proof
Upon generation of a key for, the TEE machine also generates and returns a *key existence proof*.
A key existence proof is a data structure containing the key and relevant meta data and signed by the TEE that holds the key.
The TEE machine sends the proof to its TEE proxy, from which the proof can be fetched and submitted on Flare.
The purpose of the proof is to verify that the key exists within the machine's memory.
To this end, fresh proofs are periodically requested by the TEE proxy to ensure that the key has not been lost. 

### Key Existence Proof Data Structure
The format of the proof is a signed `TeeKeyExistence` solidity struct signed by the TEE's public identity.
The format of the solidity struct is

``` Solidity
struct KeyExistence {
address teeId;
bytes32 walletId;
uint64 keyId;
bytes32 keyType;
bytes32 signingAlgo;
bytes publicKey;
uint256 nonce;
bool restored;
KeyConfigConstants configConstants;
bytes32 settingsVersion;
bytes settings;
}
```
where `nonce` is a fresh nonce, `restored` is set to True if the key was restored on to the TEE machine (and otherwise false) ,`configConstants` describes configuration of the private key data structure, and the final two fields describe configurations of the TEEs settings.
The rest of the fields are defined by the [project](../Operations/Projects and Ownership.md) on which the key is active, and identify properties of the wallet and key.

## VRF Keys
In addition to standard ECDSA signing keys, a TEE machine can hold *VRF keys*, used for verifiable random number generation.
VRF keys use the `keccak256-secp256k1-vrf` signing algorithm and are generated and managed through the same `KEY_GENERATE` and `KEY_DELETE` instructions as other wallet keys.

### VRF Proof Generation
The `VRF` command under `op.Wallet` generates a verifiable randomness proof. The instruction takes as input:

1. `walletId` (`bytes32`): The wallet ID of the VRF key.
2. `keyId` (`uint64`): The key ID within the wallet.
3. `nonce` (`bytes`): An arbitrary nonce binding the proof to a specific request.

On receiving the input, the TEE loads the private key, verifies that its signing algorithm is `keccak256-secp256k1-vrf`, and computes a VRF proof `proof` using the [ECVRF scheme](https://eprint.iacr.org/2017/099).

### VRF Proof Structure
The proof output `proof` consists of the following fields:

- `gamma`: A curve point $(\gamma_x, \gamma_y)$, the VRF output.
- `c`: The challenge scalar.
- `s`: The response scalar.
- `u`: Witness point $c \cdot \mathrm{pk} + s \cdot G$.
- `cGamma`: Witness point $c \cdot \gamma$.
- `v`: Witness point $c \cdot \gamma + s \cdot H$.
- `zInv`: Field element $(\mathrm{cGamma}_x - v_x)^{-1} \mod P$.

The witness points (`u`, `cGamma`, `v`, `zInv`) are pre-computed off-chain to avoid expensive secp256k1 scalar multiplications in the EVM. 
The on-chain `TeeVRFVerifier` contract verifies the proof using `ecrecover`.

### Randomness Extraction
The final random value is derived as $\mathrm{keccak256}(\gamma_x \| \gamma_y)$, where $\gamma_x$ and $\gamma_y$ are $32$-byte big-endian encodings of the gamma point coordinates.

## Key Backup
TEE machines backup keys that they generate for signing and other operations.
Whenever a new key is generated, the TEE machine triggers a back up process for the key.
Similarly, whenever a new signing policy is relayed to it, the TEE machine triggers a new backup process for each key it stores in its memory.

### Backup Overview
The backup process for a secret key $K$ is triggered when the key is generated or the signing policy is updated at the TEE machine that holds the key.
It consists of two rounds of secret sharing: first, a data provider share $S_\mathrm{dp}$ and a key admin share $S_\mathrm{ka}$ are generated at random using modulo addition. These two shares are then each split a second time using Shamir Secret Sharing schemes.

The data provider share $S_\mathrm{dp}$ is split with each provider receiving a proportion of the shares matching their weight, so that a sufficient weight of data providers can recover the key.
The key admin share $S_\mathrm{dp}$ is split with each admin receiving a single share, such that the amount of admins required to recover the key corresponds to a parameter set by the owner of the wallet.

To recover a key, a key recovery TEE is designated.
The providers and admins send their shares to the TEE, which recovers both the data provider and the key admin shares, and then the original key.
The details are given below.

### Backup Data and Metadata
Data providers and key admins typically store several key backups for different keys. 
Each key backup is identified by three objects: the *backup metadata*, the *backup ID*, and the *backup hash*.
These store information regarding the key itself and the TEE machine on which the key is stored. 

The backup metadata consists of the following fields:

- `teeId`: The unique identity of the TEE machine which stores the original key.
- `walletId`: The wallet ID of the wallet that the key is registered on.
- `keyId`: The key ID of the key.
- `signingAlgo`: The hashing and signing algorithm of the key.
-  `keyType`: The key type of the private key. 
- `rewardEpochId`: The ID of the signing policy on which the key was backed up, defining which data providers store backup shares.
- `publicKey`: The public key of the backed up private key.
- `providersThreshold`: The threshold weight required for recovering the data providers' share of the key. This defaults to $666/1000$ (approximately $66\%$).
- `adminsPublicKeys`: The list of admin public keys.
- `adminsThreshold`: The threshold for operations with the admin public keys.
- `cosigners`: The list of cosigner addresses for the key, if included.
- `cosignersThreshold`: The threshold for cosigning.
- `randomNonce`: A random nonce generated by the TEE machine at the time of backup creation.

The backup ID is defined from a set of fields from the backup metadata, specifically:

```Solidity
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

The backup hash is then defined as $\mathrm{hash}(\mathrm{backupID})$, where the backup ID is ABI encoded to compute the hash.

### Backup Procedure
The backup procedure for a key $K$ on a project $P$ stored on a TEE with identity $\mathrm{TEE}_\mathrm{id}$ is triggered in two cases:
- When $K$ is generated by the TEE.
- When the signing policy at $\mathrm{TEE}_\mathrm{id}$ is updated. 

Alongside the key that is being backed up, the backup process triggered by $\mathrm{TEE}_\mathrm{id}$ takes as input:

- All fields used in the backup metadata.
- The signing policy on which the key is to be backed up. This is the current signing policy at the TEE when the key is generated or the new signing policy if the backup is triggered by an update.

To backup a key $K$, the TEE machine performs the following  procedure:

1. A random split of into two shares $K$ is performed by modulo arithmetic, giving shares $S_\mathrm{dp}$ and $S_\mathrm{ka}$, the data provider and key admin shares of the secret. The shares are chosen uniformly at random such that $K = S_\mathrm{dp} + S_\mathrm{ka} \mod N$.
2. The data provider share $S_\mathrm{dp}$ is split into $1000$ shares using a $(1000, \lfloor \mathrm{providersThreshold} \cdot 1000 \rfloor)$-Shamir secret sharing scheme into shares ${S_\mathrm{dp}}^1, \dots, {S_\mathrm{dp}}^{1000}$. Each data provider is then assigned a proportion of these shares relative to its weight in the signing policy, rounded down, such that the $j$th data provider with weight $W_j$ is assigned $\lfloor W_j \cdot 1000 \rfloor$ shares of the secret.
3. Similarly, the key admin share $S_\mathrm{ka}$ is split shares $${S_\mathrm{ka}}^1, \dots, {S_\mathrm{ka}}^{N_\text{admin}}$ equal to the number of key admins using an $(N_{\text{admin}}, \mathrm{adminsThreshold})$-Shamir secret sharing scheme. The $i$th admin is assigned a share ${S_\mathrm{ka}}^i$.
4. For the each data provider and key admin, a package $\mathrm{pack}_i$ is prepared containing share data and relevant meta data. This package is then encrypted under the receiving entities public key $\mathrm{pk}_i$. Formally, the package contains:
	 - `shareData`: The share or shares for the recipient $i$.
	 - `backupID`: The ID of the backup.
	 - `holdersPublicKey`: The public key of the entity receiving the share.
	 - `signature`: The signature of the above with the private key that is being backed up.
5. Each encrypted package is combined with the recipients public key into a *holder backup package*, $\mathrm{Backup}_i = (\text{Enc}_{\mathrm{pk}_i}(\mathrm{pack}_i), \mathrm{pk}_i)$.
6. All holder backup packages and the backup metadata are combined into a single package, also containing two signatures: one performed by the key being backed up and one by the TEE's identity key into a single *backup package* [check this again later once finalized]:
	- `holderBackupPackages`
	- `backupMetadata`
	- `signature`
	- `TeeSignature`
7. The backup package is distributed to the TEE proxy, from which it can be retrieved by the recipients.

### Key Restoration Procedure
The key restoration process is triggered when any Flare user calls the `backupRestore` function on the `TeeWalletBackupManager`, whose parameters are:

- `backupID`: The ID of backup of the key to be restored.
- `backupURL`: The URL on which the backup package is hosted. If no such URL exists, the restoring user fetches the backup package from the TEE proxy and uploads it to the URL.
- `teeID`: The ID of the machine on which the key is to be restored on. Note that this is not the same as the TEE that backed up the key.
- `randomNonce`: The nonce used in the backup procedure.

The restore function then works as follows:

1. Each data provider and key admin who holds a backup package for the backup ID extracts its holder backup package.
2. They each decrypt their key share found in their backup package $\mathrm{Backup}_i$ to recover their key share(s). For example, the $j$th key admin recovers the share ${S_\mathrm{ka}}^j$.
3. Next, the key share is encrypted under the public key corresponding to TEE ID of the TEE machine on which the key is being restored, e.g. computing $\mathrm{Enc}_{\mathrm{TEE}_\mathrm{id}}({S_\mathrm{ka}}^j)$.
4. Once their encryption is prepared, they send an [instruction](../Operations/Instructions.md) to the relevant TEE proxy containing the backup metadata as the `additionalFixedMessage` and the encrypted share as the `additionalVariableMessage`.
The corresponding relay behavior is summarized in [Relay Client](../Relay Client.md#key-restoration).
5. The TEE proxy sets the `submissionTag` field in the action structure to `end`, keeping voting open for the maximal possible duration. At the end of voting, assuming it received enough shares from both data providers and key admins such that key recovery is possible, it prepares the recovery action and submits the encrypted shares to the TEE machine.
6. The TEE machine completes the action, decrypting all key shares, recovering shares of the initial split $S_\mathrm{dp}$ and $S_\mathrm{ka}$, from which it recovers $K$.
7. Once the action is complete, the TEE machine returns an action response to the TEE proxy, indicating the success (or not) of the recovery process. Additionally, the machine returns a list of entities who returned invalid key shares, if any.
8. The key can now be confirmed using a `TeeKeyExistence` proof.

Note that in steps 4 and 5 the TEE proxy has no way of knowing whether or not the data providers and key admins provided valid key shares or not; hence the action response includes this list.
If too many key shares were invalid, key recovery will fail, which is also included in the action response. 

> **Note:** The [wallet key variables](#wallet-key-variables) (`nonce`, `pauseNonce`, `status`, `expiry`) are not included in the backup and are not restored. These values are managed independently on each TEE machine.

## Key and Backup Manager Contracts
Keys and backups are managed by users through two contracts: the `TeeWalletKeyManager` contract and the `TeeWalletBackupManager` contract.
This section lists the available contract calls.

### TeeWalletKeyManager Contract Calls
Unless otherwise specified, calls to the wallet key manager contrat are only valid if made by the owner of the wallet. The calls include:

- `addKey(walletId, teeId)`:  Creates a [key definition](../Operations/Projects and Ownership.md) structure with the next sequential key ID for the wallet ID and issues the `KEY_GENERATE` instruction.
- `confirmKey(proof)`: Confirms the existence of a key on a given TEE based on an input `TeeKeyExistence` proof. 
-  `deleteKey(teeId, walletId, keyId)`: Deletes the specified key from the specified TEE machine by triggering the `KEY_DELETE` instruction. 
- `cleanUpTeeIds(walletId, keyId)`: Removes TEE IDs from the key definition of the specified key. 
- `receivingTeesAndKeys(walletId)`: Returns a list of TEE machine IDs and URLs to which wallet instructions should be sent and also pairs of TEE IDs and key IDs that will be used in signing. If there are less than the usual $n$ signatures available from TEEs (due to a machine being down), a notification is returned. Similarly, if the required $k$ value for the multisig of the wallet cannot be achieved, the transaction reverts. 

Triggered instructions are sent by the wallet manager contract to the instruction contract.
They are parameterized by:

-   `KEY_GENERATE(teeId, walletId, keyId, opType, opTypeConstants, adminsPublicKeys, adminsThreshold, cosigners, cosignersThreshold)`   
-   `KEY_DELETE(teeId, walletId, keyId)`.

### TeeWalletBackupManager Contract Calls
Since backups are triggered automatically, the `TeeWalletBackupManager` contract only has a single call:

- `backupRestore(teeId, backupId, backupUrl)`: Triggers the KEY_DATA_PROVIDER_RESTORE instruction, restoring the key backed up by backup ID on the TEE with the specified machine ID.

With the corresponding instruction sent as:

- `KEY_DATA_PROVIDER_RESTORE(teeId, backupId, backupUrl, nonce)`.
