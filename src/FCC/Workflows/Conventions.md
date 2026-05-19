# Workflow Conventions

This page collects the cross-workflow conventions that the individual procedure documents in this directory share, along with the workflow dependency graph and the typical end-to-end sequence.

## Document Format

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

## Notation

### Contract Notation

- Function calls are written as `ContractName.functionName()` (e.g., `TeeMachineRegistry.register()`).
- Events are written as `EventName(field1, field2)` (e.g., `TeeMachineRegistered(teeId, extensionId)`).

### Status Transitions

Status transitions are denoted with arrows:

- `→ STATUS` for initial status assignment (e.g., `→ INITIALIZED`).
- `OLD_STATUS → NEW_STATUS` for transitions (e.g., `INITIALIZED → PRODUCTION`).

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

1. **[Extension Configuration](ExtensionConfiguration.md)** — Register extension, add code version, configure allowlists.
2. **[Machine Registration](MachineRegistration.md)** — Boot VM, configure, register on-chain, move to PRODUCTION.
3. **[Wallet Setup](WalletSetup.md)** — Create project, create wallet, add keys, enable.
4. **[XRPL Multisig Configuration](XrplMultisigConfiguration.md)** — Create XRPL account, verify, link to wallet.
5. **[XRP Payment](XrpPayment.md)** — Send payment, retrieve signed tx, submit, verify.

For multi-TEE deployments, see [Multi-TEE Operations](MultiTeeOperations.md) which adapts each of these steps for distributed operation.

## Source References

These workflows are derived from the specifications in [`flare-specs/src/FCC/`](../) — see each workflow's **Spec References** column in the [index](README.md#workflow-index) for the relevant specification files.
