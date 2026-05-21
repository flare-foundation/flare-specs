# F_GET TEE_INFO

[Direct action](../../Actions.md#direct-actions) issued by the [TEE proxy](../../../Components/TeeProxy.md) for liveness and state polling.
The TEE machine signs an [`Attestation`](../../../Types/Abi/TeeMachine.md#attestation) struct over the supplied challenge and returns it together with platform attestation data.

## Action message

[`TeeInfoRequest`](../../../Types/Wire/TeeMachine.md#teeinforequest).

## Action result

[`TeeInfoResponse`](../../../Types/Wire/TeeMachine.md#teeinforesponse).
