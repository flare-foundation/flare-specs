# Introduction

The Flare Data Connector (FDC) attests to data external to Flare's EVM state, thus providing a guarantee to smart contracts on Flare that the data is valid.
Users submit requests to the FDC to bring specific external data on-chain, and consensus among Flare's data providers is obtained to confirm valid requests.
Once confirmed by the FDC, external data can be used anywhere across the network.
The FDC has protocol ID 200 and a [white paper](https://flare.network/wp-content/uploads/FDC_WP_14012025.pdf).

# Motivation

The EVM can use only two sources of data for computation: the EVM state and transaction input.
The EVM state has a very limited scope, whereas transaction inputs can contain arbitrary data but are completely under the control of the message sender.
As the sender may not act honestly, smart contracts cannot always trust transaction input data.
The FDC allows users on Flare to validate external data via consensus among Flare's providers; data confirmed in this way can be trusted as legitimate transaction data on Flare, as both the data and the network itself are secured by the same data providers.

## An Example Use Case

Imagine that a user needs to prove the existence of a Bitcoin transaction which was made as a payment for some service managed by a smart contract on the Flare network.
The transaction consists of a payment of 1 BTC to a specific Bitcoin address.
The FDC facilitates this process in a trustworthy manner, allowing the user to prove the existence of the transaction to the smart contract on Flare, without the contract having to trust the user.
The process is described below.

First, the user would submit a request on Flare to the contract for access to the service.
The smart contract would then issue a requirement that the user pays 1 BTC to a specified Bitcoin address.
The user would carry out this payment on Bitcoin, producing a transaction with transaction ID `XYZ`.

With the transaction made, the user would then submit a [request](./MakingRequest.md) to the FDC to attest to the transaction by submitting an attestation request of type [Payment](./AttestationTypes/Payment.md) to the FDCHub smart contract.
The request is batched together with other requests made at a similar time, and these requests are processed by Flare's data providers.
Assuming that the request is confirmed, the hash of the attestation data is included in the next Merkle tree published by the FDC, whose root is stored on the Relay contract.

Once the transaction is attested to by the FDC, the user can submit the attestation data for the `XYZ` transaction to the original smart contract together with the [Merkle proof](../Utilities/MerkleTree.md#merkle-proof), which shows that the existence of the transaction was confirmed by the FDC.
The attestation data and the Merkle proof can be obtained from [Data Availability Layer](../FSP/DataAvailability.md) of any trusted provider.
The contract can check the attestation data against its requirements (e.g. that 1 BTC was sent to the specified receiving address, and that this was performed within the expected time window), and then use the FDCVerification contract to confirm that the Merkle proof is valid.
If all checks pass, the contract has a proof that the payment was made and it can unlock the service for the user.
