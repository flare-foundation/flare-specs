# F_XRP REISSUE

## Description

Re-signs a previously issued XRP payment for resubmission, typically after the original transaction failed to confirm on the XRP Ledger.
The message format and processing flow match [`F_XRP PAY`](Pay.md); the only difference is the on-chain entry point ([`TeePayments.reissue`](../../Transactions.md#reissuing-a-payment)) and the `opCommand`.

## Event Message

Same as [`F_XRP PAY`](Pay.md#event-message): [`PaymentInstructionMessage`](../Types/Payment.md#paymentinstructionmessage).

## Fixed Message

None.

## Variable Message

None.

## Additional Action Data

None.

## Action Result

Same async lifecycle as [`F_XRP PAY`](Pay.md#action-result): the TEE posts intermediate signed transactions per [fee schedule](../../Transactions.md#fee-schedules) entry, with status climbing through $3, 4, 5, \dots$ and the final entry returning `status = 1` under `submissionTag = end`.

Each non-empty result's `data` is the JSON of an XRP Ledger transaction with a populated `Signers` field.