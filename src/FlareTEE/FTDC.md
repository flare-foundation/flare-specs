# Flare TEE Data Connector
The Flare TEE Data Connector (FTDC) is an application on the [system extension](SystemExtension.md).
It is a TEE-based alternative to the FDC [outward link to FDC].
In the FTDC, users submit attestation requests as an [instruction](Instructions.md) on the System Extension, indicating a collection of TEE machines on which the attestation is to be confirmed. 
As in the FDC, Flare's data providers are responsible for confirming the attestations.

However, unlike in the FDC where the requests are confirmed in a sequence of $90$ second using an on-chain voting process, in the FTDC providers vote by submitting the attestations to participating TEEs.
Upon receiving a sufficient weight of votes for an attestation, the TEE machines sign the attestation response with their identity key.
The signed attestation, packaged alongside the list of data provider signatures, is then available from the TEE proxy to be published on Flare.
This presents two upgrades over the FDC: 

- Latency is improved as requests are handled as they arrive, rather than at the end of a round.
- Removal of the on-chain voting process means that any request which can be verified by enough data providers will be responded to.

As part of the System Extension of the FlareTEE architecture, the FTDC is responsible for handling specific types of attestation requests relating to the liveness and security of the TEE machines [tbd?].

## Overview
The procedure for handling attestations in the FTDC is broadly the same as in the FDC.
Users submit *attestation requests* to the FTDC smart contract on Flare, requesting the verification of specified external data.
Flare's data providers prepare *attestation responses* confirming the validity of genuine requests, which together validate the data on-chain.
However, the voting process is changed from bit-voting in the FDC to a TEE based procedure.
Correspondingly, Merkle proofs are replaced by TEE verification, which means that requests are no longer confirmed in batches. 
The procedure for handling an FTDC request is as follows:

1. A user submits an attestation request $\mathrm{Att} = (\mathrm{data}, \mathrm{source}, \mathrm{TEE}_\mathrm{list}, \mathrm{cosigners}, \mathrm{cosigner \ threshold})$ to the FTDC in the form of an instruction on the system extension. The precise syntax of an attestation request is explained below, but note that the cosigner fields are optional. 
2. Flare's data providers pick-up the instruction from Flare and confirm (off-chain) that the pair $(\mathrm{data}, \mathrm{source})$ in $\mathrm{Att}$ represents valid data from the specified source. In the case where the request includes cosigners, the cosigners also perform this step.
3. Assuming the request is valid, each provider and cosigner packages the instruction together with the attestation response. They then prepare a signed TEE instruction including the provider signature $\mathrm{Sign}_i (\mathrm{Att_{response}})$ over the attestation response. The exact format of this signature is explained below.
4. Each provider sends the signed TEE instruction to the TEE proxies corresponding to the TEE machines included in the instruction argument $\mathrm{TEE}_\mathrm{list}$. 
5. The [voting process](Voting) for an FTDC request is the same as for any other instruction: thus, on receipt of a sufficient weight of data provider signatures (and an amount of cosigner signatures exceeding the cosigner threshold) each TEE machine signs the attestation response with the key corresponding to its identity $\mathrm{TEE}_{\mathrm{id}}$. 
6. The TEE returns the action result to the TEE proxy, including both the list of data provider signatures $\mathrm{Sign}_i (\mathrm{Att_{response}})$ for each data provider $i$ that voted and its own $\mathrm{Sign}_{\mathrm{id}}(\mathrm{Att_{response}})$ over the attestation response.
7. The FTDC confirmation of the request can now be fetched from a participating TEE proxy and published on Flare. This step is typically completed by the data providers.

### Attestation Types
As in the FDC, each attestation request must follow one of the pre-defined *attestation types*.
The attestation type of a request defines the type of information in the payload.
For example, separate attestation types exist for requests relating to transactions and addresses on external chains. 
Each attestation type is identified by a unique attestation type ID, with new types added via governance. 
For more information see [link to FDC attestation types].

### Request Format
An attestation request takes the form of a solidity struct

```Solidity
struct FtdcAttestationRequest {
FtdcRequestHeader header;
bytes requestBody;
```
containing two parts: a `header` providing information about the attestation and a `requestBody` containing the payload data.
Additionally, when issuing an attestation request instruction, a pair  $\mathrm{TEE}_\mathrm{list}$ = (`numberOfTees`, `TeeIds`) is included as part of the instruction, indicating the number (in uint8) and identities of the TEE machines on which voting is to be performed.

As it contains the data to be imported onto Flare, the content of `requestBody` varies depending on the exact request, and it is the responsibility of the data providers and cosigners to confirm the validity of the data.

The request header has a predefined structure:

``` Solidity
struct FtdcRequestHeader {
bytes32 attestationType;
bytes32 sourceId;
uint16 thresholdBIPS;
address[] cosigners;
uint64 cosignersThreshold;
}
```
where the `cosigners` and `cosignersThreshold` fields are optional, denoting the amount of cosigners and cosigner threshold used in the voting process in step 5 of the process. 
The `attestationType` and `sourceID` fields denote the attestation type of the attestation and the data source of the attestation. 
The `thresholdBIPS` field denotes the weight of data provider signatures required in step 5, and must exceed $40\%$.

### Response Format
An attestation response consists of three parts

- The `FtdcResponseHeader`.
- The `requestBody` from the request.
- The attestation response body.

The format of the response header is similar to the header of the request, except that it also includes a timestamp stating when it was generated:

```Solidity
struct FtdcResponseHeader {
bytes32 attestationType;
bytes32 sourceId;
uint16 thresholdBIPS;
address[] cosigners;
uint64 cosignersThreshold;
uint64 timestamp;
}
```
The format of the third part, the response body, is a Solidity struct whose exact format depends on the attestation type of the request.

Data providers, cosigners, and the TEE machine each need to sign the attestation response.
To do so, the response header, request body, and response body are each separately ABI encoded and hashed, then the outputs of the three hashes are hashed together. 
Finally, this hash is pre-pended with the string `?0x010000000000?` and hashed a final time. That is, the signed hash is:
```
hash(?0x010000000000?,
hash(
hash(ABIencode(response_header)),
hash(ABIencode(requestBody)),
hash(ABIencode(responseBody))
)
)
```

### Instruction Format
In the [instruction](Instructions.md) sent to the TEE proxy as part of handling the attestation, the data providers and cosigners must propagate certain fields in the instruction correctly. 
These include

- `additionalFixedMessage`: The ABI encoding of `requestBody`.
- `additionalVariableMessage`: The signature over the hash generated from the attestation response.

### Action Result Format
In the final step of the process, an attestation proof is published on Flare. 
The Solidity struct of the proof takes the format

``` Solidity
struct Proof {
FtdcSignatures signatures;
FtdcResponseHeader header;
RequestBody requestBody;
ResponseBody responseBody;
}
```
where the final 3 fields are taken from the attestation response. 
The struct `signatures` contains three fields: signatures from the data providers to be compared to the signing policy at the Relay contract, the signature from the TEE, and the signatures from cosigners:

``` Solidity
struct FtdcSignatures {
bytes signingPolicySignatures;
Signature[] teeSignatures;
Signature[] cosignerSignatures;
}
```
Note that in some cases, some of these fields may be empty, for example when there are no cosigners.