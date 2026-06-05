# XRPPaymentNonexistence

## Description

Assertion that an agreed-upon XRP payment has not been made by a certain deadline.
A confirmed request shows that a transaction meeting certain criteria (address, amount, reference) did not appear in the specified block range on the XRPL chain.

This type of attestation can be used to, e.g., provide grounds to liquidate funds locked by a smart contract on Flare when a payment is missed.

**Supported sources:** XRP

## Request body

| Field                      | Solidity type | Description                                                                                                           |
| -------------------------- | ------------- | --------------------------------------------------------------------------------------------------------------------- |
| `minimalBlockNumber`       | `uint64`      | The start block of the search range.                                                                                  |
| `deadlineBlockNumber`      | `uint64`      | The blockNumber to be included in the search range.                                                                   |
| `deadlineTimestamp`        | `uint64`      | The timestamp to be included in the search range.                                                                     |
| `destinationAddressHash`   | `bytes32`     | The [standard address hash](./Reference.md#standard-address-hash) of the address to which the payment had to be done. |
| `amount`                   | `uint256`     | The requested amount in minimal units that had to be paid.                                                           |
| `checkFirstMemoData` | `bool`     | Whether or not to consider the firstMemoDataHash field in the search. Note that at least one of `checkFirstMemoData` (this field) or `checkDestinationTag` must be set to true.                                                                             |
| `firstMemoDataHash` | `bytes32`     | Hash of the MemoData field of the first Memo in the transaction.                                                                             |
| `checkDestinationTag`     | `bool`        | Whether or not to consider the destinationTag field in the search.                                                        |
| `destinationTag` | `uint32`     | Destination tag of the transaction.                                                                             |
| `proofOwner`      | `address`     | The owner of the proof, which applications can use to determine which address is permitted to submit the proof. Setting this address to the 0 address indicates that any address should be permitted to use the proof.                                                                  |

## Response body

| Field                         | Solidity type | Description                              |
| ----------------------------- | ------------- | ---------------------------------------- |
| `minimalBlockTimestamp`       | `uint64`      | The timestamp (`close_time` converted to UNIX time) of the minimalBlock.       |
| `firstOverflowBlockNumber`    | `uint64`      | The height of the firstOverflowBlock.    |
| `firstOverflowBlockTimestamp` | `uint64`      | The timestamp (`close_time` converted to UNIX time) of the firstOverflowBlock. |

`firstOverflowBlock` is the first block that has block number higher than `deadlineBlockNumber` and timestamp later than `deadlineTimestamp`.
The specified search range are blocks between heights including `minimalBlockNumber` and excluding `firstOverflowBlockNumber`.

## Lowest Used Timestamp

For `lowestUsedTimestamp`, `minimalBlockTimestamp` is used.
The `lowestUsedTimestamp` limit is $1209600$ (2 weeks).

## Verification

If `firstOverflowBlock` cannot be determined or does not have a sufficient number of confirmations, defined as at least 3 (block at the tip has number of confirmations 1), the request is rejected.
If `minimalBlockNumber` is higher or equal to `firstOverflowBlockNumber`, the request is rejected.
The search range are blocks between heights including `minimalBlockNumber` and excluding `firstOverflowBlockNumber`.
If the verifier does not have a view of all blocks from `minimalBlockNumber` to `firstOverflowBlockNumber`, the request is rejected.
If both `checkFirstMemoData` and `checkDestinationTag` are false, the request is rejected
The request is confirmed if no transaction meeting the specified criteria is found in the search range.

Criteria for the transaction:

- The transaction is of type `Payment` and sends and receives XRP.
- The transaction has the specified first memo data hash and/or destination tag, as determined by the `bool` fields in the request body.
- One of the following is true:
  - Transaction status is `SUCCESS` (`TransactionResult` is `tesSUCCESS`)and the amount received by the specified destination address is greater than the specified `value`.
  - Transaction status is `RECEIVER_FAILURE` (`TransactionResult` is one of `tecDST_TAG_NEEDED`, `tecNO_DST`, or `tecNO_DST_INSUF_XRP`, or is `tecNO_PERMISSION` while the transaction has no `DomainID`) and the specified destination address would receive an amount greater than the specified `value` had the transaction been successful.