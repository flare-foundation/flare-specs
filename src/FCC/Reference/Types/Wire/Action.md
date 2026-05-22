# Action Wire Types

JSON types for [actions](../../../Operations/Actions.md) and their [responses](../../../Operations/Actions.md#action-responses), exchanged between the [TEE proxy](../../Components/Proxy.md) and its TEE machine.

## Action

The body served by the proxy on `POST /queue/{queueID}` and processed by the TEE machine.
For instruction actions, the per-signer arrays (`signatures`, `additionalVariableMessages`, `timestamps`) all share the same ordering.

```json
{
  "$id": "Action",
  "type": "object",
  "properties": {
    "data": { "$ref": "#actiondata" },
    "additionalVariableMessages": { "type": "array", "items": { "type": "string", "format": "bytes" }, "description": "Per-signer `additionalVariableMessage` values. Empty for direct actions." },
    "timestamps": { "type": "array", "items": { "type": "integer", "format": "uint64" }, "description": "Per-signer proxy arrival timestamps. Empty for direct actions." },
    "additionalActionData": { "type": "string", "format": "bytes", "description": "Optional proxy-supplied data for the machine." },
    "signatures": { "type": "array", "items": { "type": "string", "format": "bytes" }, "description": "Per-signer signatures collected by [voting](../../../Operations/Voting.md). Empty for direct actions." }
  },
  "required": ["data"]
}
```

## ActionData

```json
{
  "$id": "ActionData",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "bytes32", "description": "Unique action identifier." },
    "type": { "type": "string", "enum": ["instruction", "direct"], "description": "Origin of the action." },
    "submissionTag": { "type": "string", "description": "`threshold`, `end`, `submit`, or a custom tag." },
    "message": { "type": "string", "format": "bytes", "description": "JSON-encoded action payload: a [`TeeInstruction`](../Abi/Instruction.md#teeinstruction) for instruction actions, a [`DirectInstruction`](Instruction.md#directinstruction) for direct actions." }
  },
  "required": ["id", "type", "submissionTag", "message"]
}
```

## ActionResponse

Posted by the TEE machine to the proxy's internal `/result` endpoint, and served onward to external clients with `proxySignature` populated.

```json
{
  "$id": "ActionResponse",
  "type": "object",
  "properties": {
    "result": { "$ref": "#actionresult" },
    "signature": { "type": "string", "format": "bytes", "description": "TEE-machine signature over the result; see [Action Responses](../../../Operations/Actions.md#action-responses)." },
    "proxySignature": { "type": "string", "format": "bytes", "description": "Proxy signature added when the proxy serves the external `/result` endpoint; see [Action Responses](../../../Operations/Actions.md#action-responses)." }
  },
  "required": ["result", "signature"]
}
```

## ActionResult

```json
{
  "$id": "ActionResult",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "bytes32", "description": "Matches the originating action's `id`." },
    "submissionTag": { "type": "string", "description": "Matches the originating action's `submissionTag`." },
    "status": { "type": "integer", "format": "uint8", "description": "`0` error/invalid, `1` success, `2` in-progress (async), `3+` scheduled or extension-defined." },
    "log": { "type": "string", "description": "Exception message; empty on success." },
    "opType": { "type": "string", "format": "bytes32", "description": "Operation type from the originating action." },
    "opCommand": { "type": "string", "format": "bytes32", "description": "Operation command from the originating action." },
    "additionalResultStatus": { "type": "string", "format": "bytes", "description": "Optional supplemental status; routed to proxy [result hooks](../../Components/Proxy.md#result-hooks)." },
    "version": { "type": "string", "description": "Encoding version for `data`." },
    "data": { "type": "string", "format": "bytes", "description": "Action-specific result payload. For instruction actions with `submissionTag` = `end`, contains the marshalled [`RewardingData`](#rewardingdata)." }
  },
  "required": ["id", "submissionTag", "status", "opType", "opCommand", "version"]
}
```

## RewardingData

Marshalled into [`ActionResult.data`](#actionresult) when the action is an instruction action with `submissionTag` = `end`.
Used to attribute fees as rewards to data providers.

```json
{
  "$id": "RewardingData",
  "type": "object",
  "properties": {
    "voteSequence": { "$ref": "#votesequence" },
    "additionalData": { "type": "string", "format": "bytes", "description": "Copy of the response's `additionalResultStatus`." },
    "version": { "type": "string", "description": "Encoding version." },
    "signature": { "type": "string", "format": "bytes", "description": "TEE-machine signature over `voteHash`; see [Rewarding](../../../Operations/Rewarding.md#rewardingdata)." }
  },
  "required": ["voteSequence", "version", "signature"]
}
```

## VoteSequence

The reward-attribution state for the instruction.
`voteHash` is the final hash of the proxy's [vote-hash chain](../../../Operations/Rewarding.md#vote-receipts); together with the per-vote [`VoteReceipt`](../Abi/Voting.md#votereceipt)s it reconstructs the full vote ordering.

```json
{
  "$id": "VoteSequence",
  "type": "object",
  "properties": {
    "voteHash": { "type": "string", "format": "bytes32", "description": "Final vote hash from the proxy's vote-hash chain." },
    "instructionId": { "type": "string", "format": "bytes32", "description": "Unique ID of the instruction." },
    "instructionHash": { "type": "string", "format": "bytes32", "description": "keccak256 of the abi-encoded [`TeeInstruction`](../Abi/Instruction.md#teeinstruction)." },
    "rewardEpochId": { "type": "integer", "format": "uint32", "description": "Reward epoch of the instruction." },
    "teeId": { "type": "string", "format": "address", "description": "Destination TEE machine identity." },
    "signatures": { "type": "array", "items": { "type": "string", "format": "bytes" }, "description": "Per-signer signatures, ordered as they arrived at the proxy." },
    "additionalVariableMessageHashes": { "type": "array", "items": { "type": "string", "format": "bytes32" }, "description": "keccak256 of each signer's `additionalVariableMessage`, ordered to match `signatures`." },
    "timestamps": { "type": "array", "items": { "type": "integer", "format": "uint64" }, "description": "Proxy arrival timestamps, ordered to match `signatures`." }
  },
  "required": ["voteHash", "instructionId", "instructionHash", "rewardEpochId", "teeId", "signatures", "additionalVariableMessageHashes", "timestamps"]
}
```

