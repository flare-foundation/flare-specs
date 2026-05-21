# F_REG TEE_ATTESTATION

[Instruction action](../../Actions.md#instruction-actions) used during [registration](../../../TeeManagement/Registration.md): a [signer](../../Instructions.md#signers) submits a challenge through the [TEE proxy](../../../Components/TeeProxy.md) and the TEE machine returns the same attestation payload as a self-initiated [`TEE_INFO`](../F_GET/TeeInfo.md).

## Event message

The instruction's `originalMessage` decodes to [`TeeAttestation`](../../../Types/Abi/TeeMachine.md#teeattestation) (wrapping [`TeeMachineWithAttestationData`](../../../Types/Abi/TeeMachine.md#teemachinewithattestationdata) and a challenge).

## Action result

[`TeeInfoResponse`](../../../Types/Wire/TeeMachine.md#teeinforesponse), constructed identically to [`TEE_INFO`](../F_GET/TeeInfo.md).

## Notes

- The machine rejects the request if `teeMachine.teeId` does not match its own identity, or if `challenge` is the zero hash.
- A result is produced only on the `threshold` submission tag; the `end` action returns no payload.
