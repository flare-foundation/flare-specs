# F_GET TEE_INFO

[Direct action](../../Actions.md#direct-actions) issued by the [TEE proxy](../../../Components/TeeProxy.md) for liveness and state polling.
The proxy issues it periodically (every $\sim 10$ seconds), with a challenge derived from the latest C-chain block hash; the result feeds the [last-attestation cache](../../../Components/TeeProxy.md#in-memory-stores) served at `GET /info`.
The TEE machine signs an [`Attestation`](../../../Types/Abi/TeeMachine.md#attestation) struct over the supplied challenge and returns it together with platform attestation data.

## Action message

[`TeeInfoRequest`](../../../Types/Wire/TeeMachine.md#teeinforequest).

## Action result

[`TeeInfoResponse`](../../../Types/Wire/TeeMachine.md#teeinforesponse).
