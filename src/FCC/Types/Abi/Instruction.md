# Instruction Types

Types related to [instructions](../../Operations/Instructions.md) and their processing.

## TeeInstruction

The data structure signed by data providers and cosigners when relaying an instruction to a TEE machine.
The signature is computed over $\mathrm{Hash}($`instructionHash`$,$ `additionalVariableMessage`$)$, where `instructionHash` is the hash of the ABI-encoded `TeeInstruction` struct.


```json
{
  "$id": "TeeInstruction",
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
    "additionalFixedMessage": { "type": "string", "format": "bytes", "description": "Command-specific data, fixed across all providers and cosigners." }
  },
  "required": ["instructionId", "teeId", "timestamp", "rewardEpochId", "opType", "opCommand", "cosignersThreshold", "originalMessage"]
}
```

> **Note:** The `additionalVariableMessage` field is not part of the `TeeInstruction` struct.
> It is provider-specific and signed separately alongside the `instructionHash`.
> See [Instruction (wire)](../Wire/Instruction.md) for the JSON envelope that carries both alongside the signature.
