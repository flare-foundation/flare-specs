# FDC Message Encoding Reference
## Attestation Request
| **Field** | **Size (bytes)** | **Description** |
| ------------- | ---------------- | ---------------------------------- |
| attestationType    | 32                | Attestation type identifier.               |
| sourceID.             | 32  | Data source identifier.
| messageIntegrityCode.     | 32 | Hash of expected response.
| requestBody       | Variable    | Main body of request. |
The amount of bytes in the requestBody field will vary dependent on the attestation type.
## Attestation Response

| **Field** | **Size (bytes)** | **Description** |
| ------------ | ---------------- | ------------------------------ |
| attestationType   | 32                | Attestation type identifier.           |
| sourceId      | 32                | Data source identifier.         |
| votingRound | 8                | Current voting round |
| lowestUsedTimestamp         | 8               | Unix timestamp of earliest relevant data.              |
| requestBody | Variable | Copied from request. |
| responseBody | Variable | Main body of response. |

The amount of bytes in the requestBody and responseBody field will vary dependent on the attestation type.

## FSP Data Types
The encoding of bit-vote data to the submit2 function of the Submission smart contract and finalization data to the Relay contract use the same structure as in the FSP [reference FSP encoding].