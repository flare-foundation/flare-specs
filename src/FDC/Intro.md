# Introduction

Flare Data Connector (FDC) attests to data external to the Flare's EVM state, thus provide a guarantee to smart contracts on Flare that data is valid.

FDC has protocol ID 200.

FDC also has a [white paper](https://flare.network/wp-content/uploads/FDC_WP_14012025.pdf)

## How FDC works

## A Use Case

Imagine that the transaction is a payment for some service managed by a smart contract on the **Flare** network, for which one needs to pay 1 BTC to a specific Bitcoin address.
In the full workflow, the user would first request the contract for access to the service.
The smart contract would then issue a requirement to pay 1 BTC to a specified address.
The user would carry out a payment on Bitcoin, producing a transaction with transaction ID `XYZ`.
Then it would request the FDC to attest to the transaction.

If the transaction is attested by the FDC, the user can submit the attestation data for the `XYZ` transaction to the contract together with the Merkle proof, which shows that the transaction was indeed attested to.
The contract would check the attestation data against its requirements (e.g., 1 BTC is required to be sent to the specified receiving address, within the expected time window, etc.).
Then it would calculate the hash of the provided attestation data and use the provided Merkle proof to compare it against the confirmed Merkle root stored on the [Relay contract]().
If everything matches, the contract has a proof that the payment was made and it can unlock the service for the user.

For a more detailed workflow, see [here](/specs/scProtocol/verification-workflow.md)
