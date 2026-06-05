# XRPPayment

## Description

A relay of a transaction on the XRPL chain that is of type payment in native currency (XRP).
A specialized version of the Payment Attestation Type for XRP transactions.
The provable payments emulate traditional banking payments from entity A to entity B with an optional payment reference.

**Supported sources:** XRP

## Request body

| Field           | Solidity type | Description                                                                                                            |
| --------------- | ------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `transactionId` | `bytes32`     | ID of the transaction.                                                                                                 |
| `proofOwner`        | `address`     | The owner of the proof, which applications can use to determine which address is permitted to submit the proof. Setting this address to the 0 address indicates that any address should be permitted to use the proof.    |

## Response body

| Field                          | Solidity type | Description                                                                                                                                                                                     |
| ------------------------------ | ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `blockNumber`                  | `uint64`      | Number of the block in which the transaction is included.                                                                                                                                       |
| `blockTimestamp`               | `uint64`      | The timestamp (`close_time` converted to UNIX time) of the block in which the transaction is included.                                                                                                                               |
| `sourceAddress`            | `string`     | The source address.                                                                                                                                 |
| `sourceAddressHash`            | `bytes32`     | Standard address hash of the source address.                                                                                                                                                    |
| `receivingAddressHash`         | `bytes32`     | Standard address hash of the receiving address. The zero 32-byte string if there is no receivingAddress (if `status` is not success).                                                           |
| `intendedReceivingAddressHash` | `bytes32`     | Standard address hash of the intended receiving address. Relevant if the transaction is unsuccessful.                                                                                           |
| `spentAmount`                  | `int256`      | Amount in minimal units spent by the source address.                                                                                                                                            |
| `intendedSpentAmount`          | `int256`      | Amount in minimal units to be spent by the source address. Relevant if the transaction status is unsuccessful.                                                                                  |
| `receivedAmount`               | `int256`      | Amount in minimal units received by the receiving address.                                                                                                                                      |
| `intendedReceivedAmount`       | `int256`      | Amount in minimal units intended to be received by the receiving address. Relevant if the transaction is unsuccessful.                                                                          |
| `hasMemoData`     | `bool`     | True if the first Memo item in the transaction has a MemoData field, false otherwise.                   |
| `firstMemoData`              |`bytes`        | Raw bytes of the MemoData field of the first Memo in the transaction; empty if no Memo is present.                                                                                                             |
| `hasDestinationTag`     | `bool`     |   True if the transaction has a destination tag, false otherwise.                |
| `destinationTag`                     | `uint32`        |    The Destination tag of the transaction; 0 if no destination tag is present.                                                              
| `status`                       | `uint8`       | Success status of the transaction: 0 - success, 1 - failed by sender's fault, 2 - failed by receiver's fault. |

## Lowest Used Timestamp

For `lowestUsedTimestamp`, `blockTimestamp` is used.
The `lowestUsedTimestamp` limit is $1209600$ (2 weeks).

## Verification

The transaction with `transactionId` is fetched from the XRPL chain.
If the transaction cannot be fetched or the transaction is in a block that does not have a sufficient number of confirmations, the attestation request is rejected.
Relevant fields are extracted from the transaction.

Only transactions of type [`Payment`](https://xrpl.org/docs/references/protocol/transactions/types/payment) that send and receive XRP are considered.
If a transaction is of a different type, or does not send XRP, the request is rejected.

On XRPL, some transactions that failed (based on the reason for failure) can be included in a confirmed block.
The [success of the transaction](https://xrpl.org/look-up-transaction-results.html#case-included-in-a-validated-ledger) included in a confirmed block is described by the `TransactionResult` field.
A successful transaction is labeled by `tesSUCCESS`.
If a transaction fails but is included in a block, the [`tec`-class](https://xrpl.org/tec-codes.html) code is used to indicate the reason for the failure.
The following codes indicate a failure that was the receiver's fault:

- `tecDST_TAG_NEEDED`: A destination tag is required by the target address, but is not provided. **IMPORTANT**: tagging this as the receiver's fault means that payment attestation type does not (fully) support transactions that require a destination tag.
- `tecNO_DST`: This failure is considered to be the receiver's fault if the specified address does not exist or is unfunded and the transaction has no field DomainID.
- `tecNO_DST_INSUF_XRP`: This failure is considered to be the receiver's fault if the specified address does not exist or is unfunded.
- `tecNO_PERMISSION`: This failure is considered to be the receiver's fault only if the transaction has no domainID. **IMPORTANT**: tagging this as the receiver's fault means that payment attestation type does not (fully) support transactions to the accounts that require "DepositAuth".

The rest of the tags indicate the sender's fault.

`SpentAmount` is the value for which the balance of the `sourceAddress` has been lowered.
`IntendedSpentAmount` is `Amount + Fee` of the transaction.
It is the same as `spentAmount` if the `transactionStatus` is `SUCCESS`.

`ReceivingAddress` is the address whose balance has been increased by the transaction.
`ReceivedAmount` is the value for which the balance of the `receivingAddress` has been increased.
`IntendedReceivingAddress` is the Destination of the transaction.
`IntendedReceivedAmount` is `Amount` of the transaction.