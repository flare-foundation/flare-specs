# FDC2 Attestation Sub-Workflow

## Overview

This sub-workflow describes the common process for submitting, voting on, and verifying an FDC2 attestation request.
It applies to all three attestation types: `TeeAvailabilityCheck`, `PMWMultisigAccountConfigured`, and `PMWPaymentStatus`.
For full FDC2 details, see the [FDC2 specification](../Extensions/FTDC.md).

## Prerequisites

- TEE machines participating in the attestation must be in `PRODUCTION` status.
- Data providers must be enrolled in the current signing policy.
- The `Fdc2Hub` smart contract must be deployed.

---

## Steps

All FDC2 attestation types follow the same process. The specific request and response bodies vary by attestation type, but the overall flow, voting mechanism, and proof structure are identical.

### Step 1: Submit Attestation Request (User Action)

Submit an attestation request as an [instruction](../Operations/Instructions.md) on the System Extension. The request contains:

```solidity
struct Fdc2AttestationRequest {
    Fdc2RequestHeader header;
    bytes requestBody;
}
```

Additionally, the instruction includes a TEE list (`numberOfTees`, `TeeIds`) indicating which TEE machines should participate. If `numberOfTees` is set to `0`, the `Fdc2Hub` contract selects machines randomly from the registered set.

Depending on the attestation type, the request is submitted through a convenience contract (e.g., `TeeVerification.requestAvailabilityCheckAttestation()`, `TeeVerification.requestPMWMultisigAccountConfiguredAttestation()`) or directly via `Fdc2Hub.requestAttestation()`.

Steps 2 through 6 happen automatically once the attestation request is submitted on-chain:

### Step 2: Data Provider Verification

Data providers pick up the instruction from Flare and confirm off-chain that the `(data, source)` pair in the request represents valid data from the specified source. If the request includes cosigners, they also perform this verification step.

### Step 3: Provider Signs Attestation Response

Each provider and cosigner packages the instruction together with the attestation response. They prepare a signed TEE instruction including their signature over the attestation response. The instruction fields are:

- `additionalFixedMessage`: The ABI encoding of `requestBody`.
- `additionalVariableMessage`: The signature over the hash generated from the attestation response.

### Step 4: Submit to TEE Proxies

Each provider sends the signed TEE instruction to the TEE proxies corresponding to the TEE machines listed in `TEE_list`.

### Step 5: TEE Voting

The [voting process](../Operations/Voting.md) for an FDC2 request follows the standard instruction voting rules. Upon receiving sufficient weight of data provider signatures (and cosigner signatures exceeding the cosigner threshold), each TEE machine signs the attestation response with its identity key.

### Step 6: TEE Returns Action Result

The TEE returns the action result to the TEE proxy, including:

- The list of data provider signatures over the attestation response.
- The TEE's own signature over the attestation response.
- Cosigner signatures (if applicable).

### Step 7: Retrieve Proof and Publish On-Chain (User Action)

After submitting the attestation request, poll the TEE proxy until the proof is available, then publish it on-chain:

1. **Poll the proxy** — call `GET <proxyUrl>/action/result/<instructionId>` using the `instructionId` from the `TeeInstructionsSent` event emitted in Step 1. Repeat until the response contains a completed proof.
2. **Decode the proof** — parse the response to extract the `Fdc2ResponseHeader`, `RequestBody`, and `ResponseBody` for the specific attestation type.
3. **Verify and publish on-chain** — call the appropriate verification contract function to validate the proof and apply its result. The specific function depends on the attestation type:
   - **TeeAvailabilityCheck**: `TeeMachineRegistry.toProduction(proof)` or `TeeMachineRegistry.confirmAvailability(proof)` or `TeeMachineRegistry.pauseWithProof(proof)`
   - **PMWMultisigAccountConfigured**: `TeeVerification.verifyPMWMultisigAccountConfiguredProof(walletId, proof)` followed by `TeePayment.AddPMWMultisigAccount(walletId, proof)`
   - **PMWPaymentStatus**: verify via `PMWPaymentStatusVerifier.verify(teePaymentsAddress, proof)`

---

## Notes

- **Request and response structures:** For the complete struct definitions (`Fdc2RequestHeader`, `Fdc2ResponseHeader`, `Fdc2Signatures`, `Proof`), signature computation scheme, and proof assembly process, see the [FDC2 specification](../Extensions/FTDC.md). Key points for this workflow:
  - The `Fdc2RequestHeader` contains `attestationType`, `sourceId`, `thresholdBIPS`, and `proofOwner`. The `cosigners` and `cosignersThreshold` fields are included at the instruction event level rather than in the header itself.
  - The `Fdc2ResponseHeader` mirrors the request header with additional `cosigners`, `cosignersThreshold`, and `timestamp` fields.
  - The `thresholdBIPS` must exceed 40%.
  - Some signature fields may be empty when there are no cosigners.
- **TeeAvailabilityCheck:** Verifies that a registered TEE machine is available, running valid code, and has a fresh attestation from the platform. Used during machine registration (`toProduction`), periodic availability confirmation (`confirmAvailability`), and pause-with-proof (`pauseWithProof`). For the full specification including request/response body definitions, see [TeeAvailabilityCheck](../attestation-types/TeeAvailabilityCheck.md).
  - *Verifier server behavior (poller):* The verifier server (`VERIFIER_TYPE=TeeAvailabilityCheck`) also acts as a TEE machine availability poller. Every minute, the poller queries the `<proxyUrl>/info` API for each active TEE machine. The list of active machines is obtained by calling `getAllActiveTeeMachines` on the `TeeMachineRegistry` smart contract. Only the latest 5 samples per machine are retained. On each poll: (1) challenge freshness is checked — the challenge is generated by the proxy using a block hash, and the verifier checks the block's timestamp via RPC with a configured threshold of `BlockFreshnessInSeconds = 150` (2.5 minutes); (2) verification checks — JWT token and claims validation, TEE identity check, and signing policy checks as described in the [TeeAvailabilityCheck](../attestation-types/TeeAvailabilityCheck.md) specification; (3) sample classification — all checks pass: `VALID`, failure due to verifier fault: `INDETERMINATE`, failure due to provided data: `INVALID`.
  - *Status determination (DOWN detection):* To reliably detect `DOWN`, the poller must observe only `INVALID` samples for at least 5 minutes. If all entries hold sample state `INVALID`: status = `DOWN`. Otherwise: status = `INDETERMINATE`.
  - *Evaluating availability with attestation:* If no attestation result is available on `/action/result/<instructionId>`, the verifier falls back to availability checks using recent samples — if all samples in the last 5 minutes are `INVALID`: status = `DOWN`; otherwise return `UNDETERMINED` (HTTP 503). If an attestation result is available and the platform is obsolete (`support_attributes` lacks `STABLE`): status = `OBSOLETE`; otherwise, if all JWT checks pass: status = `OK`.
- **PMWMultisigAccountConfigured:** Proves that a multisig account on an external chain is configured correctly for use with Protocol Managed Wallets. Each data provider uses its own XRP node for verification, mitigating the risk of a single malicious or spoofed node. For the full specification including request/response body definitions and XRP account validation rules, see [PMWMultisigAccountConfigured](../attestation-types/PMWMultisigAccountConfigured.md). The attestation is used during XRPL multisig setup — see [xrpl-multisig-configuration.md](xrpl-multisig-configuration.md) Steps 3-5 for the complete procedure.
- **PMWPaymentStatus:** Verifies the status of a payment transaction initiated by a Protocol Managed Wallet on an external chain. Currently only used for XRP. For the full specification including request/response body definitions and transaction lookup process, see [PMWPaymentStatus](../attestation-types/PMWPaymentStatus.md). The attestation is used to verify completed payments — see [xrp-payment.md](xrp-payment.md) Step 4 for the complete procedure.

