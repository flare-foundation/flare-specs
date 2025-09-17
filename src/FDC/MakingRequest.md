# Attestation Requests

The FDC is a request-based protocol, bringing external data on to Flare in response to valid requests made by users.
This section summarizes how to format and submit a request to the FDC.

## Request Format

An attestation request consists of the data to be brought on chain, information about where the data can be found, the expected response, and a fee.
Attestations must conform to one of the pre-defined types, known as _attestation types_, which will be explained later in this section.
Formally, an attestation request is a byte sequence encoding of the following structure:

- attestationType - (32 bytes) attestation type identifier (ATI).
  States which attestation type the request is of.
- sourceId - (32 bytes) data source identifier (DSI).
  Unambiguously identifies the origin data source.
  For example, if the data is the existence of a specific BTC transaction, the DSI will specify the Bitcoin blockchain.
- messageIntegrityCode - (32 bytes) message integrity code (MIC).
  A hash of the expected response salted with the default string "Flare".
- requestBody - Solidity struct containing the data of the request body.
  The definition of the struct depends on the attestation type.

Additionally, each attestation request must be submitted with a fee.
This fee will be awarded to providers if the request is confirmed; if not, it is burnt.
The size of the fee is at the discretion of the user, except that it must exceed a minimum amount for the attestation type and data source, a parameter set by governance.
The minimum fee can be queried by users on the `FdcRequestFeeConfigurations` smart contract.
Larger fees increase the chance of requests being responded to in the round, particularly for requests that not all data providers may be able to respond to.
See [BitVote](./BitVote.md) for more details.

## Attestation Types

A well-defined attestation type consists of a request format, response format, and verification rules.
Request and response formats are defined by Solidity structs.

### Identifiers

The attestation type identifier (ATI) and data source identifier (DSI) are 32-byte strings.
Each attestation type and data source has its name, which can be at most 32 characters long and can only consist of lower and uppercase ASCII letters and numbers.
For example, one attestation type is named "Payment". When encoded into a 32-byte lowercase hex string, the string is taken in ASCII bytes and then padded on the right with zeros.
For example, the identifier of the attestation type "Payment" is 0x5061796d656e7400000000000000000000000000000000000000000000000000.

The same procedure applies to data source identifiers.
For example, when using Bitcoin mainnet as a data source, it is identified by the name "BTC" with identifier 0x4254430000000000000000000000000000000000000000000000000000000000.

### Message Integrity Code

In order to ensure that there is only one valid response to an attestation request, a Message Integrity Code (MIC) is derived from the expected response and included in the request.

In Solidity code, the MIC is computed by taking a hash of the ABI encoding of the response and the string "Flare" e.g.

```Solidity
response.votingRound = 0;
bytes32 mic = keccak256(abi.encode(response,"Flare"));
```

For a response to an attestation request to be considered valid, its MIC must match the MIC from the request.

## FDCHub

The FDCHub hosts the function

```Solidity
function requestAttestation(bytes calldata _data) external payable;
```

that accepts encoded requests from users.
It requires that the value sent with the request is greater than or equal to the required minimal fee for the attestation type and source of the request.
If the minimal fee is not configured for the attestation type and source of the request, the request is rejected.

If a request is successfully made an event

```Solidity
event AttestationRequest(bytes data, uint256 fee);
```

is emitted.

## Attestation Response

The format of a response to an attestation request varies by attestation type.
For each type, it is defined by the Solidity struct

```Solidity
struct Response {
 bytes32 attestationType;
 bytes32 sourceId;
 uint64 votingRound;
 uint64 lowestUsedTimestamp;
 RequestBody requestBody;
 ResponseBody responseBody;
}
```

- attestationType - (32 bytes) attestation type identifier (ATI).
- sourceId - (32 bytes) source identifier (DSI).
- votingRound - (8 bytes) voting round in which the attestation was confirmed.
- lowestUsedTimestamp - (8 bytes) the timestamp in Unix epoch format which indicates what was the timestamp of the earliest data that was needed to confirm the response.
  This is explained in further detail below.
- requestBody - copied from the request.
- responseBody - Solidity struct containing the data of the response body.

### Lowest Used Timestamp

The lowestUsedTimestamp (LUT) field contained in an attestation response defines the timestamp of the oldest data needed in verification.
The LUT has to be in unix, and must be uniquely defined by the response.
If the LUT of the response is too low, the data provider should consider the request as invalid.
This occurs when the difference between the LUT of the response and the ending time of the collect phase in which the request was submitted is higher than a specified limit.

Each pair of attestation type and source defines how old the data needed for a response can be.
The limit is provided in seconds.
A pair can have (practically) unlimited LUT, upper bounded to a maximum limit is set to $2^{64}-1$.
If no time stamped data is needed to construct the response, LUT of the response is considered to be $2^{64}-1$.

### Encoding

In Solidity code, the requestBody is encoded by

```Solidity
abi.encode(requestBody);
```

and decoded by

```Solidity
abi.decode(encodedRequestBody, RequestBody);
```

where RequestBody is the Solidity struct defined by the attestation type.
Encoded requests can be submitted to the FDC smart contract.
In the encoded request, the first 96 bytes consist of the concatenated attestationType, sourceId and MIC.
The remainder consists of the encoded requestBody.

In Solidity code, the response is encoded by

```Solidity
abi.encode(response);
```

and decoded by

```Solidity
abi.decode(encodedResponse, Response);
```

where Response is the Solidity struct defined by the attestation type.

## Attestation Hash

For each confirmed attestation request, the hash of its full response, including correctly set voting round, is computed.
This hash is computed in Solidity by the following code:

```solidity
keccak256(abi.encode(response));
```

where the response is a struct of type Response that is defined by the attestation type.
The hashes of the confirmed attestation are used to construct the [Merkle tree](../Utilities/MerkleTree.md) and the Merkle root is used for voting in the voting round.
