# FDC Introduction

Flare Data Connector (FDC) attests to data external to the Flare's EVM state, thus provide a guarantee to smart contracts on Flare the data is valid.

FDC has protocol ID 200.

FDC also has a [white paper](https://flare.network/wp-content/uploads/FDC_WP_14012025.pdf).

## Motivation

EVM can use only two sources of data for computation: EVM state and transaction input. The EVM state has a very limited scope.
Transaction input can contain arbitrary data but is completely under the control of the message sender, thus the smart contract cannot always trust it.

## A Use Case

Imagine that the transaction is a payment for some service managed by a smart contract on the **Flare** network, for which one needs to pay 1 BTC to a specific Bitcoin address.
In the full workflow, the user would first request the contract for access to the service.
The smart contract would then issue a requirement to pay 1 BTC to a specified address.
The user would carry out a payment on Bitcoin, producing a transaction with transaction ID `XYZ`.
Then it would [request](./MakingRequest.md) the FDC to attest to the transaction by submitting an attestation request of type [Payment](./AttestationTypes/Payment.md) to the FDCHub smart contract.

The request is batched with other requests and processed by the providers.
If the request is confirmed, the hash of the attestation data is included in the Merkle tree whose root is stored on the Relay contract.

If the transaction is attested by the FDC, the user can submit the attestation data for the `XYZ` transaction to the contract together with the [Merkle proof](../Utilities/MerkleTree.md#merkle-proof), which shows that the transaction was indeed attested to.
The attestation data and the Merkle proof can be obtained from [Data Availability Layer](../FSP/DataAvailability.md) of any trusted provider.

The contract would check the attestation data against its requirements (e.g., 1 BTC is required to be sent to the specified receiving address, within the expected time window, etc.).
Then it would calculate the [hash](AttesationType.md#attestation-hash) of the provided attestation data and use the provided Merkle proof to compare it against the confirmed Merkle root stored on the Relay smart contract through FdcVerification smart contract.
If everything matches, the contract has a proof that the payment was made and it can unlock the service for the user.
