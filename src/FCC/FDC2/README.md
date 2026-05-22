# Flare TEE Data Connector (FDC2)

FDC2 is a TEE-based variant of the [FDC](../../FDC/Introduction.md), implemented as an application on the [system extension](../FCE/System.md) and managed via the `Fdc2Hub` smart contract.
Users submit attestation requests as [instructions](../Operations/Instructions.md); participating TEE machines, on reaching the data-provider vote threshold, sign the attestation response with their identity key.
The signed attestation is served by the [TEE proxy](../Reference/Components/Proxy.md) and can be published on Flare.

| Page | Contents |
|---|---|
| [Concepts](Concepts.md) | Request flow, attestation types, signature computation, request/response format, on-chain proof assembly. |
| [Verifier](Verifier.md) | HTTP interface of the FDC2 verifier server run by each data provider. |
| [Attestation Types](Reference/AttestationTypes/README.md) | Per-type request and response specifications. |
| [Commands](Reference/Operations/README.md) | The `F_FDC2 PROVE` command. |
