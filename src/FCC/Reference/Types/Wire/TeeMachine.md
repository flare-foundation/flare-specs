# TEE Machine Wire Types

JSON types returned by TEE proxy APIs for machine information and attestation.
For the corresponding ABI types used for on-chain encoding and hash computation, see [TEE Machine (ABI)](../Abi/TeeMachine.md).

## TeeInfoRequest

Direct action message requesting TEE attestation information.
Sent by the TEE proxy to its TEE machine.


```json
{
  "$id": "TeeInfoRequest",
  "type": "object",
  "properties": {
    "challenge": { "type": "string", "format": "bytes32", "description": "Random number selected by the proxy; should be the hash of a recent block." }
  },
  "required": ["challenge"]
}
```

## TeeInfoResponse

Action result returned for [`TEE_INFO`](../../Operations/F_GET.md#tee_info) and [`TEE_ATTESTATION`](../../Operations/F_REG.md#tee_attestation) commands.


```json
{
  "$id": "TeeInfoResponse",
  "type": "object",
  "properties": {
    "teeInfo": { "$ref": "#teeinfo" },
    "machineData": { "$ref": "#machinedata" },
    "dataSignature": { "type": "string", "format": "bytes", "description": "ECDSA signature of keccak256(ABI(machineData))." },
    "attestation": { "type": "string", "format": "bytes", "description": "Platform attestation data (binary or JWT)." }
  },
  "required": ["teeInfo", "machineData", "dataSignature", "attestation"]
}
```

The `GET /info` proxy endpoint wraps this in an outer object that adds a `proxySignature` field (the proxy's own ECDSA signature over the `teeInfo` hash).

## TeeInfo

TEE attestation information.
Contains the same logical fields as the [Attestation](../Abi/TeeMachine.md#attestation) ABI type.


```json
{
  "$id": "TeeInfo",
  "type": "object",
  "properties": {
    "challenge": { "type": "string", "format": "bytes32", "description": "Challenge used for attestation." },
    "publicKey": { "$ref": "Common.md#publickey", "description": "Identity public key." },
    "initialSigningPolicyId": { "type": "integer", "format": "uint32", "description": "Initial signing policy ID (never changes)." },
    "initialSigningPolicyHash": { "type": "string", "format": "bytes32", "description": "Initial signing policy hash." },
    "lastSigningPolicyId": { "type": "integer", "format": "uint32", "description": "Last signing policy ID." },
    "lastSigningPolicyHash": { "type": "string", "format": "bytes32", "description": "Last signing policy hash." },
    "state": { "$ref": "#teestate" },
    "teeTimestamp": { "type": "integer", "format": "uint64", "description": "Local TEE machine timestamp." }
  },
  "required": ["challenge", "publicKey", "initialSigningPolicyId", "initialSigningPolicyHash", "lastSigningPolicyId", "lastSigningPolicyHash", "state", "teeTimestamp"]
}
```

## TeeState

TEE machine state, containing ABI-encoded system and extension state blobs with their version hashes.


```json
{
  "$id": "TeeState",
  "type": "object",
  "properties": {
    "systemState": { "type": "string", "format": "bytes", "description": "ABI-encoded system state." },
    "systemStateVersion": { "type": "string", "format": "bytes32", "description": "Version hash of the system state encoding." },
    "state": { "type": "string", "format": "bytes", "description": "ABI-encoded custom compute extension state." },
    "stateVersion": { "type": "string", "format": "bytes32", "description": "Version hash of the extension state encoding." }
  },
  "required": ["systemState", "systemStateVersion", "state", "stateVersion"]
}
```

## MachineData

Machine registration data included in [TeeInfoResponse](#teeinforesponse).


```json
{
  "$id": "MachineData",
  "type": "object",
  "properties": {
    "extensionId": { "type": "string", "format": "bytes32", "description": "Extension ID the TEE belongs to." },
    "initialOwner": { "type": "string", "format": "address", "description": "Address of the initial owner." },
    "codeHash": { "type": "string", "format": "bytes32", "description": "Digest of code running in the TEE." },
    "platform": { "type": "string", "format": "bytes32", "description": "Platform identifier." },
    "publicKey": { "$ref": "Common.md#publickey", "description": "Identity public key." }
  },
  "required": ["extensionId", "initialOwner", "codeHash", "platform", "publicKey"]
}
```
