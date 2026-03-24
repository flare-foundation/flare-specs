# Flare Data Connector v2 (FDC2)
The Flare Data Connector v2 (FDC2) is an application on the [system extension](System%20Extension.md).
It is a TEE-based alternative to the FDC, managed via the `Fdc2Hub` smart contract.
In the FDC2, users submit attestation requests as an [instruction](../Operations/Instructions.md) on the system extension, indicating a collection of TEE machines on which the attestation is to be confirmed.
As in the FDC, Flare's data providers are responsible for confirming the attestations.

However, unlike in the FDC where the requests are confirmed in a sequence of $90$-second rounds using an on-chain voting process, in the FDC2 providers vote by submitting the attestations to participating TEEs.
Upon receiving a sufficient weight of votes for an attestation, the TEE machines sign the attestation response with their identity key.
The signed attestation, packaged alongside the list of data provider signatures, is then available from the TEE proxy to be published on Flare.
This presents two upgrades over the FDC:

- Latency is improved as requests are handled as they arrive, rather than at the end of a round.
- Removal of the on-chain voting process means that any request which can be verified by enough data providers will be responded to.

As part of the system extension of the Flare Confidential Compute architecture, the FDC2 handles specific types of attestation requests relating to the liveness and security of the TEE machines and the status of PMW operations.

## Attestation Types
The FDC2 currently supports four attestation types:

1. **TeeAvailabilityCheck** — verifies TEE machine availability, code integrity, and platform attestation freshness.
2. **PMWPaymentStatus** — verifies the status of a PMW payment transaction on an external chain.
3. **PMWMultisigAccountConfigured** — proves that a multisig account on an external chain is correctly configured for PMW use.
4. **PMWFeeProof** — provides accurate fee accounting for a range of payment nonces, comparing estimated fees (from instruction events) with actual fees (from external chain transactions).

For full details on each type, see the [attestation-types](../attestation-types/) documentation.
For the verifier server HTTP interface, see the [FDC2 Verifier Server](FDC2%20Verifier%20Server.md) specification.

## Overview
The procedure for handling attestations in the FDC2 is broadly the same as in the FDC.
Users submit *attestation requests* to the FDC2 smart contract on Flare, requesting the verification of specified external data.
Flare's data providers prepare *attestation responses* confirming the validity of genuine requests, which together validate the data on-chain.
However, the voting process is changed from bit-voting in the FDC to a TEE-based procedure.
Correspondingly, Merkle proofs are replaced by TEE verification, which means that requests are no longer confirmed in batches.
The procedure for handling an FDC2 request is as follows:

1. A user submits an attestation request $\mathrm{Att} = (\mathrm{data}, \mathrm{source}, \mathrm{TEE}_\mathrm{list}, \mathrm{cosigners}, \mathrm{cosigner \ threshold})$ to the FDC2 in the form of an instruction on the system extension. The precise syntax of an attestation request is explained below, but note that the cosigner fields are optional.
2. Flare's data providers pick up the instruction from Flare and confirm (off-chain) that the pair $(\mathrm{data}, \mathrm{source})$ in $\mathrm{Att}$ represents valid data from the specified source. In the case where the request includes cosigners, the cosigners also perform this step.
3. Assuming the request is valid, each provider and cosigner packages the instruction together with the attestation response. They then prepare a signed TEE instruction including the provider signature $\mathrm{Sign}_i (\mathrm{Att_{response}})$ over the attestation response. The exact format of this signature is explained below.
4. Each provider sends the signed TEE instruction to the TEE proxies corresponding to the TEE machines included in the instruction argument $\mathrm{TEE}_\mathrm{list}$.
5. The [voting process](../Operations/Voting.md) for an FDC2 request is the same as for any other instruction: thus, on receipt of a sufficient weight of data provider signatures (and an amount of cosigner signatures exceeding the cosigner threshold), each TEE machine signs the attestation response with the key corresponding to its identity $\mathrm{TEE}_{\mathrm{ID}}$.
6. The TEE returns the action result to the TEE proxy, including both the list of data provider signatures $\mathrm{Sign}_i (\mathrm{Att_{response}})$ for each data provider $i$ that voted and its own $\mathrm{Sign}_{\mathrm{ID}}(\mathrm{Att_{response}})$ over the attestation response.
7. The FDC2 confirmation of the request can now be fetched from a participating TEE proxy and published on Flare. This step is typically completed by the data providers.

### Request Format
An attestation request takes the form of a Solidity struct:

```solidity
// Source: IFdc2Hub.sol
struct Fdc2AttestationRequest {
    Fdc2RequestHeader header;
    bytes requestBody;
}

struct Fdc2RequestHeader {
    bytes32 attestationType;
    bytes32 sourceId;
    uint16 thresholdBIPS;
    address proofOwner;
}
```

The `header` provides information about the attestation and the `requestBody` contains the payload data.
The `proofOwner` field specifies the address that owns the proof; a zero address indicates a public proof.
Additionally, when issuing an attestation request instruction, a pair $\mathrm{TEE}_\mathrm{list}$ = (`numberOfTees`, `teeIds`) is included as part of the instruction, indicating the number (in $\mathrm{uint8}$) and identities of the TEE machines on which voting is to be performed.
If `numberOfTees` is set to $0$, the `Fdc2Hub` smart contract chooses a fixed number of TEE machines randomly from the set of registered machines.

As it contains the data to be imported onto Flare, the content of `requestBody` varies depending on the exact request, and it is the responsibility of the data providers and cosigners to confirm the validity of the data.

The `cosigners` and `cosignersThreshold` fields are included at the instruction event level rather than in the `Fdc2RequestHeader` itself, depending on how the `sendInstructions` call is structured.
The TEE proxy extracts these values from the instruction event and applies them during the voting process.
The `attestationType` and `sourceId` fields denote the attestation type and the data source of the attestation.
The `thresholdBIPS` field denotes the weight of data provider signatures required in step 5, and must exceed $40\%$.

### Response Format
An attestation response consists of three parts:

- The `Fdc2ResponseHeader`.
- The `requestBody` from the request.
- The attestation response body.

The format of the response header is similar to the header of the request, except that it also includes cosigner information and a timestamp:

```solidity
// Source: IFdc2Hub.sol
struct Fdc2ResponseHeader {
    bytes32 attestationType;
    bytes32 sourceId;
    uint16 thresholdBIPS;
    address proofOwner;
    address[] cosigners;
    uint64 cosignersThreshold;
    uint64 timestamp;
}
```

The format of the response body is a Solidity struct whose exact format depends on the attestation type of the request.

### Signature Computation

Data providers, cosigners, and the TEE machine each need to sign the attestation response.
To do so, the response header, request body, and response body are each separately ABI-encoded and hashed, then the outputs of the three hashes are hashed together.
Finally, this hash is prepended with a $6$-byte protocol prefix `0x010000000000` and hashed a final time. That is, the signed hash is:

$$\mathrm{hash}(\texttt{0x010000000000} \| \mathrm{hash}(\mathrm{hash}(\text{ABIencode}(\text{responseHeader})), \mathrm{hash}(\text{ABIencode}(\text{requestBody})), \mathrm{hash}(\text{ABIencode}(\text{responseBody}))))$$

> **Note on interoperability:** The $6$-byte prefix matches the format of a protocol message with a Merkle root (with `protocolId = 1`, `votingRoundId = 0`, and `isSecureRandom = 0`). This ensures interoperability with the existing Relay contract verification used in the FDC.

### Instruction Format
In the [instruction](../Operations/Instructions.md) sent to the TEE proxy as part of handling the attestation, the data providers and cosigners must propagate certain fields in the instruction correctly.
These include:

- `additionalFixedMessage`: The ABI encoding of the `requestBody`.
- `additionalVariableMessage`: The signature over the hash generated from the attestation response.

### Action Result Format
In the final step of the process, an attestation proof is published on Flare.
The action result contains the following data:

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

The `DataProviderSignatures` field is encoded in relay format using the signing policy, enabling on-chain verification through the existing Relay contract infrastructure.

Note that in some cases, some of these fields may be empty, for example when there are no cosigners.

## Assembling a Proof for On-Chain Verification

The `ProveResponse` returned from the TEE proxy's action result API must be converted into a Solidity-compatible proof struct before it can be submitted to a verifying contract on-chain. This section describes the assembly process.

### On-Chain Proof Structure

Each attestation type defines a `Proof` struct following the same pattern:

```solidity
// Source: e.g., ITeeAvailabilityCheck.sol, IPMWPaymentStatus.sol
struct Proof {
    IFdc2Verification.Fdc2Signatures signatures;
    IFdc2Hub.Fdc2ResponseHeader header;
    RequestBody requestBody;
    ResponseBody responseBody;
}
```

The `Fdc2Signatures` struct bundles all three signature types:

```solidity
// Source: IFdc2Verification.sol
struct Fdc2Signatures {
    bytes signingPolicySignatures;   // relay-formatted data provider signatures
    Signature[] teeSignatures;       // TEE machine signatures (v, r, s)
    Signature[] cosignerSignatures;  // cosigner signatures (v, r, s)
}
```

Where each `Signature` is:

```solidity
// Source: ISignature.sol
struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}
```

### Mapping ProveResponse to Proof

The following table shows how each field of the `ProveResponse` (from the action result) maps to the on-chain `Proof` struct:

| ProveResponse field | Proof field | Conversion |
|---|---|---|
| `ResponseHeader` | `header` | ABI-decode into `Fdc2ResponseHeader` |
| `RequestBody` | `requestBody` | ABI-decode into the attestation-specific `RequestBody` struct |
| `ResponseBody` | `responseBody` | ABI-decode into the attestation-specific `ResponseBody` struct |
| `DataProviderSignatures` | `signatures.signingPolicySignatures` | Use directly (already in relay format) |
| `TEESignature` | `signatures.teeSignatures` | Decompose raw bytes into `(v, r, s)` components; wrap in a single-element `Signature[]` array |
| `CosignerSignatures` | `signatures.cosignerSignatures` | Decompose each entry into `(v, r, s)` components; assemble into `Signature[]` array |

### Assembly Steps

1. **Fetch the action result** from the TEE proxy via `GET /action/result/<instructionId>`. The `data` field of the result contains the JSON-encoded `ProveResponse`.

2. **Decode the response header.** ABI-decode `ProveResponse.ResponseHeader` into the `Fdc2ResponseHeader` struct. This yields the `attestationType`, `sourceId`, `thresholdBIPS`, `proofOwner`, `cosigners`, `cosignersThreshold`, and `timestamp` fields.

3. **Decode request and response bodies.** ABI-decode `ProveResponse.RequestBody` and `ProveResponse.ResponseBody` into the attestation-type-specific structs. For example, for [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md), the response body decodes into a struct with `status`, `teeTimestamp`, `codeHash`, `platform`, `initialSigningPolicyId`, `lastSigningPolicyId`, and `state`.

4. **Decompose signatures.** Convert the raw signature bytes into Solidity `Signature` structs by splitting each $65$-byte ECDSA signature into `(v, r, s)` components:
   - `r` = first $32$ bytes.
   - `s` = next $32$ bytes.
   - `v` = last byte (recovery ID, typically $27$ or $28$).

5. **Assemble the `Fdc2Signatures` struct:**
   - `signingPolicySignatures` = `ProveResponse.DataProviderSignatures` (used as-is in relay format).
   - `teeSignatures` = array of decomposed `TEESignature`(s).
   - `cosignerSignatures` = array of decomposed `CosignerSignatures`.

6. **Construct the final `Proof` struct** and submit it to the verifying contract.

### On-Chain Verification

The verifying contract (e.g., `TeeVerification`) validates the proof by:

1. **Checking the response header** — verifying that the `attestationType` and `sourceId` match the expected values.
2. **Recomputing the message hash** — the contract independently hashes the header, request body, and response body, prepends the $6$-byte protocol prefix, and hashes again. This reproduces the hash that was originally signed.
3. **Verifying signatures** — depending on the proof type:
   - If `teeSignatures` are present: the `Fdc2Verification` contract verifies each TEE signature using `ecrecover` against the recomputed hash, confirming the signing TEE's identity.
   - If `signingPolicySignatures` are present: the `Relay` contract verifies the data provider signatures against the current signing policy.
   - If `cosignerSignatures` are present: each is verified against the cosigner addresses listed in the response header.
4. **Validating response data** — the contract checks attestation-specific fields (e.g., code hash, platform, signing policy hashes for [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md); account configuration for [`PMWMultisigAccountConfigured`](../attestation-types/PMWMultisigAccountConfigured.md)).

### Attestation-Specific Proof Structs

Each attestation type has its own request/response body definitions:

| Attestation Type | Solidity Interface | Request Body Fields | Response Body Fields |
|---|---|---|---|
| TeeAvailabilityCheck | `ITeeAvailabilityCheck` | `teeId`, `teeProxyId`, `url`, `challenge`, `instructionId` | `status`, `teeTimestamp`, `codeHash`, `platform`, `initialSigningPolicyId`, `lastSigningPolicyId`, `state` |
| PMWPaymentStatus | `IPMWPaymentStatus` | `opType`, `senderAddress`, `nonce`, `subNonce` | `recipientAddress`, `tokenId`, `amount`, `maxFee`, `paymentReference`, `transactionStatus`, `revertReason`, `receivedAmount`, `transactionFee`, `transactionId`, `blockNumber`, `blockTimestamp` |
| PMWMultisigAccountConfigured | `IPMWMultisigAccountConfigured` | `accountAddress`, `publicKeys`, `threshold` | `status`, `sequence` |
| PMWFeeProof | `IPMWFeeProof` | `opType`, `senderAddress`, `fromNonce`, `toNonce`, `untilTimestamp` | `actualFee`, `estimatedFee` |
