# ReferencedPaymentNonexistence

## Description

Assertion that an agreed-upon payment has not been made by a certain deadline.
A confirmed request shows that a transaction meeting certain criteria (address, amount, reference, sourceAddressesRoot) did not appear in the specified block range.

This type of attestation can be used to, e.g., provide grounds to liquidate funds locked by a smart contract on Flare when a payment is missed.

**Supported sources:** BTC, DOGE, XRP

## Request body

| Field                      | Solidity type | Description                                                                                                           |
| -------------------------- | ------------- | --------------------------------------------------------------------------------------------------------------------- |
| `minimalBlockNumber`       | `uint64`      | The start block of the search range.                                                                                  |
| `deadlineBlockNumber`      | `uint64`      | The blockNumber to be included in the search range.                                                                   |
| `deadlineTimestamp`        | `uint64`      | The timestamp to be included in the search range.                                                                     |
| `destinationAddressHash`   | `bytes32`     | The [standard address hash](./Reference.md#standard-address-hash) of the address to which the payment had to be done. |
| `amount`                   | `uint256`     | The requested amount in minimal units that had to be payed.                                                           |
| `standardPaymentReference` | `bytes32`     | The requested standard payment reference.                                                                             |
| `checkSourceAddresses`     | `bool`        | If true, the source address root is checked (only full match).                                                        |
| `sourceAddressesRoot`      | `bytes32`     | The root of the Merkle tree of the source addresses.                                                                  |

The `standardPaymentReference` should not be zero (as a 32-byte sequence).

## Response body

| Field                         | Solidity type | Description                              |
| ----------------------------- | ------------- | ---------------------------------------- |
| `minimalBlockTimestamp`       | `uint64`      | The timestamp of the minimalBlock.       |
| `firstOverflowBlockNumber`    | `uint64`      | The height of the firstOverflowBlock.    |
| `firstOverflowBlockTimestamp` | `uint64`      | The timestamp of the firstOverflowBlock. |

`firstOverflowBlock` is the first block that has block number higher than `deadlineBlockNumber` and timestamp later than `deadlineTimestamp`.
The specified search range are blocks between heights including `minimalBlockNumber` and excluding `firstOverflowBlockNumber`.

## Lowest Used Timestamp

For `lowestUsedTimestamp`, `minimalBlockTimestamp` is used.

## Verification

If zero `standardPaymentReference` is provided, the request is rejected.

If `firstOverflowBlock` cannot be determined or does not have a sufficient number of confirmations (block at the tip has number of confirmations 1), the attestation request is rejected.
If `minimalBlockNumber` is higher or equal to `firstOverflowBlockNumber`, the request is rejected.
The search range are blocks between heights including `minimalBlockNumber` and excluding `firstOverflowBlockNumber`.
If the verifier does not have a view of all blocks from `minimalBlockNumber` to `firstOverflowBlockNumber`, the attestation request is rejected.
The request is confirmed if no transaction meeting the specified criteria is found in the search range.
The criteria and timestamp are chain specific.

### UTXO (Bitcoin and Dogecoin)

For Bitcoin, the sufficient number of confirmations is at least 6, for Doge it is 60.

Criteria for the transaction:

- It is not coinbase transaction.
- The transaction has the specified [standardPaymentReference](./Reference.md#standard-payment-reference).
- The transaction has exactly one output with the specified address.
- The value of the output with the specified address minus the sum of values of all inputs with the specified address is greater than `amount` (in practice the sum of all values of the inputs with the specified address is zero).
- If `checkSourceAddresses` is set to true, sourceAddressesRoot of the transaction matches the specified `sourceAddressesRoot`.

Timestamp is `mediantime`.

`LowestUsedTimestamp` limit for Bitcoin and Dogecoin is $1209600$ (2 weeks).

### XRPL

For XRPL, the sufficient number of confirmations is at least 3.

Criteria for the transaction:

- The transaction is of type payment.
- The transaction has the specified [standardPaymentReference](./Reference.md#standard-payment-reference),
- One of the following is true:
  - Transaction status is `SUCCESS` and the amount received by the specified destination address is greater than the specified `value`.
  - Transaction status is `RECEIVER_FAILURE` and the specified destination address would receive an amount greater than the specified `value` had the transaction been successful.
- If `checkSourceAddresses` is set to true, sourceAddressesRoot of the transaction matches the specified `sourceAddressesRoot`.

Timestamp is `close_time` converted to UNIX time.

`LowestUsedTimestamp` limit for XRPL is $1209600$ (2 weeks).
