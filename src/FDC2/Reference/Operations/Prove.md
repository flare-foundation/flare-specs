# F_FDC2 PROVE

## Description

Processes an [FDC2](../../README.md) attestation request end-to-end: [data providers](../../../Terminology/Roles.md#data-provider) independently validate the request and sign the attestation response; the [TEE machine](../../../FCC/Reference/Components/Machine.md) aggregates the signatures and signs the result with its identity key, producing a [`ProveResponse`](../Types/Wire/Fdc2.md#proveresponse) ready for [on-chain assembly](../../Concepts.md#on-chain-proof-assembly).

Attestation requests reach the TEE proxies as `F_FDC2 PROVE` instructions submitted via the `Fdc2Hub` smart contract.

## Event Message

The event message is the [`Fdc2AttestationRequest`](../Types/Abi/Fdc2.md#fdc2attestationrequest) struct (which contains an [`Fdc2RequestHeader`](../Types/Abi/Fdc2.md#fdc2requestheader)).

The instruction event additionally carries:

- `teeIds`: TEE machines to vote on the request.
- `cosigners`, `cosignersThreshold` (optional): [cosigner](../../../FCC/Concepts/Instructions.md#cosigners) set and threshold. When set, both the data-provider and cosigner thresholds must be reached before the TEE machine signs.

The request header's `thresholdBIPS` field overrides the signing policy's default data-provider voting threshold for this instruction; a value of $0$ falls back to the policy default. See [Signing Threshold Resolution](../../../FCC/Reference/Components/Proxy.md#signing-threshold-resolution).

## Fixed Message

- `attestationResponse`: ABI-encoded attestation response body, validated against the request by each data provider.

## Variable Message

- `signature`: data-provider signature over the [attestation response hash](../../Concepts.md#signature-computation).

## Augmentation Procedure

Before signing, the [relay client](../../../FCC/Reference/Components/RelayClient.md) populates `additionalFixedMessage` and `additionalVariableMessage`:

1. Submit the attestation request to an [FDC2 verifier server](../../Verifier.md) and obtain the encoded response body.
2. Place the response body into `additionalFixedMessage`.
3. Compute the [attestation response hash](../../Concepts.md#signature-computation) and sign it with the relay client's private key.
4. Place the signature into `additionalVariableMessage`.

If the verifier rejects the request, the instruction is dropped; transient errors are retried.

## Additional Action Data

None.

## Action Result

The action result is a [`ProveResponse`](../Types/Wire/Fdc2.md#proveresponse) (which embeds an [`Fdc2ResponseHeader`](../Types/Abi/Fdc2.md#fdc2responseheader)).

## Notes

- **Signed digest:** The TEE constructs the signed hash using the [FDC2 signature computation](../../Concepts.md#signature-computation) — ABI-encode and hash the response header, request body, and response body separately, combine the three hashes, prepend the $6$-byte protocol prefix `0x010000000000`, and hash again.
- **Data-provider signature format:** `DataProviderSignatures` in `ProveResponse` are encoded in [relay format](../../../Utilities/Signing.md) against the current signing policy.
