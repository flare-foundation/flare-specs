# Voting Types

Types used in the [voting](../../../Operations/Voting.md) process for instruction signature aggregation.
These structs are ABI-encoded for computing the iterative `voteHash` chain.

## VoteSequenceInit

The initial vote hash is computed from the ABI encoding of this struct, given a sequence number of $0$.


```json
{
  "$id": "VoteSequenceInit",
  "type": "object",
  "properties": {
    "instructionId": { "type": "string", "format": "bytes32", "description": "Unique ID of the instruction." },
    "instructionHash": { "type": "string", "format": "bytes32", "description": "Hash of the instruction data." },
    "rewardEpochId": { "type": "integer", "format": "uint32", "description": "ID of the reward epoch." },
    "teeId": { "type": "string", "format": "address", "description": "Identity of the destination TEE machine." }
  },
  "required": ["instructionId", "instructionHash", "rewardEpochId", "teeId"]
}
```

## VoteSequenceNext

On arrival of each subsequent vote, a new `voteHash` is computed by hashing the ABI encoding of this struct.


```json
{
  "$id": "VoteSequenceNext",
  "type": "object",
  "properties": {
    "voteHash": { "type": "string", "format": "bytes32", "description": "Previous vote hash in the chain." },
    "sequence": { "type": "integer", "format": "uint64", "description": "Sequence number of this vote." },
    "signature": { "type": "string", "format": "bytes", "description": "Signature from the voting provider." },
    "additionalVariableMessageHash": { "type": "string", "format": "bytes32", "description": "Hash of the provider's additional variable message." },
    "timestamp": { "type": "integer", "format": "uint64", "description": "Arrival timestamp of the vote." }
  },
  "required": ["voteHash", "sequence", "signature", "additionalVariableMessageHash", "timestamp"]
}
```

## VoteReceipt

Signed by the TEE proxy each time a new vote arrives.
Contains the fields of the corresponding vote alongside the updated `voteHash`.


```json
{
  "$id": "VoteReceipt",
  "type": "object",
  "properties": {
    "instructionHash": { "type": "string", "format": "bytes32", "description": "Hash of the instruction being voted on." },
    "sequence": { "type": "integer", "format": "uint64", "description": "Sequence number of this vote." },
    "signature": { "type": "string", "format": "bytes", "description": "Signature from the voting provider." },
    "additionalVariableMessageHash": { "type": "string", "format": "bytes32", "description": "Hash of the provider's additional variable message." },
    "timestamp": { "type": "integer", "format": "uint64", "description": "Arrival timestamp of the vote." },
    "voteHash": { "type": "string", "format": "bytes32", "description": "Updated vote hash after this vote." }
  },
  "required": ["instructionHash", "sequence", "signature", "additionalVariableMessageHash", "timestamp", "voteHash"]
}
```
