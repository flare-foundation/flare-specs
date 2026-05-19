# FDC2 Attestation Sub-Workflow

## Overview

This page describes the shared operational flow used by FDC2-based attestations.
The canonical request and response formats, signature rules, and proof assembly remain in [FDC2](../Extensions/FDC2/README.md), [`F_FDC2--PROVE`](../Extensions/FDC2/Commands/Prove.md), and the individual [attestation type specifications](../Extensions/FDC2/AttestationTypes/README.md).
This workflow focuses only on the order of actions.

The same flow applies to [`TeeAvailabilityCheck`](../Extensions/FDC2/AttestationTypes/TeeAvailabilityCheck.md), [`PMWMultisigAccountConfigured`](../Extensions/FDC2/AttestationTypes/PMWMultisigAccountConfigured.md), [`PMWPaymentStatus`](../Extensions/FDC2/AttestationTypes/PMWPaymentStatus.md), and [`PMWFeeProof`](../Extensions/FDC2/AttestationTypes/PMWFeeProof.md).

## Prerequisites

- The participating TEE machines must be in `PRODUCTION` status.
- [Data providers](../../Terminology/Roles.md#data-provider) must be enrolled in the current signing policy.
- The attestation-specific request body must be prepared according to the relevant attestation specification.

## Steps

### Step 1: Submit the Attestation Request

Submit an attestation request as an [instruction](../Operations/Instructions.md) on the system extension.
Depending on the attestation type, this is done either through a convenience contract such as `TeeVerification` or through `Fdc2Hub.requestAttestation()`.
The request body, source ID, threshold, proof owner, and target TEE list are defined by the owning FDC2 specification.

### Step 2: Providers Verify and Relay the Request

Data providers, and any required [cosigners](../Operations/Instructions.md#cosigners), verify the requested data off-chain.
Each signer then prepares the instruction for the selected machines using the standard FDC2 message layout:

- `additionalFixedMessage`: the ABI-encoded attestation response body.
- `additionalVariableMessage`: the signer's signature over the attestation response hash.

The signed instructions are relayed to the relevant TEE proxies.

### Step 3: TEEs Vote and Produce the Signed Response

Each TEE proxy runs the standard [voting process](../Operations/Voting.md) for the attestation instruction.
Once the data-provider threshold, and any cosigner threshold, are satisfied, the TEE signs the attestation response with its identity key and returns the result to the proxy.

### Step 4: Retrieve the Proof from the Proxy

Poll `GET /action/result/<instructionId>` on a participating TEE proxy until the proof is available.
The returned action result contains the encoded FDC2 response header, the original request body, the attestation response body, the TEE signature, and the collected signer signatures.

### Step 5: Assemble and Verify the On-Chain Proof

Convert the proxy result into the attestation-specific proof struct described in [FDC2](../Extensions/FDC2/README.md).
Submit that proof to the appropriate on-chain verifier or application contract for the attestation type.

## Attestation-Specific Uses

- [`TeeAvailabilityCheck`](../Extensions/FDC2/AttestationTypes/TeeAvailabilityCheck.md): used by [MachineRegistration.md](MachineRegistration.md) and [MachineLifecycle.md](MachineLifecycle.md) for production entry, availability confirmation, and proof-based suspension.
- [`PMWMultisigAccountConfigured`](../Extensions/FDC2/AttestationTypes/PMWMultisigAccountConfigured.md): used by [XrplMultisigConfiguration.md](XrplMultisigConfiguration.md) to verify the external multisig account setup before linking it on-chain.
- [`PMWPaymentStatus`](../Extensions/FDC2/AttestationTypes/PMWPaymentStatus.md): used by [XrpPayment.md](XrpPayment.md) to verify the outcome of a submitted payment transaction.
- [`PMWFeeProof`](../Extensions/FDC2/AttestationTypes/PMWFeeProof.md): used when fee accounting across a payment range needs to be proven on-chain.

## Notes

- For the exact `Fdc2RequestHeader`, `Fdc2ResponseHeader`, signature computation, and proof-field mapping, follow [FDC2](../Extensions/FDC2/README.md) and [`F_FDC2--PROVE`](../Extensions/FDC2/Commands/Prove.md).
- For attestation-type-specific request and response bodies, use the relevant page in [attestation-types](../Extensions/FDC2/AttestationTypes/README.md).
- Current verifier-server and polling behavior is implementation documentation and is described separately in [FDC2 Verifier Server](../Extensions/FDC2/Verifier.md).
