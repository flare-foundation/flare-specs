# Go Verifier API Architecture

The Go verifier API is an FDC2 verifier server that validates attestation requests.
Each attestation type is loaded as a module with its own verification logic, data sources, and configuration.

![Go Verifier API architecture](images/go-verifier-api.svg)

## HTTP Endpoints

Each loaded attestation type exposes three endpoints:

| Endpoint | Purpose |
|---|---|
| `POST /verifier/<sourceId>/<attestationType>/prepareRequestBody` | ABI-encode a raw request body |
| `POST /verifier/<sourceId>/<attestationType>/prepareResponseBody` | Decode request, run verification, return ABI-encoded response |
| `POST /verifier/<sourceId>/<attestationType>/verify` | Full verification pipeline, return encoded response body |

All endpoints (except `/api/health`) require API key authentication via the `X-API-KEY` header.

### Error Classification

| HTTP Status | Meaning | Examples |
|---|---|---|
| $422$ | Data/validation error | Record not found, TEE validation failure, invalid input |
| $503$ | Infrastructure error (retryable) | DB connection failure, insufficient samples, network error |
| $500$ | Unexpected error | Encoding failure, unknown error |

## Module Loading

One attestation type module is loaded at startup per process.
Each module instantiates its own service, verifier, external data connections, and HTTP handlers.

## TeeAvailabilityCheck Module

### Verification Flow

1. Fetch the TEE action result from the proxy.
2. Validate the challenge matches the request.
3. Validate the proxy signature matches `teeProxyId`.
4. Validate the proxy URL against SSRF attacks.
5. Verify Certificate Revocation Lists for the attestation certificate chain.
6. Validate the platform attestation token (production mode, correct software, stable version).
7. Verify the $\mathrm{TEE}_{\mathrm{ID}}$ from the response matches the address derived from the public key.
8. Verify signing policy hashes match the on-chain values from the Relay contract.
9. Return status: `OK`, `OBSOLETE` (missing `STABLE` attribute), or `DOWN` (from poller).

### TEE Poller

Background process monitoring TEE machine availability.
Periodically queries each active TEE machine's proxy for attestation data.
Classifies samples as `VALID` (all checks pass), `INVALID` (data-level failure), or `INDETERMINATE` (infrastructure failure).
If all recent samples are `INVALID`, the TEE is reported as `DOWN`.

### External Dependencies

- Flare C-chain RPC (Relay contract, TeeMachineRegistry contract).
- TEE proxy HTTP endpoints (`/info`, `/action/result/*`).
- Google Cloud PKI (root certificates, CRL endpoints).

## PMWPaymentStatus Module

### Verification Flow

1. Compute the deterministic instruction ID from `(opType, PAY, sourceId, senderAddress, nonce)`.
2. Query the C-chain indexer for the `TeeInstructionsSent` event log matching `extensionId = 0` and the instruction ID.
3. Decode the `PaymentInstructionMessage` from the event.
4. Query the XRP indexer for the transaction matching `senderAddress` and `nonce` (XRP sequence number).
5. Determine transaction status: `tesSUCCESS` prefix → success, otherwise → reverted.
6. Compute `receivedAmount` from `AffectedNodes` in the XRP transaction metadata.
7. Return response with `transactionStatus`, `receivedAmount`, `transactionFee`, `revertReason`, `transactionId`, `blockNumber`, `blockTimestamp`.

### External Dependencies

- XRP transaction indexer (source database).
- C-chain indexer (event logs).

## PMWMultisigAccountConfigured Module

### Verification Flow

1. Query `account_info` on an XRP node with `ledger_index: "validated"` and `signer_lists: true`.
2. Validate the signer list: convert request public keys to XRP addresses, verify each has `SignerWeight = 1`.
3. Validate `SignerQuorum` matches the requested `threshold`.
4. Validate account flags: `disableMasterKey = true`, `depositAuth = false`, `requireDestinationTag = false`, `disallowIncomingXRP = false`.
5. Validate no `RegularKey` is set.
6. Return `OK` with the account's `Sequence`, or `ERROR` with sequence $0$.

### External Dependencies

- XRP Ledger RPC (JSON-RPC `account_info`).

## PMWFeeProof Module

### Verification Flow

1. For each nonce in `[fromNonce, toNonce]`:
   - Compute instruction ID for the `PAY` event and fetch it from the C-chain indexer.
   - Iteratively fetch `REISSUE` events (reissue numbers $0, 1, 2, \dots$) until none found.
   - Only include events with block timestamp $\leq$ `untilTimestamp`.
   - Compute `estimatedFee` using the residual formula.
2. Query the XRP indexer for all executed transactions in the nonce range.
3. Sum actual transaction fees as `actualFee`.
4. Return `(actualFee, estimatedFee)`.

### External Dependencies

- XRP transaction indexer.
- C-chain indexer.

---

## Implementation Details

### Generic Verifier Pattern

All attestation types implement the same Go interface:

```go
type Verifier[Req any, Res any] interface {
    Verify(ctx context.Context, req Req) (Res, error)
}
```

Request and response types are defined in `go-flare-common/pkg/tee/structs/connector/autogen.go`, generated from Solidity interface ABIs to match the on-chain proof structures.

### TEE Poller Internals

- **Polling interval**: every $1$ minute.
- **Active machine list**: fetched from the `TeeMachineRegistry` contract.
- **Worker pool**: $10$ concurrent workers query each TEE's proxy `/info` endpoint.
- **Sample management**: retains the latest $5$ samples per TEE in a circular buffer.
- **DOWN detection**: if all $5$ samples are `INVALID`, the TEE is reported as `DOWN`.
- **Monitoring endpoint**: `GET /poller/tees` returns all TEE samples for external monitoring.

### JWT Validation (TeeAvailabilityCheck)

Google Confidential Space attestation token checks:

- `eat_nonce` matches the hash of the TEE info data.
- `dbgstat` equals `disabled-since-boot` (production mode).
- `swname` equals `CONFIDENTIAL_SPACE`.
- `submods.confidential_space.support_attributes` contains `STABLE`.

### Security

- **API key authentication** — all verification endpoints require a valid `X-API-KEY` header.
- **URL/SSRF validation** — blocks private IPs, metadata endpoints, and dangerous address ranges before connecting to TEE proxies.
- **CRL checking** — certificate revocation lists are fetched and cached (LRU, $4$-hour TTL, max $100$ entries) to detect revoked attestation certificates.
- **Security headers** — `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`.

### Configuration

Environment variables:

| Variable | Required For | Description |
|---|---|---|
| `PORT` | All | HTTP server port |
| `API_KEYS` | All | Comma-separated API keys |
| `VERIFIER_TYPE` | All | Attestation type to load |
| `SOURCE_ID` | All | Source identifier (`TEE`, `XRP`, `testXRP`) |
| `RPC_URL` | TEE, Multisig | Flare C-chain or XRP RPC |
| `RELAY_CONTRACT_ADDRESS` | TEE | Relay contract address |
| `TEE_MACHINE_REGISTRY_CONTRACT_ADDRESS` | TEE | Machine registry address |
| `SOURCE_DATABASE_URL` | Payment, Fee | PostgreSQL connection string |
| `CCHAIN_DATABASE_URL` | Payment, Fee | MySQL connection string |
