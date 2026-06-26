# PMWPaymentStatus

The `PMWPaymentStatus` attestation type verifies the status of a payment transaction initiated by a Protocol Managed Wallet on an external chain.

## Request

Request body:

- `opType`: wallet operation type.
- `senderAddress`: sender address on the external chain.
- `nonce`: batch nonce of the payment instruction.
- `subNonce`: sequence number of the payment instruction.

**Nonce semantics by chain:**

| Chain | `nonce` | `subNonce` |
|-------|---------|------------|
| XRP | XRP `sequenceNumber` | XRP `sequenceNumber` (same as nonce) |
| UTXO | Batch identifier | Individual payment instruction index |

## Response

Response body:

- `recipientAddress`: recipient address (from `PaymentInstructionMessage` on C-Chain).
- `tokenId`: token ID (variable-length `bytes`); empty means native token.
- `amount`: amount (in minimal units) to be sent.
- `maxFee`: maximum fee (in minimal units) that can be paid for the transaction.
- `paymentReference`: from C-Chain.
- `transactionStatus`:
  - `0` (success): transaction is recorded on-chain and was successful.
  - `1` (reverted): transaction is recorded on-chain but was reverted.
- `revertReason`: depends on the blockchain; for XRPL, see [transaction result codes](https://xrpl.org/docs/references/protocol/transactions/transaction-results).
- `receivedAmount` : amount (in minimal units) received on the `recipientAddress`.
- `transactionFee`: total transaction fee spent (in minimal units).
- `transactionId`: transaction hash on the external chain.
- `blockNumber`: number of the block (or ledger) in which the transaction is included.
- `blockTimestamp`: timestamp of the block in which the transaction is included.

## Chain Support

Currently, `PMWPaymentStatus` is only used for XRP.

## Verification

### Retrieve PaymentInstructionMessage

Find the `TeeInstructionsSent` event from the C-Chain indexer logs via $\mathrm{extensionId} = 0$ and:

$$\mathrm{instructionId} = \mathrm{keccak256}(\mathrm{abi.encode}(\mathrm{opType},\ \text{PAY},\ \mathrm{sourceId},\ \mathrm{senderAddress},\ \mathrm{nonce}))$$

If the wallet allows batch transactions, multiple `TeeInstructionsSent` events with the same nonce will be emitted.
Decode the `message` field for each event and filter for the required `subNonce`.

The `message` field in `TeeInstructionsSent` contains a [`PaymentInstructionMessage`](../../../PMW/Reference/Types/Payment.md#paymentinstructionmessage).

### Check Transaction

Look up the transaction via `senderAddress` and `nonce` (or via `paymentReference`).

**Transaction not found:**

- Cannot prove anything → the verifier returns an error, which the service layer translates to an HTTP error response.

**Transaction successful:**

- `transactionStatus` = success.
- `receivedAmount` = amount received on the `recipientAddress`.
- `transactionFee` = transaction fee.
- `revertReason` = empty string.

**Transaction reverted** (status ≠ `tesSUCCESS`):

- `transactionStatus` = reverted.
- `receivedAmount` = 0.
- `transactionFee` = transaction fee.
- `revertReason` = actual [transaction result code](https://xrpl.org/docs/references/protocol/transactions/transaction-results).

## Notes

- The XRP indexer supports finding transactions via `sourceAddress` and `nonce`, as well as via `paymentReference`.
- The `deliveredAmount` and receiver can be calculated from `AffectedNodes` in the XRP transaction metadata.
- For partial payments, consult the [delivered_amount field documentation](https://xrpl.org/docs/concepts/payment-Types/partial-payments#the-delivered_amount-field).

### 2. Find Transaction on External Chain

- **UTXO:** Look up via `paymentReference` (TBD).