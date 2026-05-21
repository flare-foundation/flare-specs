# F_WALLET KEY_DELETE

[Instruction action](../../Actions.md#instruction-actions) that deletes a key from the TEE machine's wallet store, if present.

Every key that was ever stored on the machine retains a nonce record that survives deletion.
A delete is valid if the nonce record exists and is strictly lower than the instruction's `nonce`; on success the key is removed (if present) and the nonce record is bumped to the instruction's `nonce`.
If the key is no longer present but the nonce check passes, the action result carries an `additionalResultStatus` of `"key not stored"`.

The retained nonce is reused if the same `(walletId, keyId)` is later restored via [`KEY_DATA_PROVIDER_RESTORE`](KeyDataProviderRestore.md).

## Event message

[`KeyDelete`](../../../Types/Abi/Key.md#keydelete).

## Action result

JSON-encoded [`KeyIDPair`](../../../Types/Wire/Key.md#keyidpair) with the `(walletId, keyId)` of the deleted key.

## Validation

- A nonce record must already exist for `(walletId, keyId)` (the key must have been previously generated or restored on this machine).
- `nonce` must be strictly greater than the stored nonce.

## Notes

- On the `end` submission tag the machine re-checks that the key is gone and that its nonce record has been consumed, ensuring the `threshold` and `end` views agree.
