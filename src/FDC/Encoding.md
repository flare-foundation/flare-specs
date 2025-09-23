# FDC Message Encoding Reference

## AttestationRequest

| **Field**            | **Size (bytes)** | **Description**              |
|----------------------|------------------|------------------------------|
| attestationType      | 32               | Attestation type identifier. |
| sourceID             | 32               | Data source identifier.      |
| messageIntegrityCode | 32               | Hash of expected response.   |
| requestBody          | Variable         | Main body of request.        |

The amount of bytes in the requestBody field will vary dependent on the attestation type.

## AttestationResponse

| **Field**           | **Size (bytes)** | **Description**                           |
|---------------------|------------------|-------------------------------------------|
| attestationType     | 32               | Attestation type identifier.              |
| sourceId            | 32               | Data source identifier.                   |
| votingRound         | 8                | Current voting round.                     |
| lowestUsedTimestamp | 8                | Unix timestamp of earliest relevant data. |
| requestBody         | Variable         | Copied from request.                      |
| responseBody        | Variable         | Main body of response.                    |

The amount of bytes in the requestBody and responseBody field will vary dependent on the attestation type.

## BitVote

Variable size, to be used as `Payload` in a [PayloadMessage](../FSP/Encoding#payloadmessage).

| **Field** | **Size (bytes)** | **Description**                                                                                                                                  |
|-----------|------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| Size      | 2                | Number of attestations. Expected number of _bits_ in `BitVector`.                                                                                |
| BitVector | Variable         | Big-endian byte sequence. Vote indices start at LSB of the last byte in the sequence. The number of bytes can be no greater than `ceil(Size/8)`. |