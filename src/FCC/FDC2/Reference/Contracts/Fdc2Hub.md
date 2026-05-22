# Fdc2Hub

The `Fdc2Hub` contract is the FDC2-side on-chain hub.
It receives attestation requests from users, routes them to the TEE machines registered to the [system extension](../../../FCE/System.md) via [`FlareTeeManager.sendInstructions`](../../../Reference/Contracts/FlareTeeManager.md#sending-instructions) as [`F_FDC2 PROVE`](../Operations/Prove.md) instructions, and later verifies the assembled proofs on-chain for downstream consumers.

The op-type is the constant `bytes32("F_FDC2")`.

For the user-facing semantics — request flow, signature computation, on-chain proof assembly — see [FDC2 Concepts](../../Concepts.md). For on-machine processing, see [`F_FDC2 PROVE`](../Operations/Prove.md). Request/response types live in [Types/Abi/Fdc2](../Types/Abi/Fdc2.md) and [Types/Wire/Fdc2](../Types/Wire/Fdc2.md).

## Attestation Requests

```solidity
function requestAttestation(
    Fdc2AttestationRequest calldata _attestationRequest,
    uint256 _numberOfTees,
    address[] memory _teeIds,
    address[] memory _cosigners,
    uint64 _cosignersThreshold,
    address _claimBackAddress
) external payable;
```

Submits an attestation request. Payable; `msg.value` must cover the configured fee for the request's `(attestationType, sourceId)` pair (see [Fee Configuration](#fee-configuration)).

| Argument | Description |
|---|---|
| `_attestationRequest` | The [`Fdc2AttestationRequest`](../Types/Abi/Fdc2.md#fdc2attestationrequest) — header (`attestationType`, `sourceId`, optional `thresholdBIPS` override, optional `proofOwner`) plus the type-specific `requestBody`. |
| `_numberOfTees` | Number of TEE machines to dispatch the request to. If `0`, falls back to the configured default (see [Governance](#governance)). If `_teeIds` is non-empty, must equal `_teeIds.length`. |
| `_teeIds` | Optional explicit list of destination TEE machines. Empty means the contract picks `_numberOfTees` machines from the registered set. |
| `_cosigners` | Optional cosigner address set; recovered against `recoverCosigners` at verification time. |
| `_cosignersThreshold` | Cosigner threshold; must be `0` if `_cosigners` is empty. |
| `_claimBackAddress` | Optional address that may reclaim the fee if the instructions fail to execute. |

The `header.thresholdBIPS` value, when non-zero, overrides the data-provider [voting threshold](../../../Concepts/Voting.md#pass-conditions) for this specific request; `0` falls back to the signing-policy default (subject to [`setMinThresholdBIPS`](#governance)).

Emits [`AttestationRequested`](#events) followed by [`TeeInstructionsSent`](../../../Reference/Contracts/FlareTeeManagerEvents.md#teeinstructionssent) via `FlareTeeManager`.

## Verification

After the TEE machines have produced a signed [`ProveResponse`](../Types/Wire/Fdc2.md#proveresponse), downstream consumers verify it using these on-chain views. The `Fdc2Hub` implements `IFdc2Verification`.

```solidity
function verifySigningPolicySignatures(
    bytes calldata _signingPolicySignatures,
    bytes32 _messageHash
) external returns (uint256 _rewardEpochId);
```

Verifies a batch of data-provider signatures (packed in [relay format](../../../../FSP/Encoding.md)) against `_messageHash` using the corresponding signing policy. Returns the reward-epoch id of the policy that reached threshold.

```solidity
function verifyTeeSignature(
    Signature calldata _signature,
    bytes32 _messageHash
) external view returns (address _signingTeeId);

function verifyTeeSignatures(
    Signature[] calldata _signatures,
    bytes32 _messageHash
) external view returns (address[] memory _signingTeeIds);
```

Recover the signing TEE machine address from one or several TEE signatures and validate that each is a currently-attested machine of the system extension. Reverts with `TeeMachineNotAvailable`, `InvalidTeeMachineExtensionId`, or `DuplicatedTeeId` on failure.

```solidity
function recoverCosigners(
    Signature[] calldata _signatures,
    bytes32 _messageHash
) external view returns (address[] memory _cosigners);
```

Recovers cosigner addresses from signatures and checks for duplicates. Performs no policy validation — the caller must compare the result against the cosigner set committed in `Fdc2ResponseHeader`.

## Fee Configuration

```solidity
function getTypeAndSourceFee(
    bytes32 _type,
    bytes32 _source
) external view returns (uint256);
```

Returns the base fee in wei for an `(attestationType, sourceId)` pair. Reverts with `TypeAndSourceCombinationNotSupported` if the pair has no configured fee. Governance sets the fee per pair, emitting [`TypeAndSourceFeeSet`](#events) / [`TypeAndSourceFeeRemoved`](#events).

## Governance

```solidity
function setMinThresholdBIPS(uint16 _minThresholdBIPS) external;
function setDefaultNumberOfTees(uint8 _defaultNumberOfTees) external;
```

- `setMinThresholdBIPS` — lower bound on `header.thresholdBIPS` overrides. `0` means no minimum (signing-policy default applies). Emits [`MinThresholdBIPSSet`](#events).
- `setDefaultNumberOfTees` — default `_numberOfTees` when callers pass `0`. Must be non-zero. Emits [`DefaultNumberOfTeesSet`](#events).

Both are governance-only.

## Events

### AttestationRequested

```solidity
event AttestationRequested(
    bytes32 indexed instructionId,
    bytes32 indexed attestationType,
    bytes32 indexed sourceId,
    address proofOwner,
    address claimBackAddress,
    uint256 fee
);
```

### MinThresholdBIPSSet

```solidity
event MinThresholdBIPSSet(uint16 minThresholdBIPS);
```

### DefaultNumberOfTeesSet

```solidity
event DefaultNumberOfTeesSet(uint8 defaultNumberOfTees);
```

### TypeAndSourceFeeSet

```solidity
event TypeAndSourceFeeSet(bytes32 indexed attestationType, bytes32 indexed source, uint256 fee);
```

### TypeAndSourceFeeRemoved

```solidity
event TypeAndSourceFeeRemoved(bytes32 indexed attestationType, bytes32 indexed source);
```

## Errors

| Error | Condition |
|---|---|
| `ThresholdInvalid` | `header.thresholdBIPS` is below the configured minimum (when non-zero) or outside the legal range. |
| `NumberOfTeesAndTeeIdsInvalid` | `_numberOfTees` mismatches `_teeIds.length`, or both are zero with no default configured. |
| `CosignersThresholdInvalid` | `_cosignersThreshold` is non-zero with empty `_cosigners`, or exceeds `_cosigners.length`. |
| `MultipleResponsesPossible` | Configuration would let more than one valid response exist for the request (e.g., conflicting threshold settings). |
| `DuplicatedTeeId` | `_teeIds` contains a duplicate, or duplicate TEE signatures recovered. |
| `TeeMachineNotAvailable` | A destination machine (or signing machine) is not currently attested and in `PRODUCTION`. |
| `OnlySystemExtensionId` | A signing TEE machine is not registered to the system extension. |
| `FeeTooLow` | `msg.value` is less than the configured fee for `(attestationType, sourceId)`. |
| `MinThresholdInvalid` | `setMinThresholdBIPS` called with an out-of-range value. |
| `DefaultNumberOfTeesZero` | `setDefaultNumberOfTees` called with `0`. |
| `FeeMustBeGreaterThanZero` / `FeeNotSet` / `TypeAndSourceCombinationNotSupported` | Fee-configuration errors. |
