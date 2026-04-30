# Instruction Wire Types

JSON types for [TEE instructions](../../Operations/Instructions.md#tee-instructions) submitted by [relay clients](../../Operations/RelayClient.md) to the [TEE proxy](../../TeeManagement/TeeProxy.md).
For the corresponding ABI struct used to compute `instructionHash`, see [Instruction (ABI)](../Abi/Instruction.md).

## Instruction

The JSON body posted at [`POST /instruction`](../../TeeManagement/TeeProxy.md#external-write-apis).
`signature` is produced by the relaying [data provider](../../../Terminology/Roles.md#data-provider) or [cosigner](../../../Terminology/Roles.md#cosigner) over [`HashForSigning(data)`](#hashforsigning) following the [Ethereum Signed Message](../../../Utilities/Signing.md) procedure.


```json
{
  "$id": "Instruction",
  "type": "object",
  "properties": {
    "data": { "$ref": "#data" },
    "signature": { "type": "string", "format": "bytes", "description": "ECDSA signature over HashForSigning(data)." }
  },
  "required": ["data", "signature"]
}
```

## Data

The signed payload.
Carries every field of the [`TeeInstruction`](../Abi/Instruction.md#teeinstruction) ABI struct (which forms `instructionHash`) plus an `additionalVariableMessage` byte field that is **not** part of `TeeInstruction` and **not** part of `instructionHash`.


```json
{
  "$id": "Data",
  "type": "object",
  "properties": {
    "instructionId": { "type": "string", "format": "bytes32", "description": "Unique index for the instruction." },
    "teeId": { "type": "string", "format": "address", "description": "Unique identity of the destination TEE machine." },
    "timestamp": { "type": "integer", "format": "uint64", "description": "Timestamp of the block in which the instruction was issued." },
    "rewardEpochId": { "type": "integer", "format": "uint32", "description": "ID of the reward epoch in which the instruction was issued." },
    "opType": { "type": "string", "format": "bytes32", "description": "Operation type from the instruction event." },
    "opCommand": { "type": "string", "format": "bytes32", "description": "Command type from the instruction event." },
    "cosigners": { "type": "array", "items": { "type": "string", "format": "address" }, "description": "Optional list of cosigner addresses." },
    "cosignersThreshold": { "type": "integer", "format": "uint64", "description": "Threshold of cosigner signatures required." },
    "originalMessage": { "type": "string", "format": "bytes", "description": "The message from the instruction event." },
    "additionalFixedMessage": { "type": "string", "format": "bytes", "description": "Command-specific data, identical across all senders contributing to the same vote." },
    "additionalVariableMessage": { "type": "string", "format": "bytes", "description": "Command-specific data supplied independently by each sender; not part of instructionHash." }
  },
  "required": ["instructionId", "teeId", "timestamp", "rewardEpochId", "opType", "opCommand", "cosignersThreshold", "originalMessage"]
}
```

## DirectInstruction

The JSON body posted at [`POST /direct`](../../TeeManagement/TeeProxy.md#external-write-apis) for [direct instructions](../../Operations/Instructions.md#direct-instructions).
The proxy rejects bodies with a system (`F_`) `opType`.

```json
{
  "$id": "DirectInstruction",
  "type": "object",
  "properties": {
    "opType": { "type": "string", "format": "bytes32", "description": "Operation type." },
    "opCommand": { "type": "string", "format": "bytes32", "description": "Operation command." },
    "message": { "type": "string", "format": "bytes", "description": "Command-specific payload." }
  },
  "required": ["opType", "opCommand", "message"]
}
```

## HashForSigning

For a [`Data`](#data) value $d$, the hash that is signed is

$$
\mathrm{HashForSigning}(d) = \mathrm{Hash}(\mathrm{instructionHash},\ \mathrm{Hash}(d.\mathrm{additionalVariableMessage})),
$$

where `instructionHash` is the keccak-256 hash of the ABI-encoded [`TeeInstruction`](../Abi/Instruction.md#teeinstruction) struct constructed from the fields of $d$ other than `additionalVariableMessage`.
The final ECDSA signature is produced from $\mathrm{HashForSigning}(d)$ following the [Ethereum Signed Message](../../../Utilities/Signing.md) procedure.
