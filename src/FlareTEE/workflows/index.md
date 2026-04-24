# FCC Workflow Documentation

## Overview

This directory contains step-by-step operational workflows for the FCC system.
The consolidated specification in `../` remains the canonical source for protocol semantics, data structures, and ownership rules.
These workflow documents describe how to perform end-to-end tasks, and they should point back to the core specification whenever a concept is defined there.

Each workflow document follows a consistent format:
- *Overview* and *Prerequisites* sections.
- Numbered steps with contract function names.
- For each step: *Who can call*, *Parameters*, *Requirements*, *What happens*, and *Events emitted*.
- Status transitions where applicable.
- Cross-references to canonical specification pages and related workflows.

## Dependency Graph

The workflows build on each other. Complete earlier workflows before attempting later ones.

```
   extension-configuration
              │
     ┌────────┼──────────┐
     ▼        ▼          │
  machine-  machine-     │
  registration lifecycle │
     │                   │
     ▼                   │
  wallet-setup           │
     │                   │
     ├────────────────┐  │
     ▼                ▼  ▼
  xrpl-multisig-   key-add / key-delete / key-restore
  configuration
     │
     ▼
  xrp-payment

  wallet-setup (with VRF key)
              │
              ▼
        vrf-proof

  extension-configuration + wallet-setup
              │
              ▼
     extension-instructions

  All single-TEE workflows
              │
              ▼
     multi-tee-operations
```

> **FDC2 Attestation** is a shared sub-workflow invoked from within other workflows, not a standalone prerequisite. The following workflows use FDC2 attestation:
> - **TeeAvailabilityCheck** — used in [MachineRegistration.md](MachineRegistration.md) (Steps 9-10), [MachineLifecycle.md](MachineLifecycle.md) (Steps 1, 6), and [MultiTeeOperations.md](MultiTeeOperations.md) (Step 1)
> - **PMWMultisigAccountConfigured** — used in [XrplMultisigConfiguration.md](XrplMultisigConfiguration.md) (Steps 3-5) and [MultiTeeOperations.md](MultiTeeOperations.md) (Step 3)
> - **PMWPaymentStatus** — used in [XrpPayment.md](XrpPayment.md) (Step 4) and [MultiTeeOperations.md](MultiTeeOperations.md) (Step 4)

## Workflow Index

| Workflow | Description | Key Contracts | Spec References |
|----------|-------------|---------------|-----------------|
| [Fdc2Attestation.md](Fdc2Attestation.md) | FDC2 attestation sub-workflow — not standalone; invoked from within machine, multisig, and payment workflows | `Fdc2Hub`, `TeeVerification` | [FDC2](../Extensions/FDC2.md), [AttestationTypes/](../AttestationTypes/) |
| [ExtensionConfiguration.md](ExtensionConfiguration.md) | Register and configure a custom TEE extension (extensionId > 0) | `TeeExtensionRegistry` | [Extensions](../Extensions/Overview.md), [System Extension](../Extensions/SystemExtension.md) |
| [MachineRegistration.md](MachineRegistration.md) | Deploy a TEE machine from VM boot to PRODUCTION status | `TeeMachineRegistry`, `TeeExtensionRegistry`, `TeeVerification` | [Registration](../TeeManagement/Registration.md), [State and Attestation](../TeeManagement/StateAndAttestation.md) |
| [WalletSetup.md](WalletSetup.md) | Create a project and configure a wallet through to PRODUCTION | `TeeWalletProjectManager`, `TeeWalletManager`, `TeeWalletKeyManager` | [Projects and Configuration](../Operations/ProjectsAndConfiguration.md), [Key Management](../TeeManagement/KeyManagement.md) |
| [XrplMultisigConfiguration.md](XrplMultisigConfiguration.md) | Bind an XRPL multisig account to a TEE-managed wallet | `TeePayments`, `TeeVerification` | [PMW](../Extensions/PMW/PMW.md), [PMWMultisigAccountConfigured](../AttestationTypes/PMWMultisigAccountConfigured.md) |
| [XrpPayment.md](XrpPayment.md) | Execute, reissue, or nullify XRP payments through a TEE wallet | `TeePayments` | [Transactions](../Extensions/PMW/Transactions.md), [PMWPaymentStatus](../AttestationTypes/PMWPaymentStatus.md) |
| [KeyAdd.md](KeyAdd.md) | Add a new signing key to a TEE machine | `TeeWalletKeyManager` | [Key Management](../TeeManagement/KeyManagement.md), [Projects and Configuration](../Operations/ProjectsAndConfiguration.md) |
| [KeyDelete.md](KeyDelete.md) | Delete a key from a TEE machine and clean up stale TEE IDs | `TeeWalletKeyManager` | [Key Management](../TeeManagement/KeyManagement.md) |
| [KeyRestore.md](KeyRestore.md) | Restore a key from backup onto a new TEE machine | `TeeWalletKeyManager`, `TeeWalletBackupManager` | [Key Management](../TeeManagement/KeyManagement.md) |
| [MachineLifecycle.md](MachineLifecycle.md) | Post-registration machine operations: pause, resume, upgrade, ownership transfer | `TeeMachineRegistry` | [Registration](../TeeManagement/Registration.md), [State and Attestation](../TeeManagement/StateAndAttestation.md) |
| [ExtensionInstructions.md](ExtensionInstructions.md) | Send custom instructions to extensions and retrieve the result | `TeeExtensionRegistry` | [Extensions](../Extensions/Overview.md), [Actions](../Operations/Actions.md) |
| [VrfProof.md](VrfProof.md) | Generate and verify a VRF proof using a TEE-managed VRF key | `TeeWalletKeyManager`, `TeeVRFVerifier` | [Key Management](../TeeManagement/KeyManagement.md), [F_WALLET--VRF](../Commands/F_WALLET--VRF.md) |
| [MultiTeeOperations.md](MultiTeeOperations.md) | Distributed workflows with multiple TEE machines sharing a wallet | All of the above | All of the above |

## Common Conventions

### Contract Notation

- Function calls are written as `ContractName.functionName()` (e.g., `TeeMachineRegistry.register()`)
- Events are written as `EventName(field1, field2)` (e.g., `TeeMachineRegistered(teeId, extensionId)`)

### Status Transitions

Status transitions are denoted with arrows:
- `→ STATUS` for initial status assignment (e.g., `→ INITIALIZED`)
- `OLD_STATUS → NEW_STATUS` for transitions (e.g., `INITIALIZED → PRODUCTION`)

### Machine Statuses

See the [Registration specification](../TeeManagement/Registration.md#statuses) for full status definitions (`INITIALIZED`, `PRODUCTION`, `SUSPENDED`, `PAUSED`, `BANNED`).

### Wallet Statuses

| Status | Meaning |
|--------|---------|
| `CREATED` | Wallet created, admins/cosigners being configured |
| `INITIALIZED` | Configuration closed, keys being added |
| `PRODUCTION` | Fully operational, can process payments |

### Network Targets

| Name | Description |
|------|-------------|
| `hardhat` / `localhost` | Local development |
| `coston` | Flare testnet |
| `coston2` | Flare testnet (alternate) |
| `songbird` | Canary network |
| `flare` | Production mainnet |

## Typical End-to-End Sequence

For a complete single-TEE XRP payment setup from scratch:

1. **[Extension Configuration](ExtensionConfiguration.md)** — Register extension, add code version, configure allowlists
2. **[Machine Registration](MachineRegistration.md)** — Boot VM, configure, register on-chain, move to PRODUCTION
3. **[Wallet Setup](WalletSetup.md)** — Create project, create wallet, add keys, enable
4. **[XRPL Multisig Configuration](XrplMultisigConfiguration.md)** — Create XRPL account, verify, link to wallet
5. **[XRP Payment](XrpPayment.md)** — Send payment, retrieve signed tx, submit, verify

For multi-TEE deployments, see [Multi-TEE Operations](MultiTeeOperations.md) which adapts each of these steps for distributed operation.

## Source References

These workflows are derived from the specifications in [`flare-specs/src/FCC/`](../) — see each workflow's **Spec References** column in the index above for the relevant specification files.
