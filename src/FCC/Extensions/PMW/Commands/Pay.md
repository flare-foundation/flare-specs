# F_XRP PAY

## Description

Signs an XRP Ledger multisig payment from a PMW wallet using one or more TEE-managed private keys.
Emitted as an instruction when a user calls [`TeePayments.pay`](../Transactions.md#submitting-a-payment) (directly or through a batched call from the same wallet).

- If `amount = 0` and the recipient address equals the sender, the TEE signs an empty `AccountSet` (nullification) transaction; the payment reference is still attached. See [Nullification](../Transactions.md#nullification).
- If `tokenId` is zero-valued, the transaction is a direct XRP payment. Other token IDs are reserved for future use.
- `sourceId` is `XRP` or `testXRP`.

## Event Message

[`PaymentInstructionMessage`](../../../Types/Abi/Payment.md#paymentinstructionmessage), referencing [`TeeIdKeyIdPair`](../../../Types/Abi/Common.md#teeidkeyidpair).

`feeSchedule` carries the [encoded fee-schedule entries](../Transactions.md#encoded-format); it must be non-empty.

## Fixed Message

None.

## Variable Message

None.

## Additional Action Data

None.

## Action Result

`F_XRP PAY` is asynchronous: the TEE machine returns an empty placeholder on the `threshold` submission tag, then posts one signed transaction per [fee schedule](../Transactions.md#fee-schedules) entry on its delay schedule.

- `submissionTag = threshold`: empty data, [`ActionResult.status`](../../../Operations/Actions.md#action-results) = $2$ (in-progress).
- Intermediate signed transactions: `status` = $3$, $4$, $5$, … (one per fee entry, monotonically increasing).
- Final signed transaction (last fee entry): `submissionTag = end`, `status` = $1$.

Each non-empty result's `data` is the JSON of an XRP Ledger transaction with a populated `Signers` field.

## Notes

The TEE machine validates the instruction before signing:

- `feeSchedule` is non-empty.
- The machine's own TEE ID appears in `teeIdKeyIdPairs`.
- The key type is `XRP` and the signing algorithm is `sha512half-secp256k1-ecdsa`.
- The key exists on the machine and is in active status.
- [Cosigner](../../../Operations/Instructions.md#cosigners) signatures are verified per key when the wallet has cosigners configured.
