# F_FDC2 PROVE

## Description

Processes an FDC2 attestation request end-to-end: data providers independently validate and sign the attestation response, and the TEE machine aggregates the signatures into a complete signed proof. The PROVE instruction can be issued for any attestation type supported by the FDC verifier infrastructure. A new version (v2) of Flare Data Connector (FDC) is implemented using PMW infrastructure. It leverages the format and verifier infrastructure of the existing FDC. Attestation requests are submitted through the `Fdc2Hub` smart contract.

## Event message

The event message is formatted as the [`Fdc2AttestationRequest`](../Types/Abi/Fdc2.md#fdc2attestationrequest) struct, containing a [`Fdc2RequestHeader`](../Types/Abi/Fdc2.md#fdc2requestheader).

Additionally, the instruction event includes:

- `teeIds` — list of TEE IDs on which the voting is carried out.
- `cosigners` — (optional) list of cosigner addresses.
- `cosignersThreshold` — (optional) cosigners threshold. A TEE machine signs the attestation response only if both data providers and cosigners achieve their respective thresholds.

## Fixed message

- `attestationResponse` — attestation response, validated against the request by each data provider.

## Variable message

- `signature` — signature by data provider of the attestation response only.

## Additional action data

/

## Action result

The action result is formatted as the [`ProveResponse`](../Types/Wire/Fdc2.md#proveresponse) struct, which contains a [`Fdc2ResponseHeader`](../Types/Abi/Fdc2.md#fdc2responseheader).

## Notes

- **Message hash construction:** The TEE constructs the signed hash by separately ABI-encoding and hashing the response header, request body, and response body, combining the three hashes, prepending a $6$-byte protocol prefix (`0x010000000000`), and hashing the result. This format ensures interoperability with the existing Relay contract verification used in the FDC.
- **Data provider signatures:** Data provider signatures are encoded in relay format using the signing policy, enabling on-chain verification through the existing Relay contract infrastructure.
