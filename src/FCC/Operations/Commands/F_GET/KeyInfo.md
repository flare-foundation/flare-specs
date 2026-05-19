# F_GET KEY_INFO

## Description

Returns signed `KeyExistence` proofs for all keys stored on the TEE machine. This is a direct action triggered by the proxy and does not need to provide any signatures.

## Action message

Empty.

## Fixed message

/

## Variable message

/

## Additional action data

/

## Action result

The result is returned as a list of signed `KeyExistence` proofs:

- `keyExistence` -- ABI encoded `KeyExistence` (see [KEY_GENERATE](../F_WALLET/KeyGenerate.md) for struct definition)
- `signature` -- ECDSA signature of the `keyExistence` hash by the TEE machine's identity key

## Notes

- **Proxy result hook:** The proxy loops through the result and pushes the `KeyExistence` proofs with signatures to the key data store. For each key, the backup ID is calculated and checked whether the backup is already in the backup store. If not, a [TEE_BACKUP](TeeBackup.md) action is triggered.
