# F_WALLET KEY_DATA_PROVIDER_RESTORE

## Description

Restores a previously backed-up key onto a target TEE machine. Data providers and wallet admins fetch the backup package, verify its consistency, and re-encrypt their shares with the target TEE's public key. The TEE machine reconstructs the private key from these shares and returns a signed `KeyExistence` proof.

Data providers and wallet admins fetch the backup package from the `backupUrl`. They check the consistency of the package and consistency with the `backupId`. They check registration and attestation of the machine with `teeId` (also verifying that the code version is not banned). If everything is valid, they extract their encrypted share package, decrypt it, and encrypt it with the public key of `teeId`.

## Event message

```solidity
// Source: ITeeWalletBackupManager.sol
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

// Source: IPublicKey.sol
struct PublicKey {
    bytes32 x; // x coordinate of the public key
    bytes32 y; // y coordinate of the public key
}
```

## Fixed message

- `backupMetadata` -- metadata obtained from backup package, if it matches `backupId`

## Variable message

- `encryptedShare` -- encrypted share with metadata

## Additional action data

/

## Action result

- `keyExistence` -- ABI encoded `KeyExistence` (see [KEY_GENERATE](F_WALLET--KEY_GENERATE.md) for struct definition)
- `signature` -- ECDSA signature of the `keyExistence` hash by the TEE machine's identity key (see [KEY_GENERATE](F_WALLET--KEY_GENERATE.md) for `Signature` struct)
