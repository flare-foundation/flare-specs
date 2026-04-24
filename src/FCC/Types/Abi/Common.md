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

An ECDSA signature decomposed into its $(v, r, s)$ components.
This is the on-chain representation used in Solidity structs.

Over HTTP, signatures are instead transmitted as a single `0x`-prefixed hex string encoding the $65$-byte concatenation $r \mathbin\| s \mathbin\| v$, where $r$ and $s$ are $32$ bytes each and $v$ is $1$ byte.
See [Signature (wire)](../Wire/Common.md#signature) for the wire representation.


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
