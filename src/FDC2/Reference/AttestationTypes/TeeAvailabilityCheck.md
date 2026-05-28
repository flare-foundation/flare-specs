# TeeAvailabilityCheck

The `TeeAvailabilityCheck` attestation type proves that a registered [TEE machine](../../../FCC/Concepts/Machines.md) is reachable, running approved code, and still tied to the current [signing policy](../../../FCC/Concepts/Policy.md).

## Request

Request body: [`TeeAvailabilityCheck.RequestBody`](../Types/Abi/AttestationType.md#requestbody).

- `teeId`: TEE identity address of the machine to check.
- `teeProxyId`: identity address of the paired [TEE proxy](../../../FCC/Reference/Components/Proxy.md).
- `url`: HTTP URL of the TEE proxy.
- `challenge`: random challenge for the attestation request.
- `instructionId`: instruction ID under which the request was dispatched.

## Response

Response body: [`TeeAvailabilityCheck.ResponseBody`](../Types/Abi/AttestationType.md#responsebody), using the [`AvailabilityCheckStatus`](../Types/Abi/AttestationType.md#availabilitycheckstatus) enum and [`TeeState`](../../../FCC/Reference/Types/Abi/TeeMachine.md#teestate).

- `status`:
  - `OK` — machine reachable, code accepted, attestation valid.
  - `OBSOLETE` — production TEE running on a non-`STABLE` Confidential Space image (`submods.confidential_space.support_attributes` lacks `STABLE`).
  - `DOWN` — TEE machine is unreachable.
- `teeTimestamp`: local timestamp from the TEE machine.
- `codeHash`: from the `submods.container.image_digest` JWT claim.
- `platform`: from the `hwmodel` JWT claim (e.g. `INTEL_TDX`, `GCP_AMD_SEV`).
- `initialSigningPolicyId`, `lastSigningPolicyId`, `state`: from the machine's attestation payload.

Only Google Cloud Confidential Space JWT attestations are currently supported.

## Verification

The verifier fetches the result from `GET /action/result/<instructionId>` on the [TEE proxy](../../../FCC/Reference/Components/Proxy.md) (the `result.message` bytes).

### Challenge and Identity

- `challenge` matches the challenge in the proxy info response.
- `teeProxyId` matches the address recovered from `proxySignature`.
- `teeId` matches the address derived from the proxy info `publicKey`.

### URL (SSRF Guard)

Before fetching, private IPs, link-local and multicast addresses, cloud metadata endpoints, and Teredo tunnels are blocked.

### JWT and Claims

The JWT is verified against the Google Cloud Confidential Computing PKI, with CRL checks on the leaf and intermediate certificates. Required claims:

- `eat_nonce` equals the hash of the proxy data.
- `swname` equals `CONFIDENTIAL_SPACE`.
- _Production gate_ — `ALLOW_TEE_DEBUG = false` (default) rejects any TEE whose `dbgstat` is not `disabled-since-boot`; `ALLOW_TEE_DEBUG = true` (staging/E2E only) additionally admits debug TEEs, skipping the security-version check below and emitting a warning. Debug TEEs must not be admitted in production deployments.
- _Security version_ (production TEEs only) — `submods.confidential_space.support_attributes` must contain `STABLE`; otherwise the status downgrades to `OBSOLETE`.

### Signing Policy

- `data.lastSigningPolicyHash` equals the current signing policy on-chain (`Relay.toSigningPolicyHash(rewardEpochId)`).
- `data.initialSigningPolicyHash` equals the initial signing policy on-chain (same call).

## On-Chain Consumption

A successful `OK` proof accepted via `confirmAvailability(proof)` — or `toProduction(proof)` from `INITIALIZED` / `PAUSED` / `SUSPENDED` — advances the machine's [availability bounds](../../../FCC/Concepts/Machines.md#availability-deadline), refreshing both `endTs` and the recorded `lastSigningPolicyId`. The machine becomes permissionlessly suspendable as soon as either expires.

Block freshness is not a concern on Flare due to its fast deterministic finality.
