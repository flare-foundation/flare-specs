# Common Wire Types

Shared wire types used across FCC HTTP APIs.

## PublicKey

An elliptic curve public key, represented as a JSON object with hex-encoded coordinates.
This is the same structure as the [ABI type](../Abi/Common.md#publickey), serialized to JSON following the [format glossary](../index.md#format-glossary).


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

Over HTTP, ECDSA signatures are represented as a single `0x`-prefixed hex string encoding the $65$-byte concatenation $r \mathbin\| s \mathbin\| v$, where $r$ and $s$ are $32$ bytes each and $v$ is $1$ byte.

```json
{
  "$id": "Signature",
  "type": "string",
  "format": "bytes",
  "description": "65-byte ECDSA signature (r || s || v), 0x-prefixed hex."
}
```

For on-chain verification, signatures are decomposed into the $(v, r, s)$ components defined by the [`Signature`](../Abi/Common.md#signature) ABI type.
