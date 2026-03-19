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

## Action result

```go
// Source: tee-node/pkg/wallets/wallets.go
type TEEBackupResponse struct {
    BackupID     WalletBackupID `json:"backupId"`     // backup id structure
    WalletBackup []byte         `json:"walletBackup"` // binary encoded backup package (base64)
    TEESignature []byte         `json:"teeSignature"` // TEE signature over the backup hash
}
```

The `TEESignature` field contains a signature by the TEE's identity key over the hash of the backup, providing authenticity verification for the backup package.

See [KEY_DATA_PROVIDER_RESTORE](F_WALLET--KEY_DATA_PROVIDER_RESTORE.md) for the `BackupId` struct definition.

**Proxy result hook:** Proxy stores backups per hash of backup ID and also stores a mapping from `(walletId, keyId)` to the latest backup ID hash.
