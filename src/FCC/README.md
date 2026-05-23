# Introduction

Flare Confidential Compute (FCC) extends the Flare blockchain with Trusted Execution Environments (TEEs), enabling secure outsourcing of operations to registered cloud-based TEE machines.
A TEE is an isolated operating environment trusted to run specified code and store objects securely in memory; TEEs can attest to their state, ensuring honest execution.

FCC organizes outsourcing through the _Flare Compute Extension_ ([FCE](FCE/README.md)) framework — each extension pairs a set of smart contracts on Flare with one or more registered TEE machines running its code; the contracts define the instructions users can submit, and the machines execute them.
The [System Extension](FCE/System.md) is provided by Flare and hosts two applications: the _Protocol Managed Wallet_ ([PMW](PMW/README.md)) infrastructure for managed external-chain wallets, and the _Flare TEE Data Connector v2_ ([FDC2](FDC2/README.md)), a TEE-based attestation oracle.
Developers can deploy custom extensions with their own contracts and TEE machine code; each extension has a unique extension ID, and its TEE machines are isolated from those of other extensions.

## Further Reading

| Section | Description |
|---------|-------------|
| [Architecture](Architecture.md) | Participants, instruction flow, deployment topology. |
| [Concepts](Concepts/README.md) | Instructions, actions, voting, rewarding, machines, keys, wallets, trust model. |
| [Reference](Reference/Components/README.md) | Off-chain components, on-chain contracts, system operations, types. |
| [FCE](FCE/README.md) | The extension framework and the system FCE. |
| [PMW](PMW/README.md) | Protocol-managed wallet application (XRPL today). |
| [FDC2](FDC2/README.md) | TEE-based attestation oracle. |
| [Workflows](Workflows/README.md) | State-machine-shaped operational procedures. |
