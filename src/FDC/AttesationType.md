# Attestation type

An attestation type consists of request format, response format and verification rules. Request and response formats are defined by Solidity structs.

## Request

The attestation request is a byte sequence encoding of the following structure.

- attestationType - (32 bytes) attestation type identifier (ATI).
- sourceId - (32 bytes) data source identifier (DSI). Essentially it unambiguously identifies the core data source (like Bitcoin blockchain).
- messageIntegrityCode - (32 bytes) message integrity code (MIC). A hash of the expected response salted with the default string “Flare”
- requestBody - Solidity struct containing the data of the request body. The definition of the struct depends on the attestation type.

### Identifiers

Attestation type identifier (ATI) and data source identifier (DSI) are 32-byte string defined as follows.
Each attestation type and data source has its name.
The name can only consist of lower and uppercase ASCII letters and numbers (no white spaces etc.) and it can be at most 32 characters long.
For example, one attestation type is named “Payment”.
When encoded to a 32-bytes lowercase hex string, the string is taken in ASCII bytes and then padded on the right with zeros.
For example, the identifier of the attestation type “Payment” is 0x5061796d656e7400000000000000000000000000000000000000000000000000.
The same procedure applies to data source identifiers.
For example, a Bitcoin mainnet as a data source is identified by the name “BTC” with identifier 0x4254430000000000000000000000000000000000000000000000000000000000.

### Message Integrity Code

Message Integrity Code (MIC) is derived from the expected response.
It ensures that at most one response (up to hash collision) is valid.
In Solidity code, MIC is computed by

```Solidity
response.votingRound = 0;
bytes32 mic = keccak256(abi.encode(response,”Flare”));
```

For a response to be considered valid, its MIC must match the MIC from the request.

## Response

The format of the response is defined by the Solidity struct

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
- sourceId - (32 bytes) source identifier
- votingRound - (8 bytes) voting round in which the attestation was confirmed.
  The final value is set by the data provider before including the hash of response into the Merkle tree.
- lowestUsedTimestamp - (8 bytes) the timestamp in Unix epoch format which indicates what was the timestamp of the earliest data that was needed to confirm the response.
- requestBody - copied from the request.
- responseBody - Solidity struct containing the data of the response body.
  The definition of the struct depends on the attestation type.

### Lowest Used Timestamp

Each response contains a field lowestUsedTimestamp (LUT), i.a., the timestamp of the oldest data needed in verification.
LUT has to be in unix.
LUT has to be uniquely defined by the response.
If the LUT of the response is too low, the data provider should consider the request as invalid.
Each pair of attestation type and source define how old the data needed for a response can be.
The limit is provided in seconds.

The response is too old and considered invalid if the difference between the LUT of the response and the ending of the collect phase in which the request was submitted is higher than the specified limit.

A pair can have (practically) unlimited LUT, in this case the limit is set to $2^{64}-1$.
If no time stamped data is needed to construct the response, LUT of the response should be $2^{64}-1$.

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

In the encoded request, the first 96 bytes are concatenated attestationType, sourceId and MIC.
The rest is the encoded requestBody.

In Solidity code, the response is encoded by

```Solidity
abi.encode(response);
```

and decoded by

```Solidity
abi.decode(encodedResponse, Response);
```

where Response is the Solidity struct defined by the attestation type.

## Attestation hash

For each confirmed attestation request, the hash of its full response with correctly set voting round is computed.
In solidity, the hash of the response is computed in Solidity by the following code:

```solidity
keccak256(abi.encode(response));
```

where the response is a struct of type Response that is defined by the attestation type.
Hashes of the confirmed attestation are used to construct the [Merkle tree](../Utilities/MerkleTree.md) and the Merkle root is used for voting in the voting round.
