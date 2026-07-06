# Flare TEE Data Connector (FDC2)

FDC2 is a TEE-based variant of the [FDC](../FDC/Introduction.md), implemented as an application on the [system extension](../FCC/FCE/System.md) and managed via the `Fdc2Hub` smart contract.
Users submit attestation requests as [instructions](../FCC/Concepts/Instructions.md); on reaching the data provider vote threshold, participating TEE machines sign the attestation response with their identity key.
The signed attestation is served by the [TEE proxy](../FCC/Reference/Components/Proxy.md) and can be published on Flare.

| Page | Contents |
|---|---|
| [Concepts](Concepts.md) | Request flow, attestation types, signature computation, request/response format, on-chain proof assembly. |
| [Verifier](Verifier.md) | HTTP interface of the FDC2 verifier server run by each data provider. |
| [Reference/Contracts/Fdc2Hub](Reference/Contracts/Fdc2Hub.md) | The on-chain hub: request submission, verification, fees, governance. |
| [Reference/AttestationTypes](Reference/AttestationTypes/README.md) | Per-type request and response specifications. |
| [Reference/Operations](Reference/Operations/README.md) | The `F_FDC2 PROVE` operation. |
| [Reference/Types](Reference/Types/Abi/Fdc2.md) | ABI and wire types ([Abi/Fdc2](Reference/Types/Abi/Fdc2.md), [Wire/Fdc2](Reference/Types/Wire/Fdc2.md), [AttestationType](Reference/Types/Abi/AttestationType.md)). |
| [Workflows/Fdc2Attestation](Workflows/Fdc2Attestation.md) | Submit an attestation request and assemble the on-chain proof. |
