# FDC2 Concepts

The Flare Data Connector v2 (FDC2) is an application on the [system extension](../FCE/System.md), managed via the `Fdc2Hub` smart contract.
Like the [FDC](../../FDC/Introduction.md), FDC2 is an enshrined oracle that imports validated external data onto Flare; unlike the FDC, it uses TEE machines as the trust anchor instead of on-chain bit voting.

Users submit attestation requests as [instructions](../Operations/Instructions.md) on the system extension; participating TEE machines, after a sufficient weight of [data-provider](../../Terminology/Roles.md#data-provider) votes, sign the attestation response with their identity key.
The signed attestation is then available from the [TEE proxy](../Reference/Components/Proxy.md) and can be published on Flare.

Compared with the FDC, this gives:

- Lower latency — requests are handled as they arrive, not in $90$-second rounds.
- Per-request finality — any request that gathers enough data-provider votes is answered, with no batched Merkle commitments.

In FCC, FDC2 also handles attestation types specific to TEE liveness and PMW transaction status.

## Request Flow

1. A user submits an [`Fdc2AttestationRequest`](Reference/Types/Abi/Fdc2.md#fdc2attestationrequest) via `Fdc2Hub`, which routes it as an [`F_FDC2 PROVE`](Reference/Operations/Prove.md) instruction to the TEE machines selected by `Fdc2Hub` (either explicitly listed in the request or chosen randomly from the registered set; see [Request Format](#request-format)).
2. Each [data provider](../../Terminology/Roles.md#data-provider) picks up the instruction off-chain, validates `(data, source)` against the request, and produces an attestation response.
3. The provider builds a signed instruction with the [`F_FDC2 PROVE` augmentation procedure](Reference/Operations/Prove.md#augmentation-procedure): `additionalFixedMessage` holds the ABI-encoded response body; `additionalVariableMessage` holds the provider's signature over the [attestation response hash](#signature-computation).
4. The signed instruction is sent to the [TEE proxies](../Reference/Components/Proxy.md) of the target machines and enters the standard [voting process](../Operations/Voting.md).
5. On reaching the data-provider weight threshold (and the cosigner threshold, if set), the TEE machine signs the attestation response with its identity key.
6. The TEE proxy serves the resulting [`ProveResponse`](Reference/Types/Wire/Fdc2.md#proveresponse) as the [action result](../Operations/Actions.md#action-results).
7. The proof can then be assembled and submitted on Flare; this final step is typically performed by a data provider.

## Attestation Types

FDC2 currently supports four attestation types:

1. [`TeeAvailabilityCheck`](Reference/AttestationTypes/TeeAvailabilityCheck.md) — TEE machine availability, code integrity, and platform attestation freshness.
2. [`PMWPaymentStatus`](Reference/AttestationTypes/PMWPaymentStatus.md) — status of a PMW payment transaction on an external chain.
3. [`PMWMultisigAccountConfigured`](Reference/AttestationTypes/PMWMultisigAccountConfigured.md) — that a multisig account on an external chain is correctly configured for PMW use.
4. [`PMWFeeProof`](Reference/AttestationTypes/PMWFeeProof.md) — fee accounting for a range of payment nonces (estimated fees vs. actual on-chain fees).

The verifier-server HTTP interface that data providers run for each type is documented in [Verifier](Verifier.md).

## Request Format

A request is an [`Fdc2AttestationRequest`](Reference/Types/Abi/Fdc2.md#fdc2attestationrequest) containing an [`Fdc2RequestHeader`](Reference/Types/Abi/Fdc2.md#fdc2requestheader) and a type-specific `requestBody`.

Key fields:

- `attestationType` and `sourceId`: identify the attestation type and the data source.
- `proofOwner`: address authorized to publish the proof; the zero address denotes a public proof.
- `thresholdBIPS`: data-provider voting threshold for this request, in basis points; must be at least $4000$ ($40\%$). The [TEE proxy](../Reference/Components/Proxy.md#signing-threshold-resolution) treats `0` as "use the signing policy default".
- $\mathrm{TEE}_\mathrm{list} = (\text{numberOfTees}, \text{teeIds})$: target TEE machines (carried on the instruction event, not in the request body). `numberOfTees = 0` instructs `Fdc2Hub` to select a fixed number of machines at random from the registered set.

`cosigners` and `cosignersThreshold` are passed at the `sendInstructions` call rather than in `Fdc2RequestHeader`, and the proxy extracts them from the [`TeeInstructionsSent` event](../Reference/Types/Abi/Events/TeeExtensionRegistry.md#teeinstructionssent) for the voting process.

## Response Format

An attestation response has three ABI-encoded parts:

- [`Fdc2ResponseHeader`](Reference/Types/Abi/Fdc2.md#fdc2responseheader) — extends the request header with cosigner fields and a timestamp.
- The `requestBody` from the request (echoed back).
- A type-specific response body.

## Signature Computation

Data providers, cosigners, and the TEE machine all sign the same digest.
The three parts above are each ABI-encoded and hashed; the three hashes are concatenated and hashed; the result is prefixed with the $6$-byte protocol prefix `0x010000000000` and hashed once more:

```
hash(0x010000000000,
     hash(hash(abi(responseHeader)),
          hash(abi(requestBody)),
          hash(abi(responseBody))))
```

The prefix matches the FSP protocol-message format for a Merkle root with `protocolId = 1`, `votingRoundId = 0`, and `isSecureRandom = 0`, which lets the existing Relay-contract verification used by the FDC verify FDC2 proofs unchanged.

## Action Result

The [`F_FDC2 PROVE`](Reference/Operations/Prove.md) action result is the [`ProveResponse`](Reference/Types/Wire/Fdc2.md#proveresponse) struct.
Its `DataProviderSignatures` field is encoded in [relay format](../../Utilities/Signing.md) using the current signing policy, enabling on-chain verification through the existing Relay contract infrastructure.
Cosigner or TEE signature fields may be empty when not applicable (e.g. no cosigners specified).

## On-Chain Proof Assembly

The on-chain [`Proof`](Reference/Types/Abi/Fdc2.md#proof) struct for each attestation type wraps a per-type `(header, requestBody, responseBody)` triple with an [`Fdc2Signatures`](Reference/Types/Abi/Fdc2.md#fdc2signatures) bundle composed of [`Signature`](../Reference/Types/Abi/Common.md#signature) entries.

`ProveResponse` → `Proof` mapping:

| `ProveResponse` field | `Proof` field | Conversion |
|---|---|---|
| `ResponseHeader` | `header` | ABI-decode into [`Fdc2ResponseHeader`](Reference/Types/Abi/Fdc2.md#fdc2responseheader). |
| `RequestBody` | `requestBody` | ABI-decode into the type-specific request body. |
| `ResponseBody` | `responseBody` | ABI-decode into the type-specific response body. |
| `DataProviderSignatures` | `signatures.signingPolicySignatures` | Use directly (already in relay format). |
| `TEESignature` | `signatures.teeSignatures` | Split the raw bytes into [`(v, r, s)`](../Reference/Types/Abi/Common.md#signature) and wrap in a one-element array. |
| `CosignerSignatures` | `signatures.cosignerSignatures` | Split each entry into `(v, r, s)`. |

The result is submitted to the verification entry point on [`FlareTeeManager`](../TeeManagement/FlareTeeManager.md) (e.g. `verifyAvailabilityCheckProof`, `verifyPMWMultisigAccountConfiguredProof`).

### On-Chain Verification

For each submitted proof, the contract:

1. Checks `attestationType` and `sourceId` match the expected values.
2. Recomputes the signed digest from the header, request body, and response body using the [signature-computation procedure](#signature-computation).
3. Verifies the signatures that are present:
   - `teeSignatures` are recovered with `ecrecover` and checked against the registered TEE identities.
   - `signingPolicySignatures` are verified by the `Relay` contract against the current signing policy.
   - `cosignerSignatures` are recovered and checked against the `cosigners` set in the response header.
4. Validates attestation-specific fields (e.g. code hash and platform for [`TeeAvailabilityCheck`](Reference/AttestationTypes/TeeAvailabilityCheck.md), account configuration for [`PMWMultisigAccountConfigured`](Reference/AttestationTypes/PMWMultisigAccountConfigured.md)).
