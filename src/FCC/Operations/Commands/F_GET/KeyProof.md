# F_GET KEY_PROOF

[Direct action](../../Actions.md#direct-actions) issued by the [TEE proxy](../../../Components/TeeProxy.md) to fetch signed key-existence proofs for a list of `(walletId, keyId)` pairs.
Returns one proof per requested pair, in the same order as the request.

Issued during the proxy's periodic [`KEY_INFO`](KeyInfo.md) sync, batched for pairs whose nonce changed since the last sync.

## Action message

A JSON array of [`KeyIDPair`](../../../Types/Wire/Key.md#keyidpair).

## Action result

A JSON array of [`SignedKeyExistenceProof`](../../../Types/Wire/Key.md#signedkeyexistenceproof), in the same order as the request.

## Validation

The TEE machine rejects the request if any requested `(walletId, keyId)` is not currently stored on the machine.
