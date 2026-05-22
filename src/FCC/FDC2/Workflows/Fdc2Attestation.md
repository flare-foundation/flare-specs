# FDC2 Attestation Sub-Workflow

## Overview

This page describes the shared operational flow used by FDC2-based attestations.
The canonical request and response formats, signature rules, and proof assembly remain in [FDC2](../README.md), [`F_FDC2--PROVE`](../Reference/Operations/Prove.md), and the individual [attestation type specifications](../Reference/AttestationTypes/README.md).
This workflow focuses only on the order of actions.

The same flow applies to [`TeeAvailabilityCheck`](../Reference/AttestationTypes/TeeAvailabilityCheck.md), [`PMWMultisigAccountConfigured`](../Reference/AttestationTypes/PMWMultisigAccountConfigured.md), [`PMWPaymentStatus`](../Reference/AttestationTypes/PMWPaymentStatus.md), and [`PMWFeeProof`](../Reference/AttestationTypes/PMWFeeProof.md).

## Prerequisites

- The participating TEE machines must be in `PRODUCTION` status.
- [Data providers](../../../Terminology/Roles.md#data-provider) must be enrolled in the current signing policy.
- The attestation-specific request body must be prepared according to the relevant attestation specification.

## Steps

### Step 1: Submit the Attestation Request

Submit an attestation request as an [instruction](../../Concepts/Instructions.md) on the system extension.
Depending on the attestation type, this is done either through a convenience contract such as the verification entry points on [`FlareTeeManager`](../../Reference/Contracts/FlareTeeManager.md), or directly through `Fdc2Hub.requestAttestation()`.
The request body, source ID, threshold, proof owner, and target TEE list are defined by the owning FDC2 specification.

### Step 2: Providers Verify and Relay the Request

Data providers, and any required [cosigners](../../Concepts/Instructions.md#cosigners), verify the requested data off-chain.
Each signer then prepares the instruction for the selected machines using the standard FDC2 message layout:

- `additionalFixedMessage`: the ABI-encoded attestation response body.
- `additionalVariableMessage`: the signer's signature over the attestation response hash.

The signed instructions are relayed to the target TEE proxies.

### Step 3: TEEs Vote and Produce the Signed Response

Each TEE proxy runs the standard [voting process](../../Concepts/Voting.md) for the attestation instruction.
Once the data-provider threshold, and any cosigner threshold, are satisfied, the TEE signs the attestation response with its identity key and returns the result to the proxy.

### Step 4: Retrieve the Proof from the Proxy

Poll `GET /action/result/<instructionId>` on a participating TEE proxy until the proof is available.
The returned action result contains the encoded FDC2 response header, the original request body, the attestation response body, the TEE signature, and the collected signer signatures.

### Step 5: Assemble and Verify the On-Chain Proof

Convert the proxy result into the attestation-specific proof struct described in [FDC2](../README.md).
Submit that proof to the appropriate on-chain verifier or application contract for the attestation type.

## Attestation-Specific Uses

- [`TeeAvailabilityCheck`](../Reference/AttestationTypes/TeeAvailabilityCheck.md): used by [MachineRegistration.md](../../Workflows/MachineRegistration.md) and [MachineLifecycle.md](../../Workflows/MachineLifecycle.md) for production entry, availability confirmation, and proof-based suspension.
- [`PMWMultisigAccountConfigured`](../Reference/AttestationTypes/PMWMultisigAccountConfigured.md): used by [XrplMultisigConfiguration.md](../../PMW/Workflows/XrplMultisigConfiguration.md) to verify the external multisig account setup before linking it on-chain.
- [`PMWPaymentStatus`](../Reference/AttestationTypes/PMWPaymentStatus.md): used by [XrpPayment.md](../../PMW/Workflows/XrpPayment.md) to verify the outcome of a submitted payment transaction.
- [`PMWFeeProof`](../Reference/AttestationTypes/PMWFeeProof.md): used when fee accounting across a payment range needs to be proven on-chain.

## Notes

- For the exact `Fdc2RequestHeader`, `Fdc2ResponseHeader`, signature computation, and proof-field mapping, follow [FDC2](../README.md) and [`F_FDC2--PROVE`](../Reference/Operations/Prove.md).
- For attestation-type-specific request and response bodies, use the relevant page in [attestation-types](../Reference/AttestationTypes/README.md).
- Current verifier-server and polling behavior is implementation documentation and is described separately in [FDC2 Verifier Server](../Verifier.md).
