# Common Types

Shared types used across the FCC specification.

## PublicKey

An elliptic curve public key represented as its $(x, y)$ coordinates.


```json
{
  "$id": "PublicKey",
  "type": "object",
  "properties": {
    "x": { "type": "string", "format": "bytes32", "description": "x coordinate of the public key." },
    "y": { "type": "string", "format": "bytes32", "description": "y coordinate of the public key." }
  },
  "required": ["x", "y"]
}
```

## Signature

An ECDSA signature in Flare's [on-chain convention](../../../../Utilities/Signing.md#encoding-conventions): a `(v, r, s)` triple.
The corresponding off-chain representation is the [`Signature` wire type](../Wire/Common.md#signature).


```json
{
  "$id": "Signature",
  "type": "object",
  "properties": {
    "v": { "type": "integer", "format": "uint8", "description": "Recovery identifier." },
    "r": { "type": "string", "format": "bytes32", "description": "r component of the signature." },
    "s": { "type": "string", "format": "bytes32", "description": "s component of the signature." }
  },
  "required": ["v", "r", "s"]
}
```

## TeeIdKeyIdPair

Associates a TEE machine with a key ID.


```json
{
  "$id": "TeeIdKeyIdPair",
  "type": "object",
  "properties": {
    "teeId": { "type": "string", "format": "address", "description": "TEE machine ID." },
    "keyId": { "type": "integer", "format": "uint64", "description": "Key ID." }
  },
  "required": ["teeId", "keyId"]
}
```
