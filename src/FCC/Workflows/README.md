# Workflows

Step-by-step operational workflows for FCC.
The specification under [`../`](../) is the canonical source for protocol semantics, data structures, and ownership rules; workflow documents describe how to perform end-to-end tasks and link back to the spec on first mention of any concept.

For document format, the workflow dependency graph, and the typical end-to-end sequence, see [Conventions](Conventions.md).

## Index

All on-chain calls go through the [`FlareTeeManager`](../TeeManagement/FlareTeeManager.md) diamond or one of the PMW contracts (`TeePayments`, `TeePaymentsFeeScheduleManager`); only the [`Fdc2Hub`](../Extensions/FDC2/README.md) and the off-chain TEE proxy sit outside the diamond.

| Workflow | Description | Spec |
|---|---|---|
| [Fdc2Attestation](Fdc2Attestation.md) | Shared sub-workflow invoked from machine, multisig, and payment workflows. | [FDC2](../Extensions/FDC2/README.md), [AttestationTypes](../Extensions/FDC2/AttestationTypes/README.md) |
| [ExtensionConfiguration](ExtensionConfiguration.md) | Register and configure a custom [FCE](../Extensions/README.md). | [Extensions](../Extensions/README.md), [System Extension](../Extensions/SystemExtension.md) |
| [MachineRegistration](MachineRegistration.md) | Deploy a TEE machine from VM boot to `PRODUCTION`. | [Registration](../TeeManagement/Registration.md), [State](../TeeManagement/State.md), [Attestation](../TeeManagement/Attestation.md) |
| [WalletSetup](WalletSetup.md) | Create a project and configure a wallet through `PRODUCTION`. | [Wallets](../TeeManagement/Wallets.md), [Keys](../TeeManagement/Keys.md) |
| [XrplMultisigConfiguration](XrplMultisigConfiguration.md) | Bind an XRPL multisig account to a TEE-managed wallet. | [PMW](../Extensions/PMW/README.md), [`PMWMultisigAccountConfigured`](../Extensions/FDC2/AttestationTypes/PMWMultisigAccountConfigured.md) |
| [XrpPayment](XrpPayment.md) | Execute, reissue, or nullify XRP payments through a TEE wallet. | [Transactions](../Extensions/PMW/Transactions.md), [`PMWPaymentStatus`](../Extensions/FDC2/AttestationTypes/PMWPaymentStatus.md) |
| [KeyAdd](KeyAdd.md) | Add a new signing key to a TEE machine. | [Keys](../TeeManagement/Keys.md), [Wallets](../TeeManagement/Wallets.md) |
| [KeyDelete](KeyDelete.md) | Delete a key from a TEE machine and clean up stale TEE IDs. | [Keys](../TeeManagement/Keys.md) |
| [KeyRestore](KeyRestore.md) | Restore a key from backup onto a new TEE machine. | [Keys](../TeeManagement/Keys.md) |
| [MachineLifecycle](MachineLifecycle.md) | Post-registration operations: pause, resume, upgrade, ownership transfer. | [Registration](../TeeManagement/Registration.md) |
| [ExtensionInstructions](ExtensionInstructions.md) | Send custom instructions to an FCE and retrieve the result. | [Extensions](../Extensions/README.md), [Actions](../Operations/Actions.md) |
| [VrfProof](VrfProof.md) | Generate and verify a VRF proof from a TEE-managed VRF key. | [Keys](../TeeManagement/Keys.md), [`F_WALLET VRF`](../Operations/System/F_WALLET.md#vrf) |
| [MultiTeeOperations](MultiTeeOperations.md) | Deltas for running a wallet or application across multiple TEE machines. | All of the above |
