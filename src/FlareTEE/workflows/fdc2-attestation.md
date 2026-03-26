# FDC2 Attestation Sub-Workflow

## Overview

This page describes the shared operational flow used by FDC2-based attestations.
The canonical request and response formats, signature rules, and proof assembly remain in [FDC2](../Extensions/FTDC.md), [`F_FDC2--PROVE`](../commands/F_FDC2--PROVE.md), and the individual [attestation type specifications](../attestation-types/index.md).
This workflow focuses only on the order of actions.

The same flow applies to [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md), [`PMWMultisigAccountConfigured`](../attestation-types/PMWMultisigAccountConfigured.md), [`PMWPaymentStatus`](../attestation-types/PMWPaymentStatus.md), and [`PMWFeeProof`](../attestation-types/PMWFeeProof.md).

## Prerequisites

- The participating TEE machines must be in `PRODUCTION` status.
- Data providers must be enrolled in the current signing policy.
- The attestation-specific request body must be prepared according to the relevant attestation specification.

## Steps

### Step 1: Submit the Attestation Request

Submit an attestation request as an [instruction](../Operations/Instructions.md) on the system extension.
Depending on the attestation type, this is done either through a convenience contract such as `TeeVerification` or through `Fdc2Hub.requestAttestation()`.
The request body, source ID, threshold, proof owner, and target TEE list are defined by the owning FDC2 specification.

### Step 2: Providers Verify and Relay the Request

Data providers, and any required cosigners, verify the requested data off-chain.
Each signer then prepares the TEE instruction for the selected machines using the standard FDC2 message layout:

- `additionalFixedMessage`: the encoded request body.
- `additionalVariableMessage`: the signer's signature over the attestation response hash.

The signed instructions are relayed to the relevant TEE proxies.

### Step 3: TEEs Vote and Produce the Signed Response

Each TEE proxy runs the standard [voting process](../Operations/Voting.md) for the attestation instruction.
Once the data-provider threshold, and any cosigner threshold, are satisfied, the TEE signs the attestation response with its identity key and returns the result to the proxy.

### Step 4: Retrieve the Proof from the Proxy

Poll `GET /action/result/<instructionId>` on a participating TEE proxy until the proof is available.
The returned action result contains the encoded FDC2 response header, the original request body, the attestation response body, the TEE signature, and the collected signer signatures.

### Step 5: Assemble and Verify the On-Chain Proof

Convert the proxy result into the attestation-specific proof struct described in [FDC2](../Extensions/FTDC.md).
Submit that proof to the appropriate on-chain verifier or application contract for the attestation type.

## Attestation-Specific Uses

- [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md): used by [machine-registration.md](machine-registration.md) and [machine-lifecycle.md](machine-lifecycle.md) for production entry, availability confirmation, and proof-based suspension.
- [`PMWMultisigAccountConfigured`](../attestation-types/PMWMultisigAccountConfigured.md): used by [xrpl-multisig-configuration.md](xrpl-multisig-configuration.md) to verify the external multisig account setup before linking it on-chain.
- [`PMWPaymentStatus`](../attestation-types/PMWPaymentStatus.md): used by [xrp-payment.md](xrp-payment.md) to verify the outcome of a submitted payment transaction.
- [`PMWFeeProof`](../attestation-types/PMWFeeProof.md): used when fee accounting across a payment range needs to be proven on-chain.

## Notes

- For the exact `Fdc2RequestHeader`, `Fdc2ResponseHeader`, signature computation, and proof-field mapping, follow [FDC2](../Extensions/FTDC.md) and [`F_FDC2--PROVE`](../commands/F_FDC2--PROVE.md).
- For attestation-type-specific request and response bodies, use the relevant page in [attestation-types](../attestation-types/index.md).
- Current verifier-server and polling behavior is implementation documentation and is described separately in [FDC2 Verifier Server](../Extensions/FDC2 Verifier Server.md).
