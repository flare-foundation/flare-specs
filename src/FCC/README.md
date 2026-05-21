# Introduction

Flare Confidential Compute (FCC) extends the Flare blockchain with Trusted Execution Environments (TEEs), enabling the secure outsourcing of operations to registered cloud-based TEE machines.
A TEE is an isolated operating environment trusted to run specified code and store objects securely in memory.
TEEs can attest to their state, ensuring honest execution of instructions in accordance with their code.

## Instruction Flow

Flare users issue instructions to TEEs via smart contracts on Flare.
[Data providers](../Terminology/Roles.md#data-provider) monitor the chain for these instructions, sign them, and relay them to the TEE network.
Once a TEE has received the instruction from a majority of data providers, it executes it and produces an [action response](Operations/Actions.md#action-responses).
Action responses are publicly available from the TEE proxy and can be relayed back on-chain.
Actions may also have external side effects: a PMW action signs a transaction on an external blockchain, and a custom [extension](#extensions) action can interact with any external service.
Some TEE deployments also allow [_direct actions_](Operations/Actions.md#direct-actions) that bypass the on-chain flow entirely while still executing on the same TEE machines.

## Extensions

FCC manages the outsourcing of operations through a system of _extensions_.
An extension consists of smart contracts on Flare and one or more registered TEE machines running the extension's code.
The contracts define the instructions users can submit; the TEE machines execute them in a secure environment.
For example, the [System Extension](Extensions/SystemExtension.md) hosts the PMW infrastructure, allowing users to submit transaction instructions for their external wallets on Flare to be executed by the extension's TEE machines.

Developers can create their own FCC extensions, defining custom smart contracts and TEE machine software.
Each extension is identified by a unique extension ID, and its TEE machines are isolated from those of other extensions.

## Further Reading

| Section | Description |
|---------|-------------|
| [Architecture](Architecture.md) | System components, deployment topology, and trust model. |
| [Operations](Operations/Instructions.md) | How instructions, actions, voting, and relay clients work. |
| [Extensions](Extensions/README.md) | The extension framework and built-in extensions (PMW, FDC2, System Extension). |
| [TEE Management](TeeManagement/Registration.md) | Machine registration, key management, state attestation, and the TEE proxy. |
| [Commands](Operations/Commands/README.md) | Reference for all TEE command types. |
| [Workflows](Workflows/README.md) | Step-by-step operational procedures. |
| [Attestation Types](Extensions/FDC2/AttestationTypes/README.md) | FDC2 attestation request and response schemas. |
| [Types](Types/README.md) | ABI and wire data structures used across the specification. |
