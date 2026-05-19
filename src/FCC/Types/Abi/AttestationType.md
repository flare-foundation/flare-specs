# Attestation Type Schemas

Request and response body types for FDC2 [attestation types](../../Extensions/FDC2/AttestationTypes/).

## TeeAvailabilityCheck

### RequestBody

```json
{
  "$id": "TeeAvailabilityCheck.RequestBody",
  "type": "object",
  "properties": {
    "teeId": { "type": "string", "format": "address", "description": "TEE identity address of the machine to be checked." },
    "teeProxyId": { "type": "string", "format": "address", "description": "Identity address of the TEE proxy." },
    "url": { "type": "string", "description": "URL of the TEE proxy." },
    "challenge": { "type": "string", "format": "bytes32", "description": "Random challenge for the attestation request." },
    "instructionId": { "type": "string", "format": "bytes32", "description": "Instruction ID for the attestation request." }
  },
  "required": ["teeId", "teeProxyId", "url", "challenge", "instructionId"]
}
```

### AvailabilityCheckStatus

**Solidity enum:** `{ OK, OBSOLETE, DOWN }`

| Value | Meaning |
|-------|---------|
| `OK` | TEE machine is available and valid. |
| `OBSOLETE` | Platform state is outdated. |
| `DOWN` | TEE machine is unavailable. |

### ResponseBody

The `state` field uses the [`TeeState`](TeeMachine.md#teestate) struct.

```json
{
  "$id": "TeeAvailabilityCheck.ResponseBody",
  "type": "object",
  "properties": {
    "status": { "type": "integer", "description": "AvailabilityCheckStatus enum value." },
    "teeTimestamp": { "type": "integer", "format": "uint64", "description": "Timestamp from the TEE machine." },
    "codeHash": { "type": "string", "format": "bytes32", "description": "Value of the submods.container.image_digest claim." },
    "platform": { "type": "string", "format": "bytes32", "description": "Value of the hwmodel claim." },
    "initialSigningPolicyId": { "type": "integer", "format": "uint32", "description": "From the TEE proxy attestation result." },
    "lastSigningPolicyId": { "type": "integer", "format": "uint32", "description": "From the TEE proxy attestation result." },
    "state": { "$ref": "TeeMachine.md#teestate" }
  },
  "required": ["status", "teeTimestamp", "codeHash", "platform", "initialSigningPolicyId", "lastSigningPolicyId", "state"]
}
```

## PMWPaymentStatus

### RequestBody

```json
{
  "$id": "PMWPaymentStatus.RequestBody",
  "type": "object",
  "properties": {
    "opType": { "type": "string", "format": "bytes32", "description": "Wallet operation type." },
    "senderAddress": { "type": "string", "description": "Sender address on the external chain." },
    "nonce": { "type": "integer", "format": "uint64", "description": "Batch nonce of the payment instruction." },
    "subNonce": { "type": "integer", "format": "uint64", "description": "Sequence number of the payment instruction." }
  },
  "required": ["opType", "senderAddress", "nonce", "subNonce"]
}
```

### ResponseBody

```json
{
  "$id": "PMWPaymentStatus.ResponseBody",
  "type": "object",
  "properties": {
    "recipientAddress": { "type": "string", "description": "Recipient address." },
    "tokenId": { "type": "string", "format": "bytes", "description": "Token ID; empty for native token." },
    "amount": { "type": "string", "format": "uint256", "description": "Amount to be sent." },
    "maxFee": { "type": "string", "format": "uint256", "description": "Maximum fee." },
    "paymentReference": { "type": "string", "format": "bytes32", "description": "Payment reference." },
    "transactionStatus": { "type": "integer", "format": "uint8", "description": "0 = success, 1 = reverted." },
    "revertReason": { "type": "string", "description": "Revert reason (chain-specific)." },
    "receivedAmount": { "type": "string", "format": "uint256", "description": "Amount actually received." },
    "transactionFee": { "type": "string", "format": "uint256", "description": "Total transaction fee spent." },
    "transactionId": { "type": "string", "format": "bytes32", "description": "Transaction hash on the external chain." },
    "blockNumber": { "type": "integer", "format": "uint64", "description": "Block or ledger number." },
    "blockTimestamp": { "type": "integer", "format": "uint64", "description": "Block timestamp." }
  },
  "required": ["recipientAddress", "tokenId", "amount", "maxFee", "paymentReference", "transactionStatus", "revertReason", "receivedAmount", "transactionFee", "transactionId", "blockNumber", "blockTimestamp"]
}
```

## PMWFeeProof

### RequestBody

```json
{
  "$id": "PMWFeeProof.RequestBody",
  "type": "object",
  "properties": {
    "opType": { "type": "string", "format": "bytes32", "description": "Wallet operation type." },
    "senderAddress": { "type": "string", "description": "Sender address on the external chain." },
    "fromNonce": { "type": "integer", "format": "uint64", "description": "Inclusive start of the nonce range." },
    "toNonce": { "type": "integer", "format": "uint64", "description": "Inclusive end of the nonce range." },
    "untilTimestamp": { "type": "integer", "format": "uint64", "description": "Flare chain block timestamp cutoff for reissue events." }
  },
  "required": ["opType", "senderAddress", "fromNonce", "toNonce", "untilTimestamp"]
}
```

### ResponseBody

```json
{
  "$id": "PMWFeeProof.ResponseBody",
  "type": "object",
  "properties": {
    "actualFee": { "type": "string", "format": "uint256", "description": "Sum of executed transaction fees (in drops)." },
    "estimatedFee": { "type": "string", "format": "uint256", "description": "Sum of maxFees from pay and reissue events (in drops)." }
  },
  "required": ["actualFee", "estimatedFee"]
}
```

## PMWMultisigAccountConfigured

### RequestBody

```json
{
  "$id": "PMWMultisigAccountConfigured.RequestBody",
  "type": "object",
  "properties": {
    "accountAddress": { "type": "string", "description": "Address of the multisig account on the external chain." },
    "publicKeys": { "type": "array", "items": { "type": "string", "format": "bytes" }, "description": "Public keys of the multisig account owners." },
    "threshold": { "type": "integer", "format": "uint64", "description": "Threshold for the multisig account." }
  },
  "required": ["accountAddress", "publicKeys", "threshold"]
}
```

### PMWMultisigAccountStatus

**Solidity enum:** `{ OK, ERROR }`

| Value | Meaning |
|-------|---------|
| `OK` | Multisig account is correctly configured. |
| `ERROR` | Configuration check failed. |

### ResponseBody

```json
{
  "$id": "PMWMultisigAccountConfigured.ResponseBody",
  "type": "object",
  "properties": {
    "status": { "type": "integer", "description": "PMWMultisigAccountStatus enum value." },
    "sequence": { "type": "integer", "format": "uint64", "description": "Sequence number of the multisig account." }
  },
  "required": ["status", "sequence"]
}
```
