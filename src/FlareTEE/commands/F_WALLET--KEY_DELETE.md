# F_WALLET KEY_DELETE

## Description

Deletes the key from the machine state, if present.

Any key that was ever in the machine state holds a nonce record. An action is valid if the nonce record for the key is present and is strictly lower than the action's nonce. A valid action deletes the key from the state, if present, and updates the nonce record. If the key is not present, only the nonce record is updated and the action result includes an `additionalResultStatus` of `"key not stored"`.

Note that on the TEE machine the nonce related to `(walletId, keyId)` is kept and reused if later the same key gets restored to the TEE machine (or its upgrade).

## Event message

```solidity
// Source: ITeeWalletKeyManager.sol
struct KeyDelete {
    address teeId;    // TEE machine id where the key should be deleted
    bytes32 walletId; // wallet id of the key to be deleted
    uint64 keyId;     // key id of the key to be deleted
    uint256 nonce;    // nonce for (walletId, keyId); must be higher than the one on the TEE machine
}
```

## Fixed message

/

## Variable message

/

## Additional action data

/

## Action result

Marshalled key ID pair:

```go
// Source: tee-node/pkg/wallets/wallets.go
type KeyIDPair struct {
    WalletID common.Hash `json:"walletId"` // wallet id
    KeyID    uint64      `json:"keyId"`    // key id
}
```

The result contains the `walletId` and `keyId` of the deleted key.

## Notes

On the `End` submission tag, the TEE verifies that the deletion was processed and the nonce was consumed, ensuring consistency between the threshold and end-of-voting results.
