# F_GET TEE_BACKUP

[Direct action](../../Actions.md#direct-actions) issued by the [TEE proxy](../../../Components/TeeProxy.md) to obtain a fresh backup of one stored key.
The TEE machine constructs the backup from current state and the active [signing policy](../../../../FSP/SigningPolicy.md), signs it with its identity key, and returns it.

The proxy schedules `TEE_BACKUP` via its [result hooks](../../../Components/TeeProxy.md#result-hooks) — once per new key and once per stored key after each successful [`UPDATE_POLICY`](../F_POLICY/UpdatePolicy.md), to bind backups to the active signing policy's signer set and weights.

## Action message

[`TeeBackupRequest`](../../../Types/Wire/Key.md#teebackuprequest).

## Action result

[`TeeBackupResponse`](../../../Types/Wire/Key.md#teebackupresponse).

See [Key backup](../../../TeeManagement/Keys.md#backup-procedure) for the cryptographic construction of the backup package.
