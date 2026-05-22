# Policy Wire Types

JSON types carried in policy direct actions ([`INITIALIZE_POLICY`](../../Operations/System/F_POLICY.md#initialize_policy), [`UPDATE_POLICY`](../../Operations/System/F_POLICY.md#update_policy)).

## InitializePolicyRequest

Direct action message that seeds the TEE machine's first signing policy.

```json
{
  "$id": "InitializePolicyRequest",
  "type": "object",
  "properties": {
    "initialPolicyBytes": { "type": "string", "format": "bytes", "description": "Packed signing policy bytes as emitted in `SigningPolicyInitialized`." },
    "publicKeys": { "type": "array", "items": { "$ref": "Common.md#publickey" }, "description": "Voter public keys, in the same order as the signing policy's signer addresses." }
  },
  "required": ["initialPolicyBytes", "publicKeys"]
}
```

## UpdatePolicyRequest

Direct action message that rotates the TEE machine to the next signing policy.

```json
{
  "$id": "UpdatePolicyRequest",
  "type": "object",
  "properties": {
    "newPolicy": { "$ref": "#multisignedpolicy" },
    "publicKeys": { "type": "array", "items": { "$ref": "Common.md#publickey" }, "description": "Voter public keys for the new policy, in the same order as the signing policy's signer addresses." }
  },
  "required": ["newPolicy", "publicKeys"]
}
```

## MultiSignedPolicy

A packed signing policy together with enough [signatures](../../../Utilities/Signing.md) from the previous policy's signers to meet its threshold.

```json
{
  "$id": "MultiSignedPolicy",
  "type": "object",
  "properties": {
    "policyBytes": { "type": "string", "format": "bytes", "description": "Packed signing policy bytes as emitted in `SigningPolicyInitialized`." },
    "signatures": { "type": "array", "items": { "$ref": "Common.md#signature" }, "description": "Signatures over keccak256(policyBytes); accumulated signer weight must exceed the active policy's threshold." }
  },
  "required": ["policyBytes", "signatures"]
}
```
