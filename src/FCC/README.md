# Introduction

Flare Confidential Compute (FCC) extends the Flare blockchain with Trusted Execution Environments (TEEs), enabling secure outsourcing of operations to cloud-based [TEE machines](Concepts/Machines.md).
A TEE is an isolated operating environment trusted to run specified code and store objects securely in memory; TEEs can [attest to their state](Concepts/Machines.md#attestation), ensuring honest execution.

FCC organizes outsourcing through the _Flare Compute Extension_ ([FCE](FCE/README.md)) framework — each extension pairs a set of smart contracts on Flare with one or more TEE machines running its code; the contracts define the [instructions](Concepts/Instructions.md) [users](../Terminology/Roles.md#user) can submit, and the machines execute them.
The [System Extension](FCE/System.md) is provided by Flare and hosts two applications: _Protocol Managed Wallets_ ([PMW](PMW/README.md)) for managed [external-chain wallets](Concepts/Wallets.md), and the _Flare Data Connector 2_ ([FDC2](FDC2/README.md)), a TEE-based attestation oracle.
Developers can deploy custom extensions with their own contracts and TEE machine code; each extension's TEE machines are isolated from those of other extensions.

## Reading Order

1. [Architecture](Architecture.md) — participants, instruction flow, deployment topology.
2. [Concepts](Concepts/README.md) — instructions, actions, voting, rewarding, machines, keys, wallets, trust model.
3. [FCE](FCE/README.md) — the extension framework and the system FCE.
4. [PMW](PMW/README.md) — protocol-managed wallets.
5. [FDC2](FDC2/README.md) — TEE-based attestation oracle.
6. [Workflows](Workflows/README.md) — state-machine-shaped operational procedures.
7. [Reference](Reference/Components/README.md) — off-chain components, on-chain contracts, system operations, types.
