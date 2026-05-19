# F_WALLET KEY_DATA_PROVIDER_RESTORE

## Description

Restores a previously backed-up key onto a target TEE machine.
[Data providers](../../../../Terminology/Roles.md#data-provider) and [key admins](../../../../Terminology/Roles.md#key-admin) fetch the backup package, verify its consistency, and re-encrypt their shares with the target TEE's public key (see [Augmentation procedure](#augmentation-procedure) for the relay-client steps).
The TEE machine reconstructs the private key from these shares and returns a signed `KeyExistence` proof.

## Event message

```solidity
struct KeyDataProviderRestore {
    PublicKey teePublicKey; // public key of the target TEE machine
    BackupId backupId;      // backup identification data
    string backupUrl;       // URL of the backup package
    uint256 nonce;          // nonce for key operation
}

struct BackupId {
    address teeId;        // TEE machine id of the original key holder
    bytes32 walletId;     // wallet id
    uint64 keyId;         // key id
    bytes32 keyType;      // key type of the wallet
    bytes32 signingAlgo;  // hashing and signing algorithm of the key
    bytes publicKey;      // public key of the private key being backed up
    uint32 rewardEpochId; // signing policy used in the backup
    bytes32 randomNonce;  // random nonce for uniqueness
}

struct PublicKey {
    bytes32 x; // x coordinate of the public key
    bytes32 y; // y coordinate of the public key
}
```

## Fixed message

- `backupMetadata` -- metadata obtained from backup package, if it matches `backupId`

## Variable message

- `encryptedShare` -- encrypted share with metadata

## Augmentation procedure

During the [backup procedure](../../../TeeManagement/Keys.md#backup-procedure), each data provider and key admin receives a _holder backup package_ — their [Shamir secret share](../../../TeeManagement/Keys.md#backup-procedure) of the backed-up private key, encrypted under the holder's public key using ECIES.

Before signing the instruction, the [relay client](../../../Components/RelayClient.md) re-encrypts its share for the target TEE machine:

1. Fetch the backup package from `backupUrl` in the instruction.
   The package is subject to a size limit; if the response exceeds it or the server returns an error, the instruction is dropped.
2. Validate that the package metadata matches all [`BackupId`](../../../Types/Abi/Key.md#backupid) fields. If any field does not match, the instruction is dropped.
3. Verify that the target TEE machine (identified by `teeId`) is registered and currently attested, and that its code version is not banned.
4. Extract the holder backup package(s) corresponding to the relay client's public key.
   The key may be registered in the data provider pool, the key admin pool, or both; if it is in both, both packages are extracted.
   If it is in neither, the instruction is dropped.
5. Decrypt each extracted share using the relay client's private key.
6. Re-encrypt the share(s) under the target TEE machine's public key ([`TeePublicKey`](../../../Types/Abi/Common.md#publickey) in the instruction) using ECIES.
   If step 4 produced two shares (the both-pools case), they are bundled into a single ciphertext.
7. Place the [backup metadata](../../../TeeManagement/Keys.md#backup-data-and-metadata) into `additionalFixedMessage`.
8. Place the ECIES ciphertext into `additionalVariableMessage`.

See [key restoration procedure](../../../TeeManagement/Keys.md#key-restoration-procedure) for the full process including TEE-side recovery.

## Additional action data

/

## Action result

- `keyExistence` -- ABI encoded `KeyExistence` (see [KEY_GENERATE](KeyGenerate.md) for struct definition)
- `signature` -- ECDSA signature of the `keyExistence` hash by the TEE machine's identity key (see [KEY_GENERATE](KeyGenerate.md) for `Signature` struct)
