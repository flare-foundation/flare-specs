# Flare TEE Data Connector
The Flare Data Connector v2 (FDC2) is an application on the [system extension](SystemExtension.md).
It is a TEE-based alternative to the FDC, managed via the `Fdc2Hub` smart contract.
In the FDC2, users submit attestation requests as an [instruction](../Operations/Instructions.md) on the system extension, indicating a collection of TEE machines on which the attestation is to be confirmed.
As in the FDC, Flare's [data providers](../../Terminology/Roles.md#data-provider) are responsible for confirming the attestations.

However, unlike in the FDC where the requests are confirmed in a sequence of $90$-second rounds using an on-chain voting process, in the FDC2 providers vote by submitting the attestations to participating TEEs.
Upon receiving a sufficient weight of votes for an attestation, the TEE machines sign the attestation response with their identity key.
The signed attestation, packaged alongside the list of data provider signatures, is then available from the TEE proxy to be published on Flare.
This presents two upgrades over the FDC:

- Latency is improved as requests are handled as they arrive, rather than at the end of a round.
- Removal of the on-chain voting process means that any request which can be verified by enough data providers will be responded to.

As part of the system extension of the Flare Confidential Compute architecture, the FDC2 handles specific types of attestation requests relating to the liveness and security of the TEE machines and the status of PMW operations.

## Overview
The procedure for handling attestations in the FDC2 is broadly the same as in the FDC.
Users submit *attestation requests* to the FDC2 smart contract on Flare, requesting the verification of specified external data.
Flare's data providers prepare *attestation responses* confirming the validity of genuine requests, which together validate the data on-chain.
However, the voting process is changed from bit-voting in the FDC to a TEE-based procedure.
Correspondingly, Merkle proofs are replaced by TEE verification, which means that requests are no longer confirmed in batches.
The procedure for handling an FDC2 request is as follows:

1. A user submits an attestation request $\mathrm{Att} = (\mathrm{data}, \mathrm{source}, \mathrm{TEE}_\mathrm{list}, \mathrm{cosigners}, \mathrm{cosigner \ threshold})$ to the FDC2 in the form of an instruction on the system extension. The precise syntax of an attestation request is explained below, but note that the [cosigner](../../Terminology/Roles.md#cosigner) fields are optional.
2. Flare's data providers pick up the instruction from Flare and confirm (off-chain) that the pair $(\mathrm{data}, \mathrm{source})$ in $\mathrm{Att}$ represents valid data from the specified source. In the case where the request includes cosigners, the cosigners also perform this step.
3. Assuming the request is valid, each provider and cosigner packages the instruction together with the attestation response. They then prepare a signed TEE instruction including the provider signature $\mathrm{Sign}_i (\mathrm{Att_{response}})$ over the attestation response. The exact format of this signature is explained below.
4. Each provider sends the signed TEE instruction to the TEE proxies corresponding to the TEE machines included in the instruction argument $\mathrm{TEE}_\mathrm{list}$.
5. The [voting process](../Operations/Voting.md) for an FDC2 request is the same as for any other instruction: thus, on receipt of a sufficient weight of data provider signatures (and an amount of cosigner signatures exceeding the cosigner threshold), each TEE machine signs the attestation response with the key corresponding to its identity $\mathrm{TEE}_{\mathrm{ID}}$.
6. The TEE returns the action result to the TEE proxy, including both the list of data provider signatures $\mathrm{Sign}_i (\mathrm{Att_{response}})$ for each data provider $i$ that voted and its own $\mathrm{Sign}_{\mathrm{ID}}(\mathrm{Att_{response}})$ over the attestation response.
7. The FDC2 confirmation of the request can now be fetched from a participating TEE proxy and published on Flare. This step is typically completed by the data providers.

## Attestation Types
The FDC2 currently supports four attestation types:

1. **TeeAvailabilityCheck**: Verifies TEE machine availability, code integrity, and platform attestation freshness.
2. **PMWPaymentStatus**: Verifies the status of a PMW payment transaction on an external chain.
3. **PMWMultisigAccountConfigured**: Proves that a multisig account on an external chain is correctly configured for PMW use.
4. **PMWFeeProof**: Provides accurate fee accounting for a range of payment nonces, comparing estimated fees (from instruction events) with actual fees (from external chain transactions).

For full details on each type, see the [attestation-types](../AttestationTypes/) documentation.
For the verifier server HTTP interface, see the [FDC2 Verifier Server](Fdc2VerifierServer.md) specification.

## Formatting

An attestation request takes the form of the [`Fdc2AttestationRequest`](../Types/Abi/Fdc2.md#fdc2attestationrequest) struct, containing a [`Fdc2RequestHeader`](../Types/Abi/Fdc2.md#fdc2requestheader) and a type-specific `requestBody`.

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

The format of the response header is defined by the [`Fdc2ResponseHeader`](../Types/Abi/Fdc2.md#fdc2responseheader) struct, which extends the request header with cosigner information and a timestamp.

The format of the response body is a Solidity struct whose exact format depends on the attestation type of the request.

### Signature Computation
Data providers, cosigners, and the TEE machine each need to sign the attestation response.
To do so, the response header, request body, and response body are each separately ABI-encoded and hashed, then the outputs of the three hashes are hashed together.
Finally, this hash is prepended with a $6$-byte protocol prefix `0x010000000000` and hashed a final time. That is, the signed hash is:

```
hash(0x010000000000,
hash(
hash(ABIencode(response_header)),
hash(ABIencode(requestBody)),
hash(ABIencode(responseBody))
)
)
```
> **Note on interoperability:** The $6$-byte prefix matches the format of a protocol message with a Merkle root (with `protocolId = 1`, `votingRoundId = 0`, and `isSecureRandom = 0`). This ensures interoperability with the existing Relay contract verification used in the FDC.

### Instruction Format
In the [instruction](../Operations/Instructions.md) sent to the TEE proxy as part of handling the attestation, the data providers and cosigners must propagate certain fields in the instruction correctly.
These include:

- `additionalFixedMessage`: The ABI-encoded attestation response body.
- `additionalVariableMessage`: The signature over the hash generated from the attestation response.

The corresponding relay behavior is summarized in the [`F_FDC2 PROVE` augmentation procedure](../Commands/F_FDC2--PROVE.md#augmentation-procedure).

### Action Result Format
In the final step of the process, an attestation proof is published on Flare.
The action result is formatted as the [`ProveResponse`](../Types/Wire/Fdc2.md#proveresponse) struct.

The `DataProviderSignatures` field is encoded in relay format using the signing policy, enabling on-chain verification through the existing Relay contract infrastructure.

Note that in some cases, some of these fields may be empty, for example when there are no cosigners.

## Assembling a Proof for On-Chain Verification

The `ProveResponse` returned from the TEE proxy's action result API must be converted into a Solidity-compatible proof struct before it can be submitted to a verifying contract on-chain. This section describes the assembly process.

### On-Chain Proof Structure

Each attestation type defines a [`Proof`](../Types/Abi/Fdc2.md#proof) struct following the same pattern, using the [`Fdc2Signatures`](../Types/Abi/Fdc2.md#fdc2signatures) bundle and [`Signature`](../Types/Abi/Common.md#signature) type.

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

1. **Fetch the action result**: Fetch from the TEE proxy via `GET /action/result/<instructionId>`. The `data` field of the result contains the JSON-encoded `ProveResponse`.

2. **Decode the response header**: ABI-decode `ProveResponse.ResponseHeader` into the `Fdc2ResponseHeader` struct. This yields the `attestationType`, `sourceId`, `thresholdBIPS`, `proofOwner`, `cosigners`, `cosignersThreshold`, and `timestamp` fields.

3. **Decode request and response bodies**: ABI-decode `ProveResponse.RequestBody` and `ProveResponse.ResponseBody` into the attestation-type-specific structs.

4. **Decompose signatures**: Convert the raw signature bytes into Solidity `Signature` structs by splitting each $65$-byte ECDSA signature into its `(v, r, s)` components.

5. **Assemble the `Fdc2Signatures` struct:**
   - `signingPolicySignatures` = `ProveResponse.DataProviderSignatures` (used as-is in relay format).
   - `teeSignatures` = array of decomposed `TEESignature`(s).
   - `cosignerSignatures` = array of decomposed `CosignerSignatures`.

6. **Submission**: Construct the final `Proof` struct and submit it to the verifying contract.

### On-Chain Verification

The verifying contract (e.g., `TeeVerification`) validates the proof with the following process:

1. **Checking response header**: Verifies that the `attestationType` and `sourceId` match the expected values.
2. **Recomputing the message hash**: The contract independently hashes the header, request body, and response body, prepends the $6$-byte protocol prefix, and hashes again. This reproduces the hash that was originally signed.
3. **Verifying signatures**: This stage depends on the proof type:
   - If `teeSignatures` are present, the `Fdc2Verification` contract verifies each TEE signature using `ecrecover` against the recomputed hash, confirming the signing TEE's identity.
   - If `signingPolicySignatures` are present, the `Relay` contract verifies the data provider signatures against the current signing policy.
   - If `cosignerSignatures` are present, each is verified against the cosigner addresses listed in the response header.
4. **Validating response data**: The contract checks relevant attestation-specific fields (e.g., code hash, platform, signing policy hashes for [`TeeAvailabilityCheck`](../AttestationTypes/TeeAvailabilityCheck.md); account configuration for [`PMWMultisigAccountConfigured`](../AttestationTypes/PMWMultisigAccountConfigured.md)).

### Attestation-Specific Proof Structs

Each attestation type has its own request/response body definitions:

| Attestation Type | Solidity Interface | Request Body Fields | Response Body Fields |
|---|---|---|---|
| TeeAvailabilityCheck | `ITeeAvailabilityCheck` | `teeId`, `teeProxyId`, `url`, `challenge`, `instructionId` | `status`, `teeTimestamp`, `codeHash`, `platform`, `initialSigningPolicyId`, `lastSigningPolicyId`, `state` |
| PMWPaymentStatus | `IPMWPaymentStatus` | `opType`, `senderAddress`, `nonce`, `subNonce` | `recipientAddress`, `tokenId`, `amount`, `maxFee`, `paymentReference`, `transactionStatus`, `revertReason`, `receivedAmount`, `transactionFee`, `transactionId`, `blockNumber`, `blockTimestamp` |
| PMWMultisigAccountConfigured | `IPMWMultisigAccountConfigured` | `accountAddress`, `publicKeys`, `threshold` | `status`, `sequence` |
| PMWFeeProof | `IPMWFeeProof` | `opType`, `senderAddress`, `fromNonce`, `toNonce`, `untilTimestamp` | `actualFee`, `estimatedFee` |