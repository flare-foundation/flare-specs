# FDC2 Verifier Server

The FDC2 verifier server validates attestation requests on behalf of [data providers](../../Terminology/Roles.md#data-provider) as part of the [FDC2](FDC2.md) protocol.
Each data provider runs a verifier instance for each attestation type it supports.
One attestation type module is loaded at startup per process.

## HTTP Endpoints

Each loaded attestation type exposes three endpoints:

| Endpoint | Purpose |
|---|---|
| `POST /verifier/<sourceId>/<attestationType>/prepareRequestBody` | ABI-encode a raw request body. |
| `POST /verifier/<sourceId>/<attestationType>/prepareResponseBody` | Decode request, run verification, return ABI-encoded response. |
| `POST /verifier/<sourceId>/<attestationType>/verify` | Full verification pipeline, return encoded response body. |

All endpoints (except `/api/health`) require API key authentication via the `X-API-KEY` header.

### Error Classification

| HTTP Status | Meaning | Examples |
|---|---|---|
| $400$ | Bad request | Nonce range exceeds maximum size, malformed input. |
| $422$ | Data/validation error | Record not found, TEE validation failure, invalid input. |
| $503$ | Infrastructure error (retryable) | DB connection failure, insufficient samples, network error. |
| $500$ | Unexpected error | Encoding failure, unknown error. |

## Module Loading

Each module instantiates its own service, verifier, external data connections, and HTTP handlers.
The supported attestation types are:

- [TeeAvailabilityCheck](../AttestationTypes/TeeAvailabilityCheck.md)
- [PMWPaymentStatus](../AttestationTypes/PMWPaymentStatus.md)
- [PMWMultisigAccountConfigured](../AttestationTypes/PMWMultisigAccountConfigured.md)
- [PMWFeeProof](../AttestationTypes/PMWFeeProof.md)

## Security

- **API key authentication** — all verification endpoints require a valid API key header.
- **Security headers** — `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`.
- **URL/SSRF validation** — blocks private IPs, metadata endpoints, and dangerous address ranges before connecting to TEE proxies.
- **CRL checking** — certificate revocation lists are fetched and cached (LRU, $4$-hour TTL, max $100$ entries) to detect revoked attestation certificates.
