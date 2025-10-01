# BalanceDecreasingTransaction

## Description

A detection of a transaction that either decreases the balance for some address or is signed by the source address.
Such an attestation could prove a violation of an agreement and therefore provides grounds to liquidate some funds locked by a smart contract on Flare.
A transaction is considered “balance decreasing” for the address, if the balance after the transaction is lower than before or the address is among the initiators of the transaction (even if its balance is not lower than before the transaction).

**Supported sources:** BTC, DOGE, XRP

## Request body

| Field                    | Solidity type | Description                                                    |
| ------------------------ | ------------- | -------------------------------------------------------------- |
| `transactionId`          | `bytes32`     | ID of the transaction.                                         |
| `sourceAddressIndicator` | `bytes32`     | The indicator of the address whose balance has been decreased. |

## Response body

| Field                      | Solidity type | Description                                                                                    |
| -------------------------- | ------------- | ---------------------------------------------------------------------------------------------- |
| `blockNumber`              | `uint64`      | The number of the block in which the transaction is included.                                  |
| `blockTimestamp`           | `uint64`      | The timestamp of the block in which the transaction is included.                               |
| `sourceAddressHash`        | `bytes32`     | Standard address hash of the address indicated by the `sourceAddressIndicator`.                |
| `spentAmount`              | `int256`      | Amount spent by the source address in minimal units.                                           |
| `standardPaymentReference` | `bytes32`     | Standard payment reference of the transaction. Zero value if the transaction has no reference. |

## Lowest Used Timestamp

For `lowestUsedTimestamp`, `blockTimestamp` is used.

## Verification

The transaction with `transactionId` is fetched from the API of the source blockchain node or relevant indexer.
If the transaction cannot be fetched or the transaction is in a block that does not have a sufficient [number of confirmations](./Reference.md#confirmation-number), the attestation request is rejected.
Once the transaction is received, the response fields are extracted if the transaction is balance decreasing for the indicated address.

### UTXO (Bitcoin and Dogecoin)

- `sourceAddressIndicator` is the [standard address hash](./Reference.md#standard-address-hash) of the address whose balance has been decreased.
  If the address indicated by `sourceAddressIndicator` is not among the signers of the transaction and the balance of the address was not lowered in the transaction, the attestation request is rejected.

- `spentAmount` is the sum of values of all inputs with `sourceAddress` minus the sum of all outputs with `sourceAddress`.
  Can be negative.
- `blockTimestamp` is the mediantime of a block.

`LowestUsedTimestamp` limit for Bitcoin and Dogecoin is $1209600$ (2 weeks).

### XRPL

- `sourceAddressIndicator` is the [standard address hash](./Reference.md#standard-address-hash) of the address whose balance has been decreased.
  If the address indicated by `sourceAddressIndicator` is not the account that initiated the transaction and the balance of the address was not lowered in the transaction, the attestation request is rejected.
- `spentAmount` is the difference between the balance of the indicated address after and before the transaction.
  Can be negative.
- `blockTimestamp` is the close_time of a ledger converted to unix time.
- `standardPaymentReference` is zero-valued for transactions of type other than `Payment`.

`LowestUsedTimestamp` limit for Bitcoin and Dogecoin is $1209600$ (2 weeks).
