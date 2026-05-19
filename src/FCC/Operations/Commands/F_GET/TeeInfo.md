# F_GET TEE_INFO

## Description

Calculates TEE attestation for a given challenge and returns the attestation result. This is a direct [action](../../Actions.md) triggered by the [TEE proxy](../../../Components/TeeProxy.md) without any signatures.

## Action message

The action message is formatted as the [`TeeInfoRequest`](../../../Types/Wire/TeeMachine.md#teeinforequest) struct.

## Fixed message

/

## Variable message

/

## Additional action data

/

## Action result

The action result is formatted as the [`TeeInfoResponse`](../../../Types/Wire/TeeMachine.md#teeinforesponse) struct, containing [`TeeInfo`](../../../Types/Wire/TeeMachine.md#teeinfo) and [`MachineData`](../../../Types/Wire/TeeMachine.md#machinedata).

## Notes

- **Proxy result hook:** Proxy stores the latest deserialized action result.
