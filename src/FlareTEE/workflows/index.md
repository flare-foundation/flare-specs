# FlareTEE Workflow Documentation

## Overview

This directory contains step-by-step operational workflows for the Flare TEE system. While the [specification files](../) describe **what** each component is and how it works conceptually, these workflow documents describe **how to** perform specific tasks end-to-end — connecting specifications to concrete procedures.

Each workflow document follows a consistent format:
- **Overview** and **Prerequisites** sections
- Numbered steps with contract function names
- For each step: **Who can call**, **Parameters**, **Requirements**, **What happens**, **Events emitted**
- Status transitions noted where applicable
- Cross-references to spec files and related workflows

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
  xrpl-multisig-   key-management
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

> **FTDC Attestation** is a shared sub-workflow invoked from within other workflows, not a standalone prerequisite. The following workflows use FTDC attestation:
> - **TeeAvailabilityCheck** — used in [machine-registration.md](machine-registration.md) (Steps 9-10), [machine-lifecycle.md](machine-lifecycle.md) (Steps 1, 6), and [multi-tee-operations.md](multi-tee-operations.md) (Step 1)
> - **PMWMultisigAccountConfigured** — used in [xrpl-multisig-configuration.md](xrpl-multisig-configuration.md) (Steps 3-5) and [multi-tee-operations.md](multi-tee-operations.md) (Step 3)
> - **PMWPaymentStatus** — used in [xrp-payment.md](xrp-payment.md) (Step 4) and [multi-tee-operations.md](multi-tee-operations.md) (Step 4)

## Workflow Index

| Workflow | Description | Key Contracts | Spec References |
|----------|-------------|---------------|-----------------|
| [ftdc-attestation.md](ftdc-attestation.md) | FTDC attestation sub-workflow — not standalone; invoked from within machine, multisig, and payment workflows | `FtdcHub`, `TeeVerification` | [FTDC](../Extensions/FTDC.md), [attestation-types/](../attestation-types/) |
| [extension-configuration.md](extension-configuration.md) | Register and configure a custom TEE extension (extensionId > 0) | `TeeExtensionRegistry` | [Extensions](../Extensions/Extensions.md), [System Extension](../Extensions/System%20Extension.md), SDK and Development (not yet published) |
| [machine-registration.md](machine-registration.md) | Deploy a TEE machine from VM boot to PRODUCTION status | `TeeMachineRegistry`, `TeeExtensionRegistry`, `TeeVerification` | [Ownership](../TEE%20Management/Ownership.md), [State and Status](../TEE%20Management/State%20and%20Status.md), TEE Configuration API (not yet published) |
| [wallet-setup.md](wallet-setup.md) | Create a project and configure a wallet through to PRODUCTION | `TeeWalletProjectManager`, `TeeWalletManager`, `TeeWalletKeyManager` | [Projects and Ownership](../Operations/Projects%20and%20Ownership.md) |
| [xrpl-multisig-configuration.md](xrpl-multisig-configuration.md) | Bind an XRPL multisig account to a TEE-managed wallet | `TeePayments`, `TeeVerification` | [PMW](../Extensions/PMW/PMW.md), [PMWMultisigAccountConfigured](../attestation-types/PMWMultisigAccountConfigured.md) |
| [xrp-payment.md](xrp-payment.md) | Execute, reissue, or nullify XRP payments through a TEE wallet | `TeePayments` | [Transactions](../Extensions/PMW/Transactions.md), [PMWPaymentStatus](../attestation-types/PMWPaymentStatus.md) |
| [key-management.md](key-management.md) | Key deletion, backup, restoration, and migration between TEEs | `TeeWalletKeyManager`, `TeeWalletBackupManager` | [Key Management](../TEE%20Management/Key%20Management.md) |
| [machine-lifecycle.md](machine-lifecycle.md) | Post-registration machine operations: pause, resume, upgrade, ownership transfer | `TeeMachineRegistry` | [Ownership](../TEE%20Management/Ownership.md), [State and Status](../TEE%20Management/State%20and%20Status.md) |
| [extension-instructions.md](extension-instructions.md) | Send custom instructions to extensions (EVM signing, RNG, direct actions) | `TeeExtensionRegistry` | SDK and Development (not yet published), [Extensions](../Extensions/Extensions.md) |
| [vrf-proof.md](vrf-proof.md) | Generate and verify a VRF proof using a TEE-managed VRF key | `TeeWalletKeyManager`, `TeeVRFVerifier` | [Key Management](../TEE%20Management/Key%20Management.md), [F_WALLET--VRF](../commands/F_WALLET--VRF.md) |
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

| Status | Meaning |
|--------|---------|
| `INITIALIZED` | Registered but not yet verified |
| `PRODUCTION` | Fully operational |
| `SUSPENDED` | Paused due to non-availability proof |
| `PAUSED` | Paused by owner |
| `PAUSED_FOR_UPGRADE` | Ready as replication source |
| `REPLICATING` | Being replicated to new machine |
| `BANNED` | Permanently disabled (governance only) |

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
