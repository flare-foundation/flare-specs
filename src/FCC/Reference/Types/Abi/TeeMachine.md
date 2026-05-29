# TEE Machine Types (ABI)

Types related to TEE machine attestation and registration, used for ABI encoding and on-chain verification.
For the JSON wire types returned by TEE proxy APIs, see [TEE Machine (wire)](../Wire/TeeMachine.md).

## TeeMachine

Identifies a TEE machine and the location of its [TEE proxy](../../Components/Proxy.md).
Carried in the [`TeeInstructionsSent`](../../Contracts/FlareTeeManagerEvents.md#teeinstructionssent) event's `teeMachines` field; one record per destination machine.


```json
{
  "$id": "TeeMachine",
  "type": "object",
  "properties": {
    "teeId": { "type": "string", "format": "address", "description": "TEE machine ID." },
    "teeProxyId": { "type": "string", "format": "address", "description": "Proxy identity address." },
    "url": { "type": "string", "description": "Base URL of the TEE proxy." }
  },
  "required": ["teeId", "teeProxyId", "url"]
}
```

## TeeState

Encodes the state of a TEE machine for use in [attestations](#attestation).
Consists of a system state (defined by Flare) and a custom compute extension state.
Either version hash may be `0` (the 32-byte zero), in which case the corresponding body is empty `bytes`.


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

## Attestation

The struct ABI-encoded and hashed to produce the TEE-specific challenge for platform attestation.


```json
{
  "$id": "Attestation",
  "type": "object",
  "properties": {
    "challenge": { "type": "string", "format": "bytes32", "description": "Challenge value bound to this attestation." },
    "publicKey": { "$ref": "Common.md#publickey", "description": "Public key corresponding to the TEE identity." },
    "initialSigningPolicyId": { "type": "integer", "format": "uint32", "description": "ID of the first signing policy available to the TEE." },
    "initialSigningPolicyHash": { "type": "string", "format": "bytes32", "description": "Hash of the initial signing policy." },
    "lastSigningPolicyId": { "type": "integer", "format": "uint32", "description": "ID of the most recent signing policy available to the TEE." },
    "lastSigningPolicyHash": { "type": "string", "format": "bytes32", "description": "Hash of the most recent signing policy." },
    "state": { "$ref": "#teestate" },
    "teeTimestamp": { "type": "integer", "format": "uint64", "description": "Local timestamp at the TEE machine at time of attestation." }
  },
  "required": ["challenge", "publicKey", "initialSigningPolicyId", "initialSigningPolicyHash", "lastSigningPolicyId", "lastSigningPolicyHash", "state", "teeTimestamp"]
}
```

## TeeAttestation

Instruction message for a TEE attestation request, wrapping the machine data and challenge.


```json
{
  "$id": "TeeAttestation",
  "type": "object",
  "properties": {
    "teeMachine": { "$ref": "#teemachinewithattestationdata" },
    "challenge": { "type": "string", "format": "bytes32", "description": "Random challenge." }
  },
  "required": ["teeMachine", "challenge"]
}
```

## TeeMachineWithAttestationData

TEE machine registration data included in attestation instructions.


```json
{
  "$id": "TeeMachineWithAttestationData",
  "type": "object",
  "properties": {
    "teeId": { "type": "string", "format": "address", "description": "TEE machine ID." },
    "initialTeeId": { "type": "string", "format": "address", "description": "Initial TEE machine ID (differs from teeId for replicated machines)." },
    "url": { "type": "string", "description": "TEE machine URL." },
    "codeHash": { "type": "string", "format": "bytes32", "description": "Hash of the code running in the TEE." },
    "platform": { "type": "string", "format": "bytes32", "description": "Platform identifier (e.g., INTEL_TDX, GCP_AMD_SEV)." }
  },
  "required": ["teeId", "initialTeeId", "url", "codeHash", "platform"]
}
```
