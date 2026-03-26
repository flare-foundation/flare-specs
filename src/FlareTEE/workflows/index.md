# FlareTEE Workflow Documentation

## Overview

This directory contains step-by-step operational workflows for the FlareTEE system.
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
> - **TeeAvailabilityCheck** — used in [machine-registration.md](machine-registration.md) (Steps 9-10), [machine-lifecycle.md](machine-lifecycle.md) (Steps 1, 6), and [multi-tee-operations.md](multi-tee-operations.md) (Step 1)
> - **PMWMultisigAccountConfigured** — used in [xrpl-multisig-configuration.md](xrpl-multisig-configuration.md) (Steps 3-5) and [multi-tee-operations.md](multi-tee-operations.md) (Step 3)
> - **PMWPaymentStatus** — used in [xrp-payment.md](xrp-payment.md) (Step 4) and [multi-tee-operations.md](multi-tee-operations.md) (Step 4)

## Workflow Index

| Workflow | Description | Key Contracts | Spec References |
|----------|-------------|---------------|-----------------|
| [fdc2-attestation.md](fdc2-attestation.md) | FDC2 attestation sub-workflow — not standalone; invoked from within machine, multisig, and payment workflows | `Fdc2Hub`, `TeeVerification` | [FDC2](../Extensions/FTDC.md), [attestation-types/](../attestation-types/) |
| [extension-configuration.md](extension-configuration.md) | Register and configure a custom TEE extension (extensionId > 0) | `TeeExtensionRegistry` | [Extensions](../Extensions/Extensions.md), [System Extension](../Extensions/System Extension.md) |
| [machine-registration.md](machine-registration.md) | Deploy a TEE machine from VM boot to PRODUCTION status | `TeeMachineRegistry`, `TeeExtensionRegistry`, `TeeVerification` | [Ownership](../TEE Management/Ownership.md), [State and Status](../TEE Management/State and Status.md) |
| [wallet-setup.md](wallet-setup.md) | Create a project and configure a wallet through to PRODUCTION | `TeeWalletProjectManager`, `TeeWalletManager`, `TeeWalletKeyManager` | [Projects and Ownership](../Operations/Projects and Ownership.md), [Key Management](../TEE Management/Key Management.md) |
| [xrpl-multisig-configuration.md](xrpl-multisig-configuration.md) | Bind an XRPL multisig account to a TEE-managed wallet | `TeePayments`, `TeeVerification` | [PMW](../Extensions/PMW/PMW.md), [PMWMultisigAccountConfigured](../attestation-types/PMWMultisigAccountConfigured.md) |
| [xrp-payment.md](xrp-payment.md) | Execute, reissue, or nullify XRP payments through a TEE wallet | `TeePayments` | [Transactions](../Extensions/PMW/Transactions.md), [PMWPaymentStatus](../attestation-types/PMWPaymentStatus.md) |
| [key-add.md](key-add.md) | Add a new signing key to a TEE machine | `TeeWalletKeyManager` | [Key Management](../TEE Management/Key Management.md), [Projects and Ownership](../Operations/Projects and Ownership.md) |
| [key-delete.md](key-delete.md) | Delete a key from a TEE machine and clean up stale TEE IDs | `TeeWalletKeyManager` | [Key Management](../TEE Management/Key Management.md) |
| [key-restore.md](key-restore.md) | Restore a key from backup onto a new TEE machine | `TeeWalletKeyManager`, `TeeWalletBackupManager` | [Key Management](../TEE Management/Key Management.md) |
| [machine-lifecycle.md](machine-lifecycle.md) | Post-registration machine operations: pause, resume, upgrade, ownership transfer | `TeeMachineRegistry` | [Ownership](../TEE Management/Ownership.md), [State and Status](../TEE Management/State and Status.md) |
| [extension-instructions.md](extension-instructions.md) | Send custom instructions to extensions and retrieve the result | `TeeExtensionRegistry` | [Extensions](../Extensions/Extensions.md), [Actions](../Operations/Actions.md) |
| [vrf-proof.md](vrf-proof.md) | Generate and verify a VRF proof using a TEE-managed VRF key | `TeeWalletKeyManager`, `TeeVRFVerifier` | [Key Management](../TEE Management/Key Management.md), [F_WALLET--VRF](../commands/F_WALLET--VRF.md) |
| [multi-tee-operations.md](multi-tee-operations.md) | Distributed workflows with multiple TEE machines sharing a wallet | All of the above | All of the above |

## Common Conventions

### Contract Notation

- Function calls are written as `ContractName.functionName()` (e.g., `TeeMachineRegistry.register()`)
- Events are written as `EventName(field1, field2)` (e.g., `TeeMachineRegistered(teeId, extensionId)`)

### Status Transitions

Status transitions are denoted with arrows:
- `→ STATUS` for initial status assignment (e.g., `→ INITIALIZED`)
- `OLD_STATUS → NEW_STATUS` for transitions (e.g., `INITIALIZED → PRODUCTION`)

### Machine Statuses

See the [Ownership specification](../TEE Management/Ownership.md#statuses) for full status definitions (`INITIALIZED`, `PRODUCTION`, `SUSPENDED`, `PAUSED`, `BANNED`).

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

1. **[Extension Configuration](extension-configuration.md)** — Register extension, add code version, configure allowlists
2. **[Machine Registration](machine-registration.md)** — Boot VM, configure, register on-chain, move to PRODUCTION
3. **[Wallet Setup](wallet-setup.md)** — Create project, create wallet, add keys, enable
4. **[XRPL Multisig Configuration](xrpl-multisig-configuration.md)** — Create XRPL account, verify, link to wallet
5. **[XRP Payment](xrp-payment.md)** — Send payment, retrieve signed tx, submit, verify

For multi-TEE deployments, see [Multi-TEE Operations](multi-tee-operations.md) which adapts each of these steps for distributed operation.

## Source References

These workflows are derived from the specifications in [`flare-specs/src/FlareTEE/`](../) — see each workflow's **Spec References** column in the index above for the relevant specification files.
