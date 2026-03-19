# F_GET TEE_BACKUP

## Description

Returns the latest backup package. This is a direct instruction triggered by the proxy and does not need to provide any signatures. It is triggered as soon as [KEY_INFO](F_GET--KEY_INFO.md) results are available, for every key obtained by KEY_INFO.

## Action message

```json
{
    "walletId": "bytes32 -- wallet id",
    "keyId": "uint64 -- key id"
}
```

## Action result

- `backupId` -- backup id structure (see [KEY_DATA_PROVIDER_RESTORE](F_WALLET--KEY_DATA_PROVIDER_RESTORE.md) for `BackupId` struct definition)
- `package` -- binary encoded package (base64)

**Proxy result hook:** Proxy stores backups per hash of backup id and also stores backup id per `(walletId, keyId)` pair.
