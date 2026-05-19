# Common Wire Types

Shared wire types used across FCC HTTP APIs.

## PublicKey

An elliptic curve public key, represented as a JSON object with hex-encoded coordinates.
This is the same structure as the [ABI type](../Abi/Common.md#publickey), serialized to JSON following the [format glossary](../Glossary.md).


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

Over HTTP, ECDSA signatures are represented as a single `0x`-prefixed hex string carrying the 65 signature bytes in Flare's [off-chain convention](../../../Utilities/Signing.md#encoding-conventions).
The corresponding on-chain representation is the [`Signature`](../Abi/Common.md#signature) ABI type.

```json
{
  "$id": "Signature",
  "type": "string",
  "format": "bytes",
  "description": "0x-prefixed hex ECDSA signature; see Utilities/Signing.md for the byte convention."
}
```
