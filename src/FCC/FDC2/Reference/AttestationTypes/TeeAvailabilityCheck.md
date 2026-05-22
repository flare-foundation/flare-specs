# TeeAvailabilityCheck

The `TeeAvailabilityCheck` attestation type verifies that a registered TEE machine is available, running valid code, and has a fresh platform attestation.

## Request

Request body: [`TeeAvailabilityCheck.RequestBody`](../Types/Abi/AttestationType.md#requestbody).

- `teeId`: TEE identity address of the machine to be checked.
- `teeProxyId`: identity address of the paired [TEE proxy](../../../Reference/Components/Proxy.md).
- `url`: HTTP URL of the TEE proxy.
- `challenge`: random challenge for the attestation request.
- `instructionId`: instruction ID of the attestation request.

## Response

Response body: [`TeeAvailabilityCheck.ResponseBody`](../Types/Abi/AttestationType.md#responsebody), using the [`AvailabilityCheckStatus`](../Types/Abi/AttestationType.md#availabilitycheckstatus) enum and [`TeeState`](../../../Reference/Types/Abi/TeeMachine.md#teestate).

- `status`:
  - `OK` — TEE machine is available and valid.
  - `OBSOLETE` — platform state is outdated (`submods.confidential_space.support_attributes` lacks `STABLE`).
  - `DOWN` — TEE machine is unavailable.
- `teeTimestamp`: TEE timestamp from the proxy attestation result.
- `codeHash`: from the `submods.container.image_digest` JWT claim.
- `platform`: from the `hwmodel` JWT claim (e.g. `INTEL_TDX`, `GCP_AMD_SEV`).
- `initialSigningPolicyId`, `lastSigningPolicyId`, `state`: from the proxy attestation result.

## Chain Support

Currently only Google attestations in JWT-token format are supported.

## Verification

The attestation result is fetched from `GET /action/result/<instructionId>` on the [TEE proxy](../../../Reference/Components/Proxy.md); the response body is the `bytes result.message` field.

### Challenge and Identity Checks

- The `challenge` from the request must match the challenge in the proxy info response.
- The `teeProxyId` must match the address recovered from the proxy info response's `proxySignature`.
- The `teeId` must match the address derived from the proxy info response's `publicKey`.

### URL Validation

Before contacting the TEE proxy, the verifier blocks private IPs, link-local and multicast addresses, cloud metadata endpoints, and Teredo tunnels (SSRF guard).

### JWT and Claims Validation

The JWT is verified against Google Cloud Confidential Computing PKI; certificate revocation lists are checked for the leaf and intermediate certificates.
Required claims:

1. Hash of the proxy data matches `eat_nonce`.
2. `swname` equals `CONFIDENTIAL_SPACE`.
3. **Production mode** (gated by the verifier's `ALLOW_TEE_DEBUG` config flag):
   - `ALLOW_TEE_DEBUG = false` (production default): accept only TEEs with `dbgstat = disabled-since-boot`. Reject anything else.
   - `ALLOW_TEE_DEBUG = true` (staging/E2E only): accept both production and debug TEEs. The debug path skips the security-version check below and emits a warning log; debug TEEs MUST NOT be admitted in production deployments (debugger attachable, secrets extractable).
4. **Security version** (production TEEs only): `submods.confidential_space.support_attributes` must contain `STABLE`; if not, status downgrades to `OBSOLETE`.

### Signing Policy Check

- `data.lastSigningPolicyHash` must equal the current signing policy on-chain (`Relay.toSigningPolicyHash(rewardEpochId)`).
- `data.initialSigningPolicyHash` must equal the initial signing policy on-chain (same contract call).

## Verifier-Side Availability Polling

The verifier server also acts as an availability poller, exposing `GET /poller/tees` for external monitoring.
It enumerates active machines via `FlareTeeManager.getAllActiveTeeMachines` and queries `<proxyUrl>/info` for each.
Per machine, the most recent samples are retained in a circular buffer; each sample is classified `VALID` (all checks pass), `INDETERMINATE` (verifier fault, e.g. RPC unreachable), or `INVALID` (data-side failure).

Availability statuses:

- `DOWN`: requires sufficient `INVALID` samples in a row (insufficient samples → `INDETERMINATE`).
- `OBSOLETE`: production TEE missing `STABLE` attribute.
- `OK`: all checks pass.

When no attestation result is available on `/action/result/<instructionId>`, the verifier falls back to the most recent samples — `DOWN` if every recent sample is `INVALID`, otherwise `UNDETERMINED` (HTTP $503$).

## Notes

- Block freshness is not a concern on Flare due to its fast deterministic finality.
