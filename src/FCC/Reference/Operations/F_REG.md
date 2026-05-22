# F_REG

[Instruction actions](../../Concepts/Actions.md#instruction-actions) used to register a TEE machine with `FlareTeeManager`.

## TEE_ATTESTATION

Used during [registration](../../TeeManagement/Registration.md).
`FlareTeeManager` emits the instruction with a challenge of $\mathrm{keccak256}(\mathrm{teeId} \,\|\, \mathrm{block.timestamp} \,\|\, \mathrm{Relay.getRandomNumber}())$; [signers](../../Concepts/Instructions.md#signers) relay it to the [TEE proxy](../Components/Proxy.md) and the destination TEE machine returns the same attestation payload as a self-initiated [`TEE_INFO`](F_GET.md#tee_info).

**Event message:** the instruction's `originalMessage` decodes to [`TeeAttestation`](../Types/Abi/TeeMachine.md#teeattestation) (wrapping [`TeeMachineWithAttestationData`](../Types/Abi/TeeMachine.md#teemachinewithattestationdata) and a challenge).

**Action result:** [`TeeInfoResponse`](../Types/Wire/TeeMachine.md#teeinforesponse), constructed identically to [`TEE_INFO`](F_GET.md#tee_info).

**Notes.**

- The machine rejects the request if `teeMachine.teeId` does not match its own identity, or if `challenge` is the zero hash.
- A result is produced only on the `threshold` submission tag; the `end` action returns no payload.
