# F_GET KEY_PROOF

[Direct action](../../Actions.md#direct-actions) issued by the [TEE proxy](../../../Components/TeeProxy.md) to fetch signed key-existence proofs for a list of `(walletId, keyId)` pairs.
Returns one proof per requested pair, in the same order as the request.

## Action message

A JSON array of [`KeyIDPair`](../../../Types/Wire/Key.md#keyidpair).

## Action result

A JSON array of [`SignedKeyExistenceProof`](../../../Types/Wire/Key.md#signedkeyexistenceproof), in the same order as the request.
