# Submission

Sub-protocol data submissions and provider communication in FSP are facilitated by a specialized `Submission` smart contract.
It contains a subsidy mechanism to refund gas costs for depositing protocol message transactions to registered entities.
This logic is embedded at the validator node level.

To save on gast costs and support higher protocol data throughput, the `Submission` contract does not record data on-chain in the traditional sense.
Instead, it provides a set of placeholder functions (`submitX`) with no parameters as markers, and providers are expected to attach protocol message payloads as additional (very cheap gas-wise) calldata in their transactions.

This data is not accessible by smart contracts, but can be obtained by retrieving and processing raw submitted transactions. 

The provided functions are as follows:
- `submit1()` and `submit2()`: for protocol phase-specific data. For example, and `submit1()` is used for FTSO round commit hashes, `submit2()` for revealing committed data.
- `submit3()`: reserved for future use.
- `submitSignatures()`: for signatures for finalization.

Submission transaction calldata is expected to be constructed in the following way:

```tx_data = function_selector + payload```

where `payload` is a concatenation of byte-encoded [PayloadMessage](/src/FSP/Encoding.md#payloadmessage)s.
It is expected that the transaction will contain one payload message per protocol ID. 
If there is more than one message for a protocol, only the last one in the sequence will be considered.

## Submit1, submit2

Entities are expected to submit data to these functions from their registered `submitAddress`.
The first submission in a voting round to a method from the `submitAddress` of an entity included in the active signing policy is subsidized (all gas cost is refunded).
Transactions from addresses not recognised by the active signing policy are not subsidized and should be ignored by protocols.

## SubmitSignatures

Signatures are used for finalizing a protocol voting round. For a successful [finalization](Finalization.md), a Merkle root backed by signatures with enough voter weight is required.

Entities are expected to submit data to this function from their registered `submitSignaturesAddress`.
The first submission in a voting round to a method from the `submitSignaturesAddress` of an entity included in the active signing policy is subsidized (all gas cost is refunded).
Transactions from addresses not recognised by the active signing policy are not subsidized and should be ignored by protocols.

Each submitted [PayloadMessage](/src/FSP/Encoding.md#payloadmessage) is expected to contain either a [SignatureType0](/src/FSP/Encoding.md#signaturetype0) or a [SignatureType1](/src/FSP/Encoding.md#signaturetype1) message, which
[signs](../Utilities/Signing.md) the protocol voting round result – a [ProtocolMerkleRoot](/src/FSP/Encoding.md#protocolmerkleroot).