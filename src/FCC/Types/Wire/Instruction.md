# Instruction Wire Types

JSON types for [instructions](../../Operations/Instructions.md) submitted by [relay clients](../../Components/RelayClient.md) to the [TEE proxy](../../Components/TeeProxy.md).
For the corresponding ABI struct used to compute `instructionHash`, see [Instruction (ABI)](../Abi/Instruction.md).

## Instruction

The JSON body posted at [`POST /instruction`](../../Components/TeeProxy.md#external-write-apis).
`signature` is produced by the relaying [data provider](../../../Terminology/Roles.md#data-provider) or [cosigner](../../Operations/Instructions.md#cosigners) over [`hashForSigning`](../../Operations/Instructions.md#hashes).


```json
{
  "$id": "Instruction",
  "type": "object",
  "properties": {
    "data": { "$ref": "#data" },
    "signature": { "type": "string", "format": "bytes", "description": "ECDSA signature over [`hashForSigning`](../../Operations/Instructions.md#hashes)." }
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

The JSON body posted at [`POST /direct`](../../Components/TeeProxy.md#external-write-apis) for [direct actions](../../Operations/Actions.md#direct-actions).
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

