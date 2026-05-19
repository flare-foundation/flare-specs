# Flare TEE Data Connector (FDC2)

The Flare Data Connector v2 (FDC2) is an application on the [system extension](../SystemExtension.md), managed via the `Fdc2Hub` smart contract.
It is a TEE-based alternative to the FDC: users submit attestation requests as instructions on the system extension; participating TEE machines, after a sufficient weight of data-provider votes, sign the attestation response with their identity key.
The signed attestation is then available from the TEE proxy and can be published on Flare.

| Page | Contents |
|---|---|
| [Concepts](Concepts.md) | Attestation request/response flow, supported attestation types, signature computation, instruction format, and on-chain proof assembly. |
| [Verifier](Verifier.md) | HTTP interface of the FDC2 verifier server run by each data provider. |
| [Attestation Types](AttestationTypes/README.md) | Per-type request and response specifications. |
| [Commands](Commands/README.md) | `F_FDC2 PROVE` command reference. |
