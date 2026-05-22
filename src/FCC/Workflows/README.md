# Workflows

State-machine-shaped operational procedures for FCC. Each page has two roles: a user guide for the end-to-end task, and the spec of a flow the protocol must support.
For document format, the workflow dependency graph, and the typical end-to-end sequence, see [Conventions](Conventions.md).

App-specific workflows live with their app:

- FCE: [Configuration](../FCE/Workflows/Configuration.md), [Instructions](../FCE/Workflows/Instructions.md).
- PMW: [XrplMultisigConfiguration](../PMW/Workflows/XrplMultisigConfiguration.md), [XrpPayment](../PMW/Workflows/XrpPayment.md).
- FDC2: [Fdc2Attestation](../FDC2/Workflows/Fdc2Attestation.md) (shared sub-workflow).

## Cross-cutting workflows

| Workflow | Description | Spec |
|---|---|---|
| [MachineRegistration](MachineRegistration.md) | Deploy a TEE machine from VM boot to `PRODUCTION`. | [Registration](../Concepts/Machines.md), [State](../Concepts/Machines.md), [Attestation](../Concepts/Machines.md) |
| [MachineLifecycle](MachineLifecycle.md) | Post-registration operations: pause, resume, upgrade, ownership transfer. | [Registration](../Concepts/Machines.md) |
| [WalletSetup](WalletSetup.md) | Create a project and configure a wallet through `PRODUCTION`. | [Wallets](../Concepts/Wallets.md), [Keys](../Concepts/Keys.md) |
| [KeyAdd](KeyAdd.md) | Add a new signing key to a TEE machine. | [Keys](../Concepts/Keys.md), [Wallets](../Concepts/Wallets.md) |
| [KeyDelete](KeyDelete.md) | Delete a key from a TEE machine and clean up stale TEE IDs. | [Keys](../Concepts/Keys.md) |
| [KeyRestore](KeyRestore.md) | Restore a key from backup onto a new TEE machine. | [Keys](../Concepts/Keys.md) |
| [VrfProof](VrfProof.md) | Generate and verify a VRF proof from a TEE-managed VRF key. | [Keys](../Concepts/Keys.md), [`F_WALLET VRF`](../Reference/Operations/F_WALLET.md#vrf) |
| [MultiTeeOperations](MultiTeeOperations.md) | Deltas for running a wallet or application across multiple TEE machines. | All of the above |

On-chain calls go through the [`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md) diamond or one of the PMW contracts (`TeePayments`, `TeePaymentsFeeScheduleManager`); only the [`Fdc2Hub`](../FDC2/README.md) and the off-chain TEE proxy sit outside the diamond.
