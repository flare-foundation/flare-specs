# FTDC Attestation Sub-Workflow

## Overview

The Flare TEE Data Connector (FTDC) is a TEE-based alternative to the FDC for verifying external data on Flare. Unlike the FDC, which uses 90-second rounds and on-chain bit-voting, the FTDC processes requests as they arrive, with data providers voting by submitting attestations directly to participating TEE machines. This yields lower latency and broader request coverage.

The FTDC is managed via the `FtdcHub` smart contract and operates as an application on the [System Extension](../System%20Extension.md). It supports three attestation types used across machine lifecycle and PMW workflows:

- **TeeAvailabilityCheck** -- verifies TEE machine liveness, code integrity, and platform freshness.
- **PMWMultisigAccountConfigured** -- proves correct multisig configuration on an external chain.
- **PMWPaymentStatus** -- verifies the status of a payment transaction on an external chain.

For full details, see the [FTDC specification](../FTDC.md).

## Prerequisites

- TEE machines participating in the attestation must be registered and in `PRODUCTION` status.
- Data providers must be enrolled in the current signing policy.
- The `FtdcHub` smart contract must be deployed and accessible.
- For `TeeAvailabilityCheck`, the verifier server must be running with `VERIFIER_TYPE=TeeAvailabilityCheck`.
- For `PMWMultisigAccountConfigured`, data providers must have access to their own XRP nodes.
- For `PMWPaymentStatus`, the XRP indexer and C-chain indexer databases must be operational.

---

## General FTDC Attestation Flow

All FTDC attestation types follow the same process. The specific request and response bodies vary by attestation type, but the overall flow, voting mechanism, and proof structure are identical.

### Step 1: Submit Attestation Request (User Action)

Submit an attestation request as an [instruction](../Instructions.md) on the System Extension. The request contains:

```solidity
struct FtdcAttestationRequest {
    FtdcRequestHeader header;
    bytes requestBody;
}
```

Additionally, the instruction includes a TEE list (`numberOfTees`, `TeeIds`) indicating which TEE machines should participate. If `numberOfTees` is set to `0`, the `FtdcHub` contract selects machines randomly from the registered set.

Depending on the attestation type, the request is submitted through a convenience contract (e.g., `TeeVerification.requestAvailabilityCheckAttestation()`, `TeeVerification.RequestPMWMultisigAccountConfiguredAttestation()`) or directly via `FtdcHub.RequestAttestation()`.

### Automatic Processing (Steps 2-6)

Once the attestation request is submitted on-chain, the following steps happen automatically without user intervention:

**Step 2: Data Provider Verification** — Data providers pick up the instruction from Flare and confirm off-chain that the `(data, source)` pair in the request represents valid data from the specified source. If the request includes cosigners, they also perform this verification step.

**Step 3: Provider Signs Attestation Response** — Each provider and cosigner packages the instruction together with the attestation response. They prepare a signed TEE instruction including their signature over the attestation response. The instruction fields are:
- `additionalFixedMessage`: The ABI encoding of `requestBody`.
- `additionalVariableMessage`: The signature over the hash generated from the attestation response.

**Step 4: Submit to TEE Proxies** — Each provider sends the signed TEE instruction to the TEE proxies corresponding to the TEE machines listed in `TEE_list`.

**Step 5: TEE Voting** — The [voting process](../Voting.md) for an FTDC request follows the standard instruction voting rules. Upon receiving sufficient weight of data provider signatures (and cosigner signatures exceeding the cosigner threshold), each TEE machine signs the attestation response with its identity key.

**Step 6: TEE Returns Action Result** — The TEE returns the action result to the TEE proxy, including:
- The list of data provider signatures over the attestation response.
- The TEE's own signature over the attestation response.
- Cosigner signatures (if applicable).

### Step 7: Retrieve Proof and Publish On-Chain (User Action)

After submitting the attestation request, poll the TEE proxy until the proof is available, then publish it on-chain:

1. **Poll the proxy** — call `GET <proxy_url>/action/result/<instructionId>` using the `instructionId` from the `TeeInstructionsSent` event emitted in Step 1. Repeat until the response contains a completed proof.
2. **Decode the proof** — parse the response to extract the `FtdcResponseHeader`, `RequestBody`, and `ResponseBody` for the specific attestation type.
3. **Verify and publish on-chain** — call the appropriate verification contract function to validate the proof and apply its result. The specific function depends on the attestation type:
   - **TeeAvailabilityCheck**: `TeeMachineRegistry.toProduction(proof)` or `TeeMachineRegistry.confirmAvailability(proof)` or `TeeMachineRegistry.pauseWithProof(proof)`
   - **PMWMultisigAccountConfigured**: `TeeVerification.verifyPMWMultisigAccountConfiguredProof(walletId, proof)` followed by `TeePayment.AddPMWMultisigAccount(walletId, proof)`
   - **PMWPaymentStatus**: verify via `PMWPaymentStatusVerifier.verify(teePaymentsAddress, proof)`

---

## Request and Response Structures

### FtdcRequestHeader

```solidity
struct FtdcRequestHeader {
    bytes32 attestationType;
    bytes32 sourceId;
    uint16 thresholdBIPS;
    address[] cosigners;
    uint64 cosignersThreshold;
}
```

- `attestationType` -- identifies the attestation type (e.g., `TeeAvailabilityCheck`, `PMWPaymentStatus`).
- `sourceId` -- identifies the data source (e.g., `TEE`, `testXRP`).
- `thresholdBIPS` -- weight of data provider signatures required; must exceed 40%.
- `cosigners` and `cosignersThreshold` -- optional; defines additional cosigner requirements for voting.

Note: When the attestation request is submitted on-chain, `cosigners` and `cosignersThreshold` may be included at the instruction event level rather than in the header itself, depending on how the `sendInstructions` call is structured.

### FtdcResponseHeader

```solidity
struct FtdcResponseHeader {
    bytes32 attestationType;
    bytes32 sourceId;
    uint16 thresholdBIPS;
    address[] cosigners;
    uint64 cosignersThreshold;
    uint64 timestamp;
}
```

Identical to the request header with the addition of a `timestamp` field stating when the response was generated.

### Signing Scheme

The attestation response is signed by data providers, cosigners, and the TEE machine. The signed hash is constructed as:

```
hash(0x010000000000,
    hash(
        hash(ABIencode(response_header)),
        hash(ABIencode(requestBody)),
        hash(ABIencode(responseBody))
    )
)
```

The 38-byte prefix `0x010000000000` matches the format of a protocol message with a Merkle root (`protocolId = 1`, `votingRoundId = 0`, `isSecureRandom = 0`), ensuring interoperability with the existing Relay contract verification used in the FDC.

### Proof Structure

```solidity
struct Proof {
    FtdcSignatures signatures;
    FtdcResponseHeader header;
    RequestBody requestBody;
    ResponseBody responseBody;
}

struct FtdcSignatures {
    bytes signingPolicySignatures;
    Signature[] teeSignatures;
    Signature[] cosignerSignatures;
}
```

Some fields may be empty when there are no cosigners.

---

## TeeAvailabilityCheck

Verifies that a registered TEE machine is available, running valid code, and has a fresh attestation from the platform. Used during machine registration (`toProduction`), periodic availability confirmation (`confirmAvailability`), and pause-with-proof (`pauseWithProof`).

For the full specification, see [TeeAvailabilityCheck](../attestation-types/TeeAvailabilityCheck.md).

### Request Body

```solidity
struct RequestBody {
    address teeId;
    address teeProxyId;
    string url;
    bytes32 challenge;
    bytes32 instructionId;
}
```

- `teeId` -- TEE identity address of the machine to be checked.
- `teeProxyId` -- identity address of the TEE proxy.
- `url` -- URL of the TEE proxy.
- `challenge` -- random challenge for the attestation request.
- `instructionId` -- instruction ID for the attestation request.

### Response Body

```solidity
enum AvailabilityCheckStatus { OK, OBSOLETE, DOWN }

struct TeeAvailabilityCheckTeeState {
    bytes systemState;
    bytes32 systemStateVersion;
    bytes state;
    bytes32 stateVersion;
}

struct ResponseBody {
    AvailabilityCheckStatus status;
    uint64 teeTimestamp;
    bytes32 codeHash;
    bytes32 platform;
    uint32 initialSigningPolicyId;
    uint32 lastSigningPolicyId;
    TeeAvailabilityCheckTeeState state;
}
```

- `status` -- `OK` (available and valid), `OBSOLETE` (platform state outdated, `support_attributes` lacks `STABLE`), or `DOWN` (unavailable).
- `teeTimestamp` -- timestamp obtained from the TEE machine during attestation.
- `codeHash` -- value of the `submods.container.image_digest` claim.
- `platform` -- value of the `hwmodel` claim (e.g., `INTEL_TDX`, `GCP_AMD_SEV`).
- `initialSigningPolicyId` / `lastSigningPolicyId` -- from the TEE proxy attestation result.
- `state` -- TEE state encoding from the TEE proxy attestation result.

### JWT Verification Rules

Currently only Google attestations in JWT token format are supported. The attestation result is obtained from the TEE proxy on `/action/result/<instructionId>`.

1. **Challenge check** -- the `challenge` from the request body is matched against the challenge from the TEE proxy info response.
2. **Proxy signature check** -- the `teeProxyId` is matched against the address recovered from the `proxySignature` of the TEE proxy info response.
3. **Hash verification** -- create a hash from the returned TEE proxy data and compare it with the `eat_nonce` claim.
4. **Production mode** -- verify that `dbgstat` equals `disabled-since-boot`. The `ALLOW_TEE_DEBUG` configuration must be `false` in production.
5. **Running software** -- verify that `swname` equals `CONFIDENTIAL_SPACE`.
6. **Security version** -- verify that `submods.confidential_space.support_attributes` contains `STABLE`.
7. **TEE identity check** -- the `teeId` from the response body is matched against the address derived from the `publicKey` in the TEE proxy info response.
8. **Signing policy check**:
   - Verify that `data.lastSigningPolicyHash` equals the current signing policy on chain (via `Relay.toSigningPolicyHash(uint256 _rewardEpochId)`).
   - Verify that `data.initialSigningPolicyHash` equals the initial signing policy on chain.
   - Signing policy fetching uses aggressive retry parameters (single attempt, 400 ms delay) to stay within the 5-second timeout.

### Verifier Server Behavior (Poller)

The verifier server (`VERIFIER_TYPE=TeeAvailabilityCheck`) also acts as a TEE machine availability poller.

**Polling cycle:** Every minute, the poller queries the `<proxy_url>/info` API for each active TEE machine. The list of active machines is obtained by calling `getAllActiveTeeMachines` on the `TeeMachineRegistry` smart contract. Only the latest 5 samples per machine are retained.

**On each poll:**

1. **Challenge freshness** -- the challenge is generated by the proxy using a block hash. The verifier checks the block's timestamp via RPC. The configured threshold is `BlockFreshnessInSeconds = 150` (2.5 minutes).
2. **Verification checks** -- same JWT token and claims validation, TEE identity check, and signing policy checks as above.
3. **Sample classification:**
   - All checks pass: sample state = `VALID`.
   - Failure due to verifier fault (e.g., cannot connect to RPC): sample state = `INDETERMINATE`.
   - Failure due to provided data: sample state = `INVALID`.

### Status Determination (DOWN Detection)

To reliably detect `DOWN`, the poller must observe only `INVALID` samples for at least 5 minutes:

- If all entries hold sample state `INVALID`: status = `DOWN`.
- Otherwise: status = `INDETERMINATE`.

### Evaluating Availability with Attestation

- **No attestation result available** on `/action/result/<instructionId>`:
  - Fall back to availability checks using recent samples.
  - If all samples in the last 5 minutes are `INVALID`: status = `DOWN`, all other response fields set to 0.
  - Otherwise (at least one `VALID` or `INDETERMINATE` sample): return `UNDETERMINED` (HTTP 503).
- **Attestation result available:**
  - If the platform is obsolete (`support_attributes` lacks `STABLE`): status = `OBSOLETE`.
  - Otherwise, if all JWT checks pass (valid signature, reproducible `eat_nonce`, production mode, safe software, stable version, matching signing policy hashes): status = `OK`.

---

## PMWMultisigAccountConfigured

Proves that a multisig account on an external chain is configured correctly for use with Protocol Managed Wallets. Each data provider uses its own XRP node for verification, mitigating the risk of a single malicious or spoofed node.

For the full specification, see [PMWMultisigAccountConfigured](../attestation-types/PMWMultisigAccountConfigured.md).

### Request Body

- `accountAddress` (`string`) -- address of the multisig account.
- `publicKeys` (`bytes[]`) -- public keys of the multisig account owners (concatenated format: `pubkey.X | pubkey.Y`).
- `threshold` (`uint64`) -- threshold for the multisig account.

### Response Body

- `status` (`uint8`) -- `ok` (correctly configured) or `error` (incorrectly configured).
- `sequence` (`uint64`) -- sequence number of the account.

### XRP Account Validation Rules

The verifier queries `account_info` on an XRP node for the given `accountAddress` and performs:

1. **Validate signer list** -- check `signer_lists` to obtain signer addresses and weights. Convert `publicKeys` from the request body to XRPL account addresses for matching. Verify that each `SignerWeight` equals `1`.
2. **Validate quorum** -- check that `SignerQuorum` matches the requested `threshold`.
3. **Validate account flags** (from `account_flags`):
   - `disableMasterKey` = `true`
   - `depositAuth` = `false`
   - `requireDestinationTag` = `false`
   - `disallowIncomingXRP` = `false`
4. **Validate no regular key** -- check that `result.account_data.RegularKey` does not exist.
5. **Retrieve sequence** -- `sequence` = `result.account_data.Sequence`.

### Result

- All checks pass: `status` = `ok`, `sequence` = `result.account_data.Sequence`.
- Any check fails: `status` = `error`, `sequence` = `0`.

### Usage in Workflows

The PMWMultisigAccountConfigured attestation is used during XRPL multisig setup. For the complete procedure including request submission, proof retrieval, verification, and account registration, see [xrpl-multisig-configuration.md](xrpl-multisig-configuration.md) Steps 3-5.

---

## PMWPaymentStatus

Verifies the status of a payment transaction initiated by a Protocol Managed Wallet on an external chain. Currently only used for XRP.

For the full specification, see [PMWPaymentStatus](../attestation-types/PMWPaymentStatus.md).

### Request Body

- `opType` (`bytes32`) -- wallet operation type (e.g., `F_XRP`).
- `senderAddress` (`string`) -- sender address on the external chain.
- `nonce` (`uint64`) -- batch nonce of the payment instruction.
- `subNonce` (`uint64`) -- sequence number of the payment instruction.

**Nonce semantics by chain:**

| Chain | `nonce` | `subNonce` |
|-------|---------|------------|
| XRP | XRP `sequenceNumber` | XRP `sequenceNumber` (same as nonce) |
| UTXO | Batch identifier | Individual payment instruction index |

### Response Body

- `recipientAddress` (`string`) -- recipient address (from `PaymentInstructionMessage` on C-chain).
- `tokenId` (`bytes32`) -- token ID; `bytes32(0)` means native token.
- `amount` (`uint256`) -- amount in minimal units to be sent.
- `fee` (`uint256`) -- fee in minimal units to be paid.
- `paymentReference` (`bytes32`) -- payment reference.
- `transactionStatus` (`uint8`) -- `0` (success) or `1` (reverted).
- `revertReason` (`string`) -- for XRPL, the transaction result code.
- `receivedAmount` (`uint256`) -- amount actually received on the recipient address.
- `transactionFee` (`uint256`) -- total transaction fee spent.
- `transactionId` (`bytes32`) -- transaction hash on the external chain.
- `blockNumber` (`uint64`) -- block/ledger number.
- `blockTimestamp` (`uint64`) -- block timestamp.

### Transaction Lookup Process

1. **Retrieve PaymentInstructionMessage** -- find the `TeeInstructionsSent` event from the C-chain indexer logs via `extensionId = 0` and:

   ```
   instructionId = keccak256(abi.encode(opType, PAY, sourceId, senderAddress, nonce))
   ```

   If the wallet allows batch transactions, multiple events with the same nonce may exist. Decode the `message` field and filter by `subNonce`.

2. **Find transaction on external chain:**
   - **XRP:** look up via `senderAddress` and `nonce` (or via `paymentReference`).
   - **UTXO:** look up via `paymentReference` (TBD).

3. **Check transaction:**
   - **Transaction not found:** return `UNDETERMINED` / `NOT_FOUND`.
   - **XRP -- Transaction successful:** `transactionStatus` = success, `receivedAmount` = amount received, `transactionFee` = fee, `revertReason` = empty.
   - **XRP -- Transaction reverted** (status != `tesSUCCESS`): `transactionStatus` = reverted, `receivedAmount` = 0, `transactionFee` = fee, `revertReason` = actual transaction result code.

### Chain-Specific Semantics

The XRP Ledger uses deterministic consensus-based finality (validated ledgers are final), so transaction reorgs are not a concern and no minimum confirmation block requirements are needed.

The XRP indexer supports finding transactions via `sourceAddress` and `nonce`, as well as via `paymentReference`. The `deliveredAmount` and receiver can be calculated from `AffectedNodes` in the XRP transaction metadata. For partial payments, consult the `delivered_amount` field documentation.

### Usage in Workflows

The PMWPaymentStatus attestation is used to verify completed payments. For the complete procedure including request submission, proof retrieval, and verification, see [xrp-payment.md](xrp-payment.md) Step 4.

---

## Further Resources

| Attestation Type | Reference Implementation |
|-----------------|------------------------|
| TeeAvailabilityCheck | `go-verifier-api/` (verifier server) |
| PMWMultisigAccountConfigured | `e2e/pkg/utils/xrp.go` (`RequestAndVerifyMultisigProof`) |
| PMWPaymentStatus | `e2e/pkg/utils/xrp.go` (`VerifyPMWPayment`) |
