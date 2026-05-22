# PMWPaymentStatus

The `PMWPaymentStatus` attestation type verifies the status of a payment transaction initiated by a Protocol Managed Wallet on an external chain.

## Request

Attestation request body:

- `opType` — Wallet operation type.
- `senderAddress` — Sender address on the external chain.
- `nonce` — Batch nonce of the payment instruction.
- `subNonce` — Sequence number of the payment instruction.

**Nonce semantics by chain:**

| Chain | `nonce` | `subNonce` |
|-------|---------|------------|
| XRP | XRP `sequenceNumber` | XRP `sequenceNumber` (same as nonce) |
| UTXO | Batch identifier | Individual payment instruction index |

## Response

Attestation response body:

- `recipientAddress` — Recipient address (from `PaymentInstructionMessage` on C-Chain).
- `tokenId` — Token ID (variable-length `bytes`); empty means native token (from C-Chain).
- `amount` — Amount in minimal units to be sent (from C-Chain).
- `maxFee` — Maximum fee in minimal units that can be paid for the transaction (from C-Chain).
- `paymentReference` — Payment reference (from C-Chain).
- `transactionStatus`:
  - `0` (success) — Transaction is recorded on-chain and was successful.
  - `1` (reverted) — Transaction is recorded on-chain but was reverted.
- `revertReason` — Depends on the blockchain; for XRPL, see [transaction result codes](https://xrpl.org/docs/references/protocol/transactions/transaction-results).
- `receivedAmount` — Amount in minimal units actually received on the `recipientAddress`.
- `transactionFee` — Total transaction fee spent in minimal units.
- `transactionId` — Transaction hash on the external chain.
- `blockNumber` — Number of the block (or ledger) in which the transaction is included.
- `blockTimestamp` — Timestamp of the block in which the transaction is included.

## Chain Support

Currently, `PMWPaymentStatus` is only used for XRP. Since the XRP Ledger uses deterministic consensus-based finality (validated ledgers are final), transaction reorgs are not a concern and no minimum confirmation block requirements are needed.

## Verification

### 1. Retrieve PaymentInstructionMessage

Find the `TeeInstructionsSent` event from the C-Chain indexer logs via $\mathrm{extensionId} = 0$ and:

$$\mathrm{instructionId} = \mathrm{keccak256}(\mathrm{abi.encode}(\mathrm{opType},\ \text{PAY},\ \mathrm{sourceId},\ \mathrm{senderAddress},\ \mathrm{nonce}))$$

If the wallet allows batch transactions, multiple `TeeInstructionsSent` events with the same nonce will be emitted. Decode the `message` field for each event and filter by the required `subNonce`.

The `message` field in `TeeInstructionsSent` contains a [`PaymentInstructionMessage`](../../../PMW/Reference/Types/Payment.md#paymentinstructionmessage).

### 2. Find Transaction on External Chain

- **UTXO:** Look up via `paymentReference` (TBD).

### 3. Check Transaction

**Transaction not found:**

- Cannot prove anything → the verifier returns an error, which the service layer translates to an HTTP error response.

### XRP

**Transaction lookup:** Look up the transaction via `senderAddress` and `nonce` (or via `paymentReference`).

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
