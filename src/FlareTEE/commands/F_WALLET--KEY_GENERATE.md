# F_WALLET KEY_GENERATE

## Description

Triggers generation of a key on a TEE machine. Smart contracts ensure that an instruction for the combination of `(walletId, keyId)` appears in one instruction only.

## Event message

```solidity
// Source: ITeeWalletKeyManager.sol
struct KeyGenerate {
    address teeId;                     // TEE machine id where the key should be generated
    bytes32 walletId;                  // wallet id to which the key should be assigned
    uint64 keyId;                      // key id to be assigned to the key
    bytes32 keyType;                   // key type of the wallet
    bytes32 signingAlgo;               // hashing and signing algorithm of the key
    KeyConfigConstants configConstants; // key configuration constants
}

struct KeyConfigConstants {
    PublicKey[] adminsPublicKeys;  // admin public keys for the wallet
    uint64 adminsThreshold;       // threshold of admin signatures required
    address[] cosigners;          // cosigner addresses
    uint64 cosignersThreshold;    // threshold of cosigner signatures required
}

// Source: IPublicKey.sol
struct PublicKey {
    bytes32 x; // x coordinate of the public key
    bytes32 y; // y coordinate of the public key
}
```

## Fixed message

/

## Variable message

/

## Additional action data

/

## Action result

- `keyExistence` -- ABI encoded `KeyExistence`:

```solidity
// Source: ITeeWalletKeyManager.sol
struct KeyExistence {
    address teeId;                     // TEE machine id
    bytes32 walletId;                  // wallet id
    uint64 keyId;                      // key id
    bytes32 keyType;                   // key type
    bytes32 signingAlgo;               // signing algorithm
    bytes publicKey;                   // generated public key
    uint256 nonce;                     // key nonce
    bool restored;                     // false for freshly generated keys
    KeyConfigConstants configConstants; // key configuration constants
    bytes32 settingsVersion;           // settings version hash
    bytes settings;                    // encoded settings
}
```

- `signature` -- ECDSA signature of the `keyExistence` hash by the TEE machine's identity key:

```solidity
// Source: ISignature.sol
struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}
```

## Notes

- **Validation:** The TEE machine performs the following checks before generating a key:
  - The `teeId` in the instruction must match the machine's own identity.
  - The `adminsPublicKeys` list must be non-empty.
  - The `adminsThreshold` must be non-zero and not exceed the number of admins.
  - The `cosignersThreshold` must not exceed the number of cosigners.
  - The `signingAlgo` must be a supported algorithm (`keccak256-secp256k1-ecdsa`, `sha512half-secp256k1-ecdsa`, or `keccak256-secp256k1-vrf`).
  - The `(walletId, keyId)` pair must not already have a permanent record on the machine (prevents duplicate generation).
- **Signature format:** The `signature` field in the action result is the raw ECDSA signature bytes. Smart contracts decompose this into the `(v, r, s)` components of the `Signature` struct for on-chain verification.
- **Security considerations:** If data providers are malicious (50%+ attack), they can sign anything and send to any machine multiple times, which would result in generating different keys. From the smart contracts point of view, the first public key that gets confirmed (TeeKeyExistence attestation) on a key definition defines the validity of a key. Once a public key is set on a key definition, it cannot be changed.
