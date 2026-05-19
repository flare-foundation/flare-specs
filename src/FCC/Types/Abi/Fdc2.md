# FDC2 Types

Types related to the [Flare TEE Data Connector](../../Extensions/FDC2/README.md) (FDC2).

## Fdc2AttestationRequest

Wrapper for an FDC2 attestation request, containing a header and a type-specific request body.


```json
{
  "$id": "Fdc2AttestationRequest",
  "type": "object",
  "properties": {
    "header": { "$ref": "#fdc2requestheader" },
    "requestBody": { "type": "string", "format": "bytes", "description": "ABI-encoded attestation request body; structure depends on the attestation type." }
  },
  "required": ["header", "requestBody"]
}
```

## Fdc2RequestHeader

Header for an FDC2 attestation request.


```json
{
  "$id": "Fdc2RequestHeader",
  "type": "object",
  "properties": {
    "attestationType": { "type": "string", "format": "bytes32", "description": "Attestation type identifier." },
    "sourceId": { "type": "string", "format": "bytes32", "description": "Source chain identifier." },
    "thresholdBIPS": { "type": "integer", "format": "uint16", "description": "Weight of data provider signatures required, in basis points. Must exceed 40%." },
    "proofOwner": { "type": "string", "format": "address", "description": "Address that owns the proof; zero address indicates a public proof." }
  },
  "required": ["attestationType", "sourceId", "thresholdBIPS", "proofOwner"]
}
```

## Fdc2ResponseHeader

Header for an FDC2 attestation response.
Extends the request header with cosigner information and a timestamp.


```json
{
  "$id": "Fdc2ResponseHeader",
  "type": "object",
  "properties": {
    "attestationType": { "type": "string", "format": "bytes32", "description": "Attestation type identifier." },
    "sourceId": { "type": "string", "format": "bytes32", "description": "Source chain identifier." },
    "thresholdBIPS": { "type": "integer", "format": "uint16", "description": "Weight of data provider signatures required, in basis points." },
    "proofOwner": { "type": "string", "format": "address", "description": "Proof owner address." },
    "cosigners": { "type": "array", "items": { "type": "string", "format": "address" }, "description": "Cosigner addresses." },
    "cosignersThreshold": { "type": "integer", "format": "uint64", "description": "Cosigners threshold." },
    "timestamp": { "type": "integer", "format": "uint64", "description": "Timestamp of the response." }
  },
  "required": ["attestationType", "sourceId", "thresholdBIPS", "proofOwner", "cosigners", "cosignersThreshold", "timestamp"]
}
```

## Fdc2Signatures

Bundles all signature types required for on-chain FDC2 proof verification.


```json
{
  "$id": "Fdc2Signatures",
  "type": "object",
  "properties": {
    "signingPolicySignatures": { "type": "string", "format": "bytes", "description": "Data provider signatures in relay format." },
    "teeSignatures": { "type": "array", "items": { "$ref": "Common.md#signature" }, "description": "TEE machine signatures." },
    "cosignerSignatures": { "type": "array", "items": { "$ref": "Common.md#signature" }, "description": "Cosigner signatures." }
  },
  "required": ["signingPolicySignatures", "teeSignatures", "cosignerSignatures"]
}
```

## Proof

On-chain proof structure for FDC2 attestation verification.
Each attestation type defines its own `RequestBody` and `ResponseBody` within this pattern.


```json
{
  "$id": "Proof",
  "type": "object",
  "properties": {
    "signatures": { "$ref": "#fdc2signatures" },
    "header": { "$ref": "#fdc2responseheader" },
    "requestBody": { "description": "Attestation-type-specific request body struct." },
    "responseBody": { "description": "Attestation-type-specific response body struct." }
  },
  "required": ["signatures", "header", "requestBody", "responseBody"]
}
```
