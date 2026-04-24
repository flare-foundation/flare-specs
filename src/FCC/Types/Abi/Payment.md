# Payment Types

Types related to [PMW transactions](../../Extensions/PMW/Transactions.md).

## PaymentInstructionMessage

Instruction message for a payment on an external chain.


```json
{
  "$id": "PaymentInstructionMessage",
  "type": "object",
  "properties": {
    "walletId": { "type": "string", "format": "bytes32", "description": "Wallet ID on which the payment is done." },
    "teeIdKeyIdPairs": { "type": "array", "items": { "$ref": "Common.md#teeidkeyidpair" }, "description": "Pairs of TEE ID and key ID." },
    "sourceId": { "type": "string", "format": "bytes32", "description": "ID of the chain where the transaction is to be performed." },
    "senderAddress": { "type": "string", "description": "Sending address on the external chain." },
    "recipientAddress": { "type": "string", "description": "Receiving address on the external chain." },
    "tokenId": { "type": "string", "format": "bytes", "description": "Token identifier (variable length); zero-valued for native token." },
    "amount": { "type": "string", "format": "uint256", "description": "Amount of token transferred." },
    "maxFee": { "type": "string", "format": "uint256", "description": "Maximum fee for the transaction." },
    "feeSchedule": { "type": "string", "format": "bytes", "description": "Encoded fee schedule for progressive fee escalation." },
    "paymentReference": { "type": "string", "format": "bytes32", "description": "Payment reference." },
    "nonce": { "type": "integer", "format": "uint64", "description": "Batch nonce of the transaction." },
    "subNonce": { "type": "integer", "format": "uint64", "description": "Sequence number of the payment instruction." },
    "batchEndTs": { "type": "integer", "format": "uint64", "description": "Batch end timestamp." }
  },
  "required": ["walletId", "teeIdKeyIdPairs", "sourceId", "senderAddress", "recipientAddress", "tokenId", "amount", "maxFee", "feeSchedule", "paymentReference", "nonce", "subNonce", "batchEndTs"]
}
```
