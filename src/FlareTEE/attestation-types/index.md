# Attestation Types

FlareTEE uses the FDC2 protocol to verify off-chain and cross-chain state. Each attestation type defines a specific request/response schema that verifier servers validate before the result is confirmed on-chain.

## Attestation Type Index

| Attestation Type | Description |
|------------------|-------------|
| [TeeAvailabilityCheck](TeeAvailabilityCheck.md) | Verifies that a registered TEE machine is available, running valid code, and has a fresh platform attestation. |
| [PMWPaymentStatus](PMWPaymentStatus.md) | Verifies the status of a payment transaction initiated by a Protocol Managed Wallet on an external chain. |
| [PMWMultisigAccountConfigured](PMWMultisigAccountConfigured.md) | Proves that a multisig account on an external chain is configured correctly for use with Protocol Managed Wallets. |
| [PMWFeeProof](PMWFeeProof.md) | Provides accurate fee accounting for Protocol Managed Wallet payment operations, comparing estimated fees with actual fees on the external chain. |
