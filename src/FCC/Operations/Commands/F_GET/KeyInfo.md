# F_GET KEY_INFO

[Direct action](../../Actions.md#direct-actions) issued by the [TEE proxy](../../../Components/TeeProxy.md) to enumerate the keys stored on the TEE machine.
Returns one [`KeyInfo`](../../../Types/Wire/Key.md#keyinfo) entry per stored key.

## Action message

Empty.

## Action result

A JSON array of [`KeyInfo`](../../../Types/Wire/Key.md#keyinfo).
