# F_REG TEE_ATTESTATION

## Description

Calculates TEE attestation for a given challenge and returns the attestation result. In terms of TEE machine processing it behaves exactly the same as the [TEE_INFO](F_GET--TEE_INFO.md) direct instruction.

## Event message

The instruction event is decoded into a [`TeeAttestation`](../Types/Abi/TeeMachine.md#teeattestation) struct wrapping the [`TeeMachineWithAttestationData`](../Types/Abi/TeeMachine.md#teemachinewithattestationdata) and challenge.

## Fixed message

/

## Variable message

/

## Additional action data

/

## Action result

TEE attestation response formatted as [`TeeInfoResponse`](../Types/Wire/TeeMachine.md#teeinforesponse).
See [TEE_INFO](F_GET--TEE_INFO.md) for full field descriptions.

## Notes

- **Submission tags:** The command only produces a result on the `Threshold` submission tag. On the `End` submission tag, no result is returned.
