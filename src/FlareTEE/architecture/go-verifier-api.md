# Go Verifier API Architecture

The go-verifier-api is an FDC2 verifier server that validates attestation requests. It implements a pluggable verifier pattern where each attestation type (TeeAvailabilityCheck, PMWPaymentStatus, PMWMultisigAccountConfigured) is loaded as a module with its own verification logic, data sources, and configuration.

![Go Verifier API architecture](images/go-verifier-api.svg)

## Component Overview

## Generic Verifier Pattern

All attestation types implement the same interface:

```go
type Verifier[Req any, Res any] interface {
    Verify(ctx context.Context, req Req) (Res, error)
}
```

Request and response types are defined in `go-flare-common/pkg/tee/structs/connector/autogen.go`, generated from the Solidity interface ABIs. This ensures the verifier's types match the on-chain proof structures exactly.

## HTTP Endpoints

Each loaded attestation type exposes three endpoints:

| Endpoint | Purpose |
|---|---|
| `POST /verifier/{sourceId}/{attestationType}/prepareRequestBody` | ABI-encode a raw request body |
| `POST /verifier/{sourceId}/{attestationType}/prepareResponseBody` | Decode request, run verification, return ABI-encoded response |
| `POST /verifier/{sourceId}/{attestationType}/verify` | Full verification pipeline, return encoded response body |

All endpoints (except `/api/health`) require API key authentication via the `X-API-KEY` header.

### Error Classification

| HTTP Status | Meaning | Examples |
|---|---|---|
| $422$ | Data/validation error | Record not found, TEE validation failure, invalid input |
| $503$ | Infrastructure error (retryable) | DB connection failure, insufficient samples, network error |
| $500$ | Unexpected error | Encoding failure, unknown error |

## Module Loading

The `VERIFIER_TYPE` environment variable determines which attestation type module is loaded at startup. Each module instantiates its own service, verifier, external data connections, and HTTP handlers. Only one attestation type runs per process instance.

## TeeAvailabilityCheck Module

### Verification Flow

1. Fetch the TEE action result from the proxy at `GET /action/result/{instructionId}`.
2. Validate the challenge matches the request.
3. Validate the proxy signature matches `teeProxyId`.
4. **URL validation** — check the proxy URL against SSRF attacks (block private IPs, metadata endpoints, link-local addresses).
5. **CRL checking** — fetch and verify Certificate Revocation Lists for the attestation certificate chain.
6. **JWT validation** — verify the Google Confidential Space attestation token:
   - `eat_nonce` matches the hash of the TEE info data.
   - `dbgstat` equals `disabled-since-boot` (production mode).
   - `swname` equals `CONFIDENTIAL_SPACE`.
   - `submods.confidential_space.support_attributes` contains `STABLE`.
7. **TEE identity check** — verify the `teeId` from the response matches the address derived from the public key.
8. **Signing policy check** — verify `lastSigningPolicyHash` and `initialSigningPolicyHash` match the on-chain values from the Relay contract.
9. Return status: `OK`, `OBSOLETE` (missing `STABLE` attribute), or `DOWN` (from poller).

### TEE Poller

A background goroutine that continuously monitors TEE machine availability:

- **Polling interval**: every $1$ minute.
- **Active machine list**: fetched from the `TeeMachineRegistry` contract.
- **Worker pool**: $10$ concurrent workers query each TEE's proxy `/info` endpoint.
- **Sample management**: retains the latest $5$ samples per TEE in a circular buffer.
- **Sample states**: `VALID` (all checks pass), `INVALID` (data-level failure), `INDETERMINATE` (infrastructure failure).
- **DOWN detection**: if all $5$ samples are `INVALID`, the TEE is reported as `DOWN`.
- **Monitoring endpoint**: `GET /poller/tees` returns all TEE samples for external monitoring.

### External Dependencies

- Flare C-chain RPC (Relay contract, TeeMachineRegistry contract).
- TEE proxy HTTP endpoints (`/info`, `/action/result/*`).
- Google Cloud PKI (root certificates, CRL endpoints).

## PMWPaymentStatus Module

### Verification Flow

1. Compute the deterministic instruction ID from `(opType, PAY, sourceId, senderAddress, nonce)`.
2. Query the C-chain indexer database for the `TeeInstructionsSent` event log matching `extensionId = 0` and the instruction ID.
3. Decode the `PaymentInstructionMessage` from the event.
4. Query the XRP indexer database for the transaction matching `senderAddress` and `nonce` (XRP sequence number).
5. Determine transaction status: `tesSUCCESS` prefix → success ($0$), otherwise → reverted ($1$).
6. Compute `receivedAmount` from `AffectedNodes` in the XRP transaction metadata.
7. Return response with `transactionStatus`, `receivedAmount`, `transactionFee`, `revertReason`, `transactionId`, `blockNumber`, `blockTimestamp`.

### External Dependencies

- PostgreSQL — XRP transaction indexer (source database).
- MySQL — C-chain indexer (event logs).

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

- PostgreSQL — XRP transaction indexer.
- MySQL — C-chain indexer.

## Security

- **API key authentication** — all verification endpoints require a valid `X-API-KEY` header.
- **URL/SSRF validation** — blocks private IPs, metadata endpoints, and dangerous address ranges before connecting to TEE proxies.
- **CRL checking** — certificate revocation lists are fetched and cached (LRU, $4$-hour TTL, max $100$ entries) to detect revoked attestation certificates.
- **Security headers** — `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`.

## Configuration

Key environment variables:

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

## Key Design Decisions

- **One attestation type per process** — simplifies configuration, deployment, and scaling. Different types can be scaled independently.
- **Generic handler registration** — the same HTTP handler code serves all attestation types via Go generics, eliminating duplication.
- **ABI-based type generation** — request/response structs are auto-generated from Solidity ABIs, ensuring on-chain compatibility.
- **Poller-based DOWN detection** — the verifier actively monitors TEE availability rather than relying solely on on-demand checks, enabling faster detection of offline machines.
