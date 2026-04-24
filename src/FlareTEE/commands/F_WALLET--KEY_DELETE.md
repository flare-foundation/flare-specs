# F_WALLET KEY_DELETE

## Description

Deletes the key from the machine state, if present.

Any key that was ever in the machine state holds a nonce record. An action is valid if the nonce record for the key is present and is strictly lower than the action's nonce. A valid action deletes the key from the state, if present, and updates the nonce record. If the key is not present, only the nonce record is updated and the action result includes an `additionalResultStatus` of `"key not stored"`.

Note that on the TEE machine the nonce related to `(walletId, keyId)` is kept and reused if later the same key gets restored to the TEE machine (or its upgrade).

## Event message

The event message is formatted as the [`KeyDelete`](../Types/Abi/Key.md#keydelete) struct.

## Fixed message

/

## Variable message

/

## Additional action data

/

## Action result

Marshalled [`KeyIDPair`](../Types/Wire/Key.md#keyidpair).

The result contains the `walletId` and `keyId` of the deleted key.

## Notes

- **End-of-voting verification:** On the `End` submission tag, the TEE verifies that the deletion was processed and the nonce was consumed, ensuring consistency between the threshold and end-of-voting results.
