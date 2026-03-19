# F_WALLET KEY_DATA_PROVIDER_RESTORE_TEST

> **Not implemented.** This command is defined as a valid operation pair in `op.go` but has no registered processor in the TEE node. The `wallet/wallet.go` initialization code contains a TODO comment for this command. The description below reflects the *intended* behavior.

## Description

Enables testing of restoration of a key using a backup package. It simultaneously restores the key, signs a custom message, returns a result, and deletes the key. It has the same parameters as [KEY_DATA_PROVIDER_RESTORE](F_WALLET--KEY_DATA_PROVIDER_RESTORE.md). The key signs the `instructionId`. Then both are hashed and signed by the TEE ID key.

## Event message

Same as [KEY_DATA_PROVIDER_RESTORE](F_WALLET--KEY_DATA_PROVIDER_RESTORE.md).

## Fixed message

Same as [KEY_DATA_PROVIDER_RESTORE](F_WALLET--KEY_DATA_PROVIDER_RESTORE.md).

## Variable message

Same as [KEY_DATA_PROVIDER_RESTORE](F_WALLET--KEY_DATA_PROVIDER_RESTORE.md).

## Additional action data

/

## Action result (intended)

- `instructionId` — instruction ID.
- `timestamp` — local timestamp on the TEE machine at the time just before signing.
- `keySignature` — signature by the restored key of `(instructionId, timestamp)`.
- `teeSignature` — signature by TEE ID key of `(instructionId, timestamp)`.
