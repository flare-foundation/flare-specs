# F_GET KEY_INFO

[Direct action](../../Actions.md#direct-actions) issued by the [TEE proxy](../../../Components/TeeProxy.md) to enumerate the keys stored on the TEE machine.
Returns one [`KeyInfo`](../../../Types/Wire/Key.md#keyinfo) entry per stored key.

The proxy issues it periodically (every $\sim 60$ minutes) to drive the [key data store](../../../Components/TeeProxy.md#in-memory-stores) sync; each refresh follows up with [`KEY_PROOF`](KeyProof.md) for any pair whose nonce changed.

## Action message

Empty.

## Action result

A JSON array of [`KeyInfo`](../../../Types/Wire/Key.md#keyinfo).
