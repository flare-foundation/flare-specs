# Key Types

Types related to [key management](../../../Concepts/Keys.md) on TEE machines.

## KeyGenerate

Instruction message for generating a key on a TEE machine.


```json
{
  "$id": "KeyGenerate",
  "type": "object",
  "properties": {
    "teeId": { "type": "string", "format": "address", "description": "TEE machine on which the key should be generated." },
    "walletId": { "type": "string", "format": "bytes32", "description": "Wallet to which the key should be assigned." },
    "keyId": { "type": "integer", "format": "uint64", "description": "Key ID to be assigned." },
    "keyType": { "type": "string", "format": "bytes32", "description": "Key type (e.g., EVM, XRP)." },
    "signingAlgo": { "type": "string", "format": "bytes32", "description": "Hashing and signing algorithm." },
    "configConstants": { "$ref": "#keyconfigconstants" }
  },
  "required": ["teeId", "walletId", "keyId", "keyType", "signingAlgo", "configConstants"]
}
```

## KeyConfigConstants

Immutable wallet configuration constants, set at key generation and included in key backups.


```json
{
  "$id": "KeyConfigConstants",
  "type": "object",
  "properties": {
    "adminsPublicKeys": { "type": "array", "items": { "$ref": "Common.md#publickey" }, "description": "Admin public keys for backup encryption and multisig confirmation." },
    "adminsThreshold": { "type": "integer", "format": "uint64", "description": "Threshold of admin signatures required." },
    "cosigners": { "type": "array", "items": { "type": "string", "format": "address" }, "description": "Cosigner addresses." },
    "cosignersThreshold": { "type": "integer", "format": "uint64", "description": "Threshold of cosigner signatures required." }
  },
  "required": ["adminsPublicKeys", "adminsThreshold", "cosigners", "cosignersThreshold"]
}
```

## KeyExistence

Proof of key existence on a TEE machine, signed by the TEE's identity key.
This struct is ABI-encoded; over HTTP it is transmitted as an opaque byte string inside a [`SignedKeyExistenceProof`](../Wire/Key.md#signedkeyexistenceproof) wrapper.


```json
{
  "$id": "KeyExistence",
  "type": "object",
  "properties": {
    "teeId": { "type": "string", "format": "address", "description": "TEE machine ID." },
    "walletId": { "type": "string", "format": "bytes32", "description": "Wallet ID." },
    "keyId": { "type": "integer", "format": "uint64", "description": "Key ID." },
    "keyType": { "type": "string", "format": "bytes32", "description": "Key type." },
    "signingAlgo": { "type": "string", "format": "bytes32", "description": "Signing algorithm." },
    "publicKey": { "type": "string", "format": "bytes", "description": "Generated public key." },
    "nonce": { "type": "string", "format": "uint256", "description": "Key nonce." },
    "restored": { "type": "boolean", "description": "True if the key was restored from backup, false if freshly generated." },
    "configConstants": { "$ref": "#keyconfigconstants" },
    "settingsVersion": { "type": "string", "format": "bytes32", "description": "Settings version hash." },
    "settings": { "type": "string", "format": "bytes", "description": "Encoded settings." }
  },
  "required": ["teeId", "walletId", "keyId", "keyType", "signingAlgo", "publicKey", "nonce", "restored", "configConstants", "settingsVersion", "settings"]
}
```

## KeyDelete

Instruction message for deleting a key from a TEE machine.
The `nonce` must be strictly higher than the current nonce for the `(walletId, keyId)` pair on the machine.


```json
{
  "$id": "KeyDelete",
  "type": "object",
  "properties": {
    "teeId": { "type": "string", "format": "address", "description": "TEE machine on which the key should be deleted." },
    "walletId": { "type": "string", "format": "bytes32", "description": "Wallet ID of the key." },
    "keyId": { "type": "integer", "format": "uint64", "description": "Key ID of the key." },
    "nonce": { "type": "string", "format": "uint256", "description": "Nonce for replay protection; must exceed the current nonce on the machine." }
  },
  "required": ["teeId", "walletId", "keyId", "nonce"]
}
```

## BackupId

Identifies a key backup.
The backup hash is defined as $\mathrm{hash}(\mathrm{ABI.encode}(\mathrm{BackupId}))$.


```json
{
  "$id": "BackupId",
  "type": "object",
  "properties": {
    "teeId": { "type": "string", "format": "address", "description": "Identity of the TEE machine that backed up the key." },
    "walletId": { "type": "string", "format": "bytes32", "description": "Wallet ID." },
    "keyId": { "type": "integer", "format": "uint64", "description": "Key ID." },
    "keyType": { "type": "string", "format": "bytes32", "description": "Key type." },
    "signingAlgo": { "type": "string", "format": "bytes32", "description": "Signing algorithm." },
    "publicKey": { "type": "string", "format": "bytes", "description": "Public key of the backed-up key." },
    "rewardEpochId": { "type": "integer", "format": "uint32", "description": "Reward epoch on which the backup was created." },
    "randomNonce": { "type": "string", "format": "bytes32", "description": "Random nonce generated by the TEE at backup time." }
  },
  "required": ["teeId", "walletId", "keyId", "keyType", "signingAlgo", "publicKey", "rewardEpochId", "randomNonce"]
}
```

## KeyDataProviderRestore

Instruction message for restoring a previously backed-up key onto a target TEE machine.

```json
{
  "$id": "KeyDataProviderRestore",
  "type": "object",
  "properties": {
    "teePublicKey": { "$ref": "Common.md#publickey", "description": "Public key of the target TEE machine." },
    "backupId": { "$ref": "#backupid", "description": "Identifier of the backup to restore." },
    "backupUrl": { "type": "string", "description": "URL of the backup package." },
    "nonce": { "type": "string", "format": "uint256", "description": "Replay-protection nonce; must exceed any prior nonce stored for the (walletId, keyId) pair on the target machine." }
  },
  "required": ["teePublicKey", "backupId", "backupUrl", "nonce"]
}
```

## VrfInstructionMessage

Instruction message for generating a VRF proof.


```json
{
  "$id": "VrfInstructionMessage",
  "type": "object",
  "properties": {
    "walletId": { "type": "string", "format": "bytes32", "description": "Wallet ID of the VRF key." },
    "keyId": { "type": "integer", "format": "uint64", "description": "Key ID within the wallet." },
    "nonce": { "type": "string", "format": "bytes", "description": "Arbitrary nonce binding the proof to a specific request." }
  },
  "required": ["walletId", "keyId", "nonce"]
}
```
