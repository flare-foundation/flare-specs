# F_GET TEE_BACKUP

## Description

Returns the latest backup package for a specific key. This is a direct instruction triggered by the proxy and does not need to provide any signatures. It is triggered as soon as [KEY_INFO](F_GET--KEY_INFO.md) results are available, for every key obtained by KEY_INFO.

## Action message

```json
{
    "walletId": "bytes32 -- wallet id",
    "keyId": "uint64 -- key id"
}
```

## Fixed message

/

## Variable message

/

## Additional action data

/

## Action result

```go
type TEEBackupResponse struct {
    BackupID     WalletBackupID // backup id structure
    WalletBackup []byte         // JSON-encoded backup package containing the TEE signature
}
```

The TEE signature over the backup hash is embedded inside the `WalletBackup` bytes, not as a top-level field.

See [KEY_DATA_PROVIDER_RESTORE](F_WALLET--KEY_DATA_PROVIDER_RESTORE.md) for the `BackupId` struct definition.

## Notes

- **Proxy result hook:** Proxy stores backups per hash of backup ID and also stores a mapping from `(walletId, keyId)` to the latest backup ID hash.
