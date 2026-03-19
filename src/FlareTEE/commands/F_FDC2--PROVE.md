# F_FDC2 PROVE

## Description

Collects signatures of attestation responses. The PROVE instruction can be issued for any attestation type supported by the FDC verifier infrastructure. A new version (v2) of Flare Data Connector (FDC) is implemented using PMW infrastructure. It leverages the format and verifier infrastructure of the existing FDC. Attestation requests are submitted through the [FtdcHub](../Smart%20Contracts.md#ftdchub-teedataconnector) smart contract.

## Event message

```solidity
// Source: IFtdcHub.sol
struct FtdcAttestationRequest {
    FtdcRequestHeader header; // request header
    bytes requestBody;        // attestation request body
}

struct FtdcRequestHeader {
    bytes32 attestationType; // attestation type identifier
    bytes32 sourceId;        // source chain identifier
    uint16 thresholdBIPS;    // threshold in BIPS for considering proving successful
}
```

Additionally, the instruction event includes:

- `teeIds` -- list of TEE ids on which the voting is carried out
- `cosigners` -- (optional) list of cosigner addresses
- `cosignersThreshold` -- (optional) cosigners threshold. A TEE machine signs the attestation response only if both data providers and cosigners achieve their respective thresholds.

## Fixed message

- `attestationResponse` -- attestation response, validated against the request by each data provider

## Variable message

- `signature` -- signature by data provider of the attestation response only

## Additional action data

/

## Action result

```go
// Source: tee-node/pkg/ftdc/ftdc.go
type ProveResponse struct {
    ResponseHeader         hexutil.Bytes   // ABI encoded FtdcResponseHeader
    RequestBody            hexutil.Bytes   // original request body
    ResponseBody           hexutil.Bytes   // attestation response body
    TEESignature           hexutil.Bytes   // TEE machine signature of the message hash
    CosignerSignatures     []hexutil.Bytes // cosigner signatures
    DataProviderSignatures hexutil.Bytes   // signing policy signatures in relay format
}
```

The response header structure:

```solidity
// Source: IFtdcHub.sol
struct FtdcResponseHeader {
    bytes32 attestationType;   // attestation type
    bytes32 sourceId;          // source chain id
    uint16 thresholdBIPS;      // threshold in BIPS
    address[] cosigners;       // cosigner addresses
    uint64 cosignersThreshold; // cosigners threshold
    uint64 timestamp;          // timestamp of the response
}
```
