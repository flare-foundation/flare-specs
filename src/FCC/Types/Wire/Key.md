# Key Wire Types

JSON types returned by TEE proxy APIs for key management operations.
For the corresponding ABI types used for on-chain encoding, see [Key (ABI)](../Abi/Key.md).

## KeyInfo

Single element of the [`KEY_INFO`](../../Operations/Commands/F_GET/KeyInfo.md) action result list.

```json
{
  "$id": "KeyInfo",
  "type": "object",
  "properties": {
    "walletId": { "type": "string", "format": "bytes32", "description": "Wallet ID." },
    "keyId": { "type": "integer", "format": "uint64", "description": "Key ID." },
    "nonce": { "type": "integer", "format": "uint64", "description": "Current replay-protection nonce for the (walletId, keyId) pair." }
  },
  "required": ["walletId", "keyId", "nonce"]
}
```

## SignedKeyExistenceProof

Returned by `GET /wallet/<walletId>/<keyId>`, by the [`KEY_PROOF`](../../Operations/Commands/F_GET/KeyProof.md) action (as a list), and by the [`KEY_GENERATE`](../../Operations/Commands/F_WALLET/KeyGenerate.md) and [`KEY_DATA_PROVIDER_RESTORE`](../../Operations/Commands/F_WALLET/KeyDataProviderRestore.md) instruction action results.
Wraps an ABI-encoded [`KeyExistence`](../Abi/Key.md#keyexistence) struct with a TEE identity signature.


```json
{
  "$id": "SignedKeyExistenceProof",
  "type": "object",
  "properties": {
    "keyExistence": { "type": "string", "format": "bytes", "description": "ABI-encoded KeyExistence struct." },
    "signature": { "type": "string", "format": "bytes", "description": "TEE identity signature over keccak256(keyExistence)." }
  },
  "required": ["keyExistence", "signature"]
}
```

To decode the `keyExistence` field, ABI-decode using the [`KeyExistence`](../Abi/Key.md#keyexistence) struct definition.

The proxy also exposes a decoded view of the key data alongside the raw proof.
The decoded fields use the following JSON representation:

```json
{
  "$id": "KeyData",
  "type": "object",
  "properties": {
    "info": {
      "type": "object",
      "properties": {
        "teeId": { "type": "string", "format": "address", "description": "TEE machine ID." },
        "walletId": { "type": "string", "format": "bytes32", "description": "Wallet ID." },
        "keyId": { "type": "integer", "format": "uint64", "description": "Key ID." },
        "keyType": { "type": "string", "format": "bytes32", "description": "Key type." },
        "signingAlgo": { "type": "string", "format": "bytes32", "description": "Signing algorithm." },
        "publicKey": { "type": "string", "format": "bytes", "description": "Generated public key." },
        "nonce": { "type": "string", "format": "uint256", "description": "Key nonce." },
        "restore": { "type": "boolean", "description": "True if the key was restored from backup." },
        "configConstants": { "$ref": "../Abi/Key.md#keyconfigconstants" },
        "settingsVersion": { "type": "string", "format": "bytes32", "description": "Settings version hash." },
        "settings": { "type": "string", "format": "bytes", "description": "Encoded settings." }
      }
    },
    "proof": { "$ref": "#signedkeyexistenceproof" }
  },
  "required": ["info", "proof"]
}
```

> **Note:** The `info.restore` field corresponds to the `restored` field in the ABI type.

## KeyIDPair

Returned in the action result of a [`KEY_DELETE`](../../Operations/Commands/F_WALLET/KeyDelete.md) command.


```json
{
  "$id": "KeyIDPair",
  "type": "object",
  "properties": {
    "walletId": { "type": "string", "format": "bytes32", "description": "Wallet ID." },
    "keyId": { "type": "integer", "format": "uint64", "description": "Key ID." }
  },
  "required": ["walletId", "keyId"]
}
```

## TeeBackupRequest

Direct action message for the [`TEE_BACKUP`](../../Operations/Commands/F_GET/TeeBackup.md) command.
Same shape as [`KeyIDPair`](#keyidpair).

```json
{
  "$id": "TeeBackupRequest",
  "type": "object",
  "properties": {
    "walletId": { "type": "string", "format": "bytes32", "description": "Wallet ID of the key to back up." },
    "keyId": { "type": "integer", "format": "uint64", "description": "Key ID of the key to back up." }
  },
  "required": ["walletId", "keyId"]
}
```

## TeeBackupResponse

Action result for the [`TEE_BACKUP`](../../Operations/Commands/F_GET/TeeBackup.md) command.

```json
{
  "$id": "TeeBackupResponse",
  "type": "object",
  "properties": {
    "BackupID": { "$ref": "#walletbackupid", "description": "Identifier of the produced backup." },
    "WalletBackup": { "type": "string", "format": "bytes", "description": "JSON-encoded backup package, with the TEE signature over the backup hash embedded inside (not exposed as a top-level field)." }
  },
  "required": ["BackupID", "WalletBackup"]
}
```

## WalletBackupID

Identifies a key backup in TEE proxy backup API responses (`GET /backup/<backupIdHash>` and `GET /backup/<walletId>/<keyId>`).
Contains the same logical fields as the [`BackupId`](../Abi/Key.md#backupid) ABI type.


```json
{
  "$id": "WalletBackupID",
  "type": "object",
  "properties": {
    "teeId": { "type": "string", "format": "address", "description": "Identity of the TEE machine that backed up the key." },
    "walletId": { "type": "string", "format": "bytes32", "description": "Wallet ID." },
    "keyId": { "type": "integer", "format": "uint64", "description": "Key ID." },
    "publicKey": { "type": "string", "format": "bytes", "description": "Public key of the backed-up key." },
    "keyType": { "type": "string", "format": "bytes32", "description": "Key type." },
    "signingAlgo": { "type": "string", "format": "bytes32", "description": "Signing algorithm." },
    "rewardEpochId": { "type": "integer", "format": "uint32", "description": "Reward epoch on which the backup was created." },
    "randomNonce": { "type": "string", "format": "bytes32", "description": "Random nonce generated by the TEE at backup time." }
  },
  "required": ["teeId", "walletId", "keyId", "publicKey", "keyType", "signingAlgo", "rewardEpochId", "randomNonce"]
}
```
