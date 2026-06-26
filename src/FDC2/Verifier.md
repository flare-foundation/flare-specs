# FDC2 Verifier Server

The FDC2 verifier server validates attestation requests on behalf of [data providers](../Terminology/Roles.md#data-provider) as part of the [FDC2](README.md) protocol.
Each data provider runs one verifier instance per supported attestation type.
A single process loads one attestation type module at startup.

## HTTP Endpoints

Each loaded module exposes three verification endpoints, namespaced by `sourceId` and `attestationType`:

| Endpoint | Purpose |
|---|---|
| `POST /verifier/<sourceId>/<attestationType>/prepareRequestBody` | ABI-encode a raw request body. |
| `POST /verifier/<sourceId>/<attestationType>/prepareResponseBody` | Decode the request, run verification, and return an ABI-encoded response body. |
| `POST /verifier/<sourceId>/<attestationType>/verify` | Full verification pipeline; returns the encoded response body. |

All endpoints except `GET /api/health` require API-key authentication via the `X-API-KEY` header.

### Response Codes

| HTTP Status | Meaning | Examples |
|---|---|---|
| $400$ | Bad request | Nonce range exceeds maximum size, malformed input. |
| $422$ | Validation error | Record not found, TEE validation failure, invalid input. |
| $500$ | Unexpected error | Encoding failure, unknown error. |
| $503$ | Retryable infrastructure error | DB connection failure, insufficient samples, network error. |

## Supported Attestation Types

- [TeeAvailabilityCheck](Reference/AttestationTypes/TeeAvailabilityCheck.md)
- [PMWPaymentStatus](Reference/AttestationTypes/PMWPaymentStatus.md)
- [PMWMultisigAccountConfigured](Reference/AttestationTypes/PMWMultisigAccountConfigured.md)
- [PMWFeeProof](Reference/AttestationTypes/PMWFeeProof.md)

## Security

- **API-key authentication**: required on every verification endpoint.
- **Security headers**: `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`.
- **SSRF guards**: proxy URLs are validated before being contacted; private IP ranges, link-local and multicast addresses, cloud metadata endpoints, and Teredo tunnels are blocked.
- **CRL checking**: certificate revocation lists are fetched and cached (LRU, $4$-hour TTL, max $100$ entries) so revoked attestation certificates are rejected.
