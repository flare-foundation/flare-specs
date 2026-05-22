# Workflow Conventions

This page prescribes the state-machine shape that every workflow in this directory follows, plus the cross-workflow dependency graph and the typical end-to-end sequence.

The repo will eventually be translated into a formal modelling language (Quint / TLA+); the shape below is chosen so the translation is mechanical.

## Document Format

Every workflow page is structured as a state machine.
The reader is also a stakeholder in the protocol — typically a [TEE operator](../../Terminology/Roles.md#tee-operator), a [project owner](../../Terminology/Roles.md#project-owner), a [data provider](../../Terminology/Roles.md#data-provider), or [governance](../../Terminology/Roles.md#governance) — so each transition spells out who can take it.

Each page has the following sections, in order:

1. **Header**: one-paragraph summary of what the workflow accomplishes.
2. **Preconditions**: facts that must hold in the system before the workflow can start (other workflows already completed, on-chain state present, etc.). Phrased as predicates, not as numbered prerequisites.
3. **States**: every distinct value the workflow tracks. Names are PascalCase.
4. **Initial state**: which state(s) the workflow can start in, and what observable predicates pin them down.
5. **Transitions**: each transition is an H3 (`### action: From → To`) with:
   - **Action** — the contract function or off-chain operation that drives the transition.
   - **Caller** — who can invoke it.
   - **Payable** — when relevant.
   - **Guards** — predicates that must hold for the transition to fire. If any guard fails, the transition is rejected and the state is unchanged.
   - **Effects** — observable changes (state updates, instructions emitted, events).
6. **Invariants**: predicates that hold across every reachable state. Useful for the Quint translation.
7. **Terminal states**: which state(s) end the workflow, and what subsequent workflows may continue from them.

Auxiliary explanations (rationale, edge cases, FAQ) live in a final **Notes** section.

### Notation

- Contract calls: `ContractName.functionName()`. Most FCC entry points sit on the [`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md) diamond.
- Events: `EventName(field1, field2)`.
- Statuses: backticks. Transitions: `OLD → NEW`.
- Guards are written as predicates: `wallet.status = INITIALIZED`, `teeMachine.extensionId = wallet.extensionId`, etc.

### Machine and Wallet Statuses

| Machine | Meaning |
|---|---|
| `INITIALIZED` | Registered, awaiting first availability proof. |
| `PRODUCTION` | Operational. |
| `SUSPENDED` | Auto-suspended on stale availability or non-`OK` proof. |
| `PAUSED` | Owner-initiated or settings-update stop. |
| `BANNED` | Extension-owner stop. |

See [Concepts/Machines § Statuses](../Concepts/Machines.md#statuses) for the on-chain definitions.

| Wallet | Meaning |
|---|---|
| `CREATED` | Admins/cosigners being configured. |
| `INITIALIZED` | Configuration closed, keys being added. |
| `PRODUCTION` | Fully operational. |
| `PAUSED` | Owner-paused. |

See [Concepts/Wallets § Wallet Lifecycle](../Concepts/Wallets.md#wallet-lifecycle).

## Dependency Graph

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

The FDC2 attestation flow is a shared sub-workflow invoked from `machine-registration`, `machine-lifecycle`, `xrpl-multisig-configuration`, `xrp-payment`, and `multi-tee-operations`, not a standalone prerequisite.

## Typical End-to-End Sequence

For a complete single-TEE XRP payment setup from scratch:

1. **[Extension Configuration](../FCE/Workflows/Configuration.md)** — register extension, add code version, configure allowlists.
2. **[Machine Registration](MachineRegistration.md)** — boot VM, configure, register on-chain, move to `PRODUCTION`.
3. **[Wallet Setup](WalletSetup.md)** — create project, create wallet, add keys, enable.
4. **[XRPL Multisig Configuration](../PMW/Workflows/XrplMultisigConfiguration.md)** — create XRPL account, verify, link to wallet.
5. **[XRP Payment](../PMW/Workflows/XrpPayment.md)** — send payment, retrieve signed tx, submit, verify.

For multi-TEE deployments, see [Multi-TEE Operations](MultiTeeOperations.md), which adapts each of these steps for distributed operation.

## Source References

These workflows are derived from the specs in [`flare-specs/src/FCC/`](..). Each transition's Action and Effects should be traceable to a contract function ([`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md), [`Payments`](../PMW/Reference/Contracts/Payments.md), [`Fdc2Hub`](../FDC2/Reference/Contracts/Fdc2Hub.md), [`VrfVerifier`](../Reference/Contracts/VrfVerifier.md)) or a TEE-machine action ([`Reference/Operations/`](../Reference/Operations/README.md)).
