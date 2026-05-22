# Fdc2Attestation

State machine for the shared FDC2 attestation flow used by [`TeeAvailabilityCheck`](../Reference/AttestationTypes/TeeAvailabilityCheck.md), [`PMWMultisigAccountConfigured`](../Reference/AttestationTypes/PMWMultisigAccountConfigured.md), [`PMWPaymentStatus`](../Reference/AttestationTypes/PMWPaymentStatus.md), and [`PMWFeeProof`](../Reference/AttestationTypes/PMWFeeProof.md).
This page covers only the ordering and observable transitions; canonical message formats and signature rules live in [FDC2 Concepts](../Concepts.md) and [`F_FDC2 PROVE`](../Reference/Operations/Prove.md).

## Preconditions

- The participating TEE machines are in `PRODUCTION`.
- [Data providers](../../../Terminology/Roles.md#data-provider) are enrolled in the current signing policy.
- An attestation-type-specific request body is prepared per the [type's spec](../Reference/AttestationTypes/README.md).

## States

- `Unrequested` — no on-chain request exists for this attestation.
- `Requested` — [`Fdc2Hub.requestAttestation`](../Reference/Contracts/Fdc2Hub.md#attestation-requests) (or an upstream convenience entry) has fired; the corresponding [`F_FDC2 PROVE`](../Reference/Operations/Prove.md) instruction is in flight to the selected TEE machines.
- `Voted` — voting on the participating proxies has met both thresholds (data-provider weight, cosigner count if set) and each target TEE machine has signed the attestation response with its identity key.
- `Available` — the signed [`ProveResponse`](../Reference/Types/Wire/Fdc2.md#proveresponse) is served by the target proxies and ready for off-chain retrieval.
- `Verified` — the assembled [`Proof`](../Reference/Types/Abi/Fdc2.md#proof) has been submitted to and accepted by the on-chain verifier.

## Initial State

`Unrequested`.

## Transitions

### requestAttestation: Unrequested → Requested

- **Action**: [`Fdc2Hub.requestAttestation(request, numberOfTees, teeIds, cosigners, cosignersThreshold, claimBackAddress)`](../Reference/Contracts/Fdc2Hub.md#attestation-requests) — payable. Some attestation flows wrap this in a convenience entry on [`FlareTeeManager`](../../Reference/Contracts/FlareTeeManager.md) (e.g. `pauseWithProof`, `toProduction`, `confirmAvailability`) that builds the request internally.
- **Caller**: any address that funds the fee (`proofOwner` controls who may publish the resulting proof).
- **Guards**:
  - `msg.value ≥ Fdc2Hub.getTypeAndSourceFee(attestationType, sourceId)`
  - `header.thresholdBIPS = 0` or `≥ Fdc2Hub.minThresholdBIPS`
  - `numberOfTees` and `teeIds` consistent (see [Fdc2Hub guards](../Reference/Contracts/Fdc2Hub.md#attestation-requests))
- **Effects**:
  - Emits [`AttestationRequested`](../Reference/Contracts/Fdc2Hub.md#attestationrequested) and [`TeeInstructionsSent`](../../Reference/Contracts/FlareTeeManagerEvents.md#teeinstructionssent).
  - Dispatches [`F_FDC2 PROVE`](../Reference/Operations/Prove.md) to the selected TEE machines.

### relayAndVote: Requested → Voted

- **Action**: off-chain — each [data provider](../../../Terminology/Roles.md#data-provider) verifies the requested data, builds the augmented instruction per the [augmentation procedure](../Reference/Operations/Prove.md#augmentation-procedure), and relays signed copies through its [relay client](../../Reference/Components/RelayClient.md). Each TEE proxy runs the [voting process](../../Concepts/Voting.md); on reaching threshold the TEE machine signs the attestation response with its identity key.
- **Caller**: data providers (and cosigners, if any).
- **Guards**:
  - Aggregated provider signatures meet `header.thresholdBIPS` (or the signing-policy default when `thresholdBIPS = 0`).
  - Cosigner signatures meet `cosignersThreshold` if cosigners are listed.
- **Effects**:
  - TEE machine returns a [`ProveResponse`](../Reference/Types/Wire/Fdc2.md#proveresponse) to its proxy.
  - Per-vote [receipts](../../Concepts/Rewarding.md) accumulate.

### serve: Voted → Available

- **Action**: off-chain — proxy makes the `ProveResponse` retrievable via `GET /action/result/<instructionId>`.
- **Caller**: any proxy consumer (typically a data provider preparing the on-chain submission).
- **Guards**: a `ProveResponse` has been stored for the `instructionId`.
- **Effects**: none on-chain; the response is read-available.

### verify: Available → Verified

- **Action**: convert the `ProveResponse` into the per-type [`Proof`](../Reference/Types/Abi/Fdc2.md#proof) struct (see the [response → proof mapping](../Concepts.md#on-chain-proof-assembly)) and submit it to the type-specific verifier entry on [`FlareTeeManager`](../../Reference/Contracts/FlareTeeManager.md) (`verifyAvailabilityCheckProof`, `verifyPMWMultisigAccountConfiguredProof`, …) or directly to a downstream contract.
- **Caller**: the [`proofOwner`](../Concepts.md#request-format) (or anyone, if the request named `address(0)`).
- **Guards**: the contract recomputes the signed digest, recovers the signing TEEs, verifies the data-provider signatures against the relay-format policy signatures, and validates type-specific fields. Any check failure reverts.
- **Effects**: the verifier stores or consumes the proof per its type-specific semantics; the off-chain `Available` state is unchanged.

## Invariants

- A TEE machine in `Voted` has produced exactly one identity signature per `instructionId` it accepted.
- The on-chain digest verified at `verify` is bit-identical to the one signed at `relayAndVote` — both follow the [signature-computation rule](../Concepts.md#signature-computation).
- `Verified` is a downstream-contract observation, not a state stored on `Fdc2Hub`; replays at the verifier are guarded by type-specific rules (timestamps, nonces, freshness windows).

## Terminal States

`Verified` for this sub-workflow. Higher-level workflows that invoke `Fdc2Attestation` consume the verified proof and may move their own state machine forward (e.g. [MachineRegistration § toProduction](../../Workflows/MachineRegistration.md), [XrpPayment](../../PMW/Workflows/XrpPayment.md)).

## Notes

- The exact polling cadence on `GET /action/result` is implementation-level and described in [FDC2 Verifier](../Verifier.md).
- For verifier-server HTTP details that data providers run during `relayAndVote`, see [FDC2 Verifier](../Verifier.md).
