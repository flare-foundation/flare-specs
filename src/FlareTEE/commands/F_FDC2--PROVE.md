# F_FDC2 PROVE

## Description

Collects signatures of attestation responses. The PROVE instruction can be issued for any attestation type supported by the FDC verifier infrastructure. A new version (v2) of Flare Data Connector (FDC) is implemented using PMW infrastructure. It leverages the format and verifier infrastructure of the existing FDC. Attestation requests are submitted through the `Fdc2Hub` smart contract.

## Event message

```solidity
// Source: IFdc2Hub.sol
struct Fdc2AttestationRequest {
    Fdc2RequestHeader header; // request header
    bytes requestBody;        // attestation request body
}

struct Fdc2RequestHeader {
    bytes32 attestationType; // attestation type identifier
    bytes32 sourceId;        // source chain identifier
    uint16 thresholdBIPS;    // threshold in BIPS for considering proving successful
    address proofOwner;      // address that owns the proof (zero address for public proofs)
}
```

Additionally, the instruction event includes:

- `teeIds` — list of TEE IDs on which the voting is carried out.
- `cosigners` — (optional) list of cosigner addresses.
- `cosignersThreshold` — (optional) cosigners threshold. A TEE machine signs the attestation response only if both data providers and cosigners achieve their respective thresholds.

## Fixed message

- `attestationResponse` — attestation response, validated against the request by each data provider.

## Variable message

- `signature` — signature by data provider of the attestation response only.

## Additional action data

/

## Action result

```go
// Source: tee-node/pkg/fdc/fdc.go
type ProveResponse struct {
    ResponseHeader         hexutil.Bytes   // ABI-encoded Fdc2ResponseHeader
    RequestBody            hexutil.Bytes   // original request body
    ResponseBody           hexutil.Bytes   // attestation response body
    TEESignature           hexutil.Bytes   // TEE machine signature of the message hash
    CosignerSignatures     []hexutil.Bytes // cosigner signatures
    DataProviderSignatures hexutil.Bytes   // signing policy signatures in relay format
}
```

The response header structure:

```solidity
// Source: IFdc2Hub.sol
struct Fdc2ResponseHeader {
    bytes32 attestationType;   // attestation type
    bytes32 sourceId;          // source chain ID
    uint16 thresholdBIPS;      // threshold in BIPS
    address proofOwner;        // proof owner address
    address[] cosigners;       // cosigner addresses
    uint64 cosignersThreshold; // cosigners threshold
    uint64 timestamp;          // timestamp of the response
}
```

## Notes

**Message Hash Construction:** The TEE constructs the signed hash by separately ABI-encoding and hashing the response header, request body, and response body, combining the three hashes, prepending a $6$-byte protocol prefix (`0x010000000000`), and hashing the result. This format ensures interoperability with the existing Relay contract verification used in the FDC.

**Data Provider Signatures:** Data provider signatures are encoded in relay format using the signing policy, enabling on-chain verification through the existing Relay contract infrastructure.
