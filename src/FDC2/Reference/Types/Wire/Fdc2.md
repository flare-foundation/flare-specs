# FDC2 Wire Types

JSON types returned by TEE machine actions for FDC2 operations.
For the corresponding ABI types used for on-chain proof verification, see [FDC2 (ABI)](../Abi/Fdc2.md).

## ProveResponse

Action result returned by the TEE machine for an FDC2 [`PROVE`](../../Operations/Prove.md) command.
Must be converted into a [Proof](../Abi/Fdc2.md#proof) struct for on-chain verification; see [FDC2](../../../Concepts.md#assembling-a-proof-for-on-chain-verification) for the mapping.


```json
{
  "$id": "ProveResponse",
  "type": "object",
  "properties": {
    "responseHeader": { "type": "string", "format": "bytes", "description": "ABI-encoded Fdc2ResponseHeader." },
    "requestBody": { "type": "string", "format": "bytes", "description": "Original request body." },
    "responseBody": { "type": "string", "format": "bytes", "description": "Attestation response body." },
    "teeSignature": { "type": "string", "format": "bytes", "description": "TEE machine signature of the message hash." },
    "cosignerSignatures": { "type": "array", "items": { "type": "string", "format": "bytes" }, "description": "Cosigner signatures." },
    "dataProviderSignatures": { "type": "string", "format": "bytes", "description": "Signing policy signatures in relay format." }
  },
  "required": ["responseHeader", "requestBody", "responseBody", "teeSignature", "cosignerSignatures", "dataProviderSignatures"]
}
```