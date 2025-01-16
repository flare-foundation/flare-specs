# Payment

## Description

A relay of a transaction on an external chain that is considered a payment in a native currency.
Various blockchains support different types of native payments.
For each blockchain, it is specified how a payment transaction should be formed to be provable by this attestation type.
The provable payments emulate traditional banking payments from entity A to entity B in native currency with an optional payment reference.

**Supported sources:** BTC, DOGE, XRP

## Request body

| Field           | Solidity type | Description                                                                                                            |
| --------------- | ------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `transactionId` | `bytes32`     | ID of the transaction.                                                                                                 |
| `inUtxo`        | `uint256`     | For UTXO chains, this is the index of the transaction input with source address. Always 0 for the non-utxo chains.     |
| `utxo`          | `uint256`     | For UTXO chains, this is the index of the transaction output with receiving address. Always 0 for the non-utxo chains. |

## Response body

| Field                          | Solidity type | Description                                                                                                                                                                                     |
| ------------------------------ | ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `blockNumber`                  | `uint64`      | Number of the block in which the transaction is included.                                                                                                                                       |
| `blockTimestamp`               | `uint64`      | The timestamp of the block in which the transaction is included.                                                                                                                                |
| `sourceAddressHash`            | `bytes32`     | Standard address hash of the source address.                                                                                                                                                    |
| `sourceAddressesRoot`          | `bytes32`     | The root of the Merkle tree of the source addresses.                                                                                                                                            |
| `receivingAddressHash`         | `bytes32`     | Standard address hash of the receiving address. The zero 32-byte string if there is no receivingAddress (if `status` is not success).                                                           |
| `intendedReceivingAddressHash` | `bytes32`     | Standard address hash of the intended receiving address. Relevant if the transaction is unsuccessful.                                                                                           |
| `spentAmount`                  | `int256`      | Amount in minimal units spent by the source address.                                                                                                                                            |
| `intendedSpentAmount`          | `int256`      | Amount in minimal units to be spent by the source address. Relevant if the transaction status is unsuccessful.                                                                                  |
| `receivedAmount`               | `int256`      | Amount in minimal units received by the receiving address.                                                                                                                                      |
| `intendedReceivedAmount`       | `int256`      | Amount in minimal units intended to be received by the receiving address. Relevant if the transaction is unsuccessful.                                                                          |
| `standardPaymentReference`     | `bytes32`     | [Standard payment reference](/specs/attestations/external-chains/standardPaymentReference.md) of the transaction. If the transaction has no reference, zero value is returned.                  |
| `oneToOne`                     | `bool`        | Indicator whether only one source and one receiver are involved in the transaction.                                                                                                             |
| `status`                       | `uint8`       | [Success status](/specs/attestations/external-chains/transactions.md#transaction-success-status) of the transaction: 0 - success, 1 - failed by sender's fault, 2 - failed by receiver's fault. |

## Lowest Used Timestamp

For `lowestUsedTimestamp`, `blockTimestamp` is used.

## Verification

The transaction with `transactionId` is fetched from the relevant source.
If the transaction cannot be fetched or the transaction is in a block that does not have a sufficient number of confirmations, the attestation request is rejected.
Relevant fields are extracted from the transaction.

**IMPORTANT** As the field `standardPaymentReference` is set to zero value if the transaction has no standard payment reference, zero value should not be used as a valid by the smart contracts.

### Bitcoin and Dogecoin

For Bitcoin a sufficient number of confirmations is at least 6, for Dogecoin it is 60.

`BlockTimestamp` is the mediantime of the block in which the transaction is included.

If the inducted input or output does not exist, the request is rejected.
Both the indicated input and output must have an address (they must have a standard locking script), otherwise no summary is made.
In particular, requests for coinbase transactions are rejected.

Any transaction included in the block is successful, thus the `status` is always 0.

`SourceAddressHash` is the standard address hash of the address of the indicated input.
`SpentAmount` is the sum of values of all inputs with `sourceAddress` minus the sum of values of all outputs with `sourceAddress`.
`IntendedSpentAmount` always matches the `spentAmount`.

`ReceivingAddressHash` is the standard address hash of the address of the indicated output.
`ReceivedAmount` is the sum of values of all outputs with the `receivingAddress` minus the sum of values of all inputs with `receivingAddress`.
`IntendedReceivedAmount` always matches `ReceivedAmount` and `intendedReceivingAddress` always matches `receivingAddress`.

A transaction is `oneToOne` if and only if there are only inputs with `sourceAddress` and outputs consist only of UTXOs wiring to `receivingAddress`, `sourceAddress` (returning the change) or are `OP_RETURN`.

`LowestUsedTimestamp` limit for Bitcoin and Dogecoin is $1209600$ (2 weeks).

### XRPL

Only transactions of type [`Payment`](https://xrpl.org/docs/references/protocol/transactions/types/payment) are considered.
If a transaction is of a different type, the request is rejected.

`BlockTimestamp` is close time of the ledger converted to UNIX time.

On XRPL, some transactions that failed (based on the reason for failure) can be included in a confirmed block.
The [success of the transaction](https://xrpl.org/look-up-transaction-results.html#case-included-in-a-validated-ledger) included in a confirmed block is described by the `TransactionResult` field.
A successful transaction is labeled by `tesSUCCESS`.
If a transaction fails but is included in a block, the [`tec`-class](https://xrpl.org/tec-codes.html) code is used to indicate the reason for the failure.
The following codes indicate a failure that was the receiver's fault:

- `tecDST_TAG_NEEDED`: A destination tag is required by the target address, but is not provided. **IMPORTANT**: tagging this as the receiver's fault means that payment attestation type does not (fully) support transactions that require a destination tag.
- `tecNO_DST`: This failure is considered to be the receiver's fault if the specified address does not exist or is unfunded.
- `tecNO_DST_INSUF_XRP`: This failure is considered to be the receiver's fault if the specified address does not exist or is unfunded.
- `tecNO_PERMISSION`: The source address does not have permission to transfer the target address. **IMPORTANT**: tagging this as the receiver's fault means that payment attestation type does not (fully) support transactions to the accounts that require "DepositAuth".

The rest of the tags indicate the sender's fault.

In transactions of type Payment, there is exactly one sender and at most one receiver.
If a transaction is not successful, there is no receiver.
If it is successful, there is exactly one receiver.
Thus the transaction is always `oneToOne`.

`SpentAmount` is the value for which the balance of the `sourceAddress` has been lowered.
`IntendedSpentAmount` is `Amount + Fee` of the transaction.
It is the same as `spentAmount` if the `transactionStatus` is `SUCCESS`.

`ReceivingAddress` is the address whose balance has been increased by the transaction.
`ReceivedAmount` is the value for which the balance of the `receivingAddress` has been increased.
`IntendedReceivingAddress` is the Destination of the transaction.
`IntendedReceivedAmount` is `Amount` of the transaction.

`LowestUsedTimestamp` limit for XRPL is $1209600$ (2 weeks).
