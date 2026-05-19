# Workflows

Step-by-step operational workflows for the FCC system.
The specification under `../` is the canonical source for protocol semantics, data structures, and ownership rules; workflow documents describe how to perform end-to-end tasks and point back to the spec whenever a concept is defined there.

For document format, the workflow dependency graph, naming conventions, and the typical end-to-end sequence, see [Conventions](Conventions.md).

## Workflow Index

| Workflow | Description | Key Contracts | Spec References |
|----------|-------------|---------------|-----------------|
| [Fdc2Attestation.md](Fdc2Attestation.md) | FDC2 attestation sub-workflow — not standalone; invoked from within machine, multisig, and payment workflows | `Fdc2Hub`, `TeeVerification` | [FDC2](../Extensions/FDC2/README.md), [AttestationTypes/](../Extensions/FDC2/AttestationTypes/) |
| [ExtensionConfiguration.md](ExtensionConfiguration.md) | Register and configure a custom TEE extension (extensionId > 0) | `TeeExtensionRegistry` | [Extensions](../Extensions/README.md), [System Extension](../Extensions/SystemExtension.md) |
| [MachineRegistration.md](MachineRegistration.md) | Deploy a TEE machine from VM boot to PRODUCTION status | `TeeMachineRegistry`, `TeeExtensionRegistry`, `TeeVerification` | [Registration](../TeeManagement/Registration.md), [State](../TeeManagement/State.md) and [Attestation](../TeeManagement/Attestation.md) |
| [WalletSetup.md](WalletSetup.md) | Create a project and configure a wallet through to PRODUCTION | `TeeWalletProjectManager`, `TeeWalletManager`, `TeeWalletKeyManager` | [Wallets](../TeeManagement/Wallets.md), [Key Management](../TeeManagement/Keys.md) |
| [XrplMultisigConfiguration.md](XrplMultisigConfiguration.md) | Bind an XRPL multisig account to a TEE-managed wallet | `TeePayments`, `TeeVerification` | [PMW](../Extensions/PMW/README.md), [PMWMultisigAccountConfigured](../Extensions/FDC2/AttestationTypes/PMWMultisigAccountConfigured.md) |
| [XrpPayment.md](XrpPayment.md) | Execute, reissue, or nullify XRP payments through a TEE wallet | `TeePayments` | [Transactions](../Extensions/PMW/Transactions.md), [PMWPaymentStatus](../Extensions/FDC2/AttestationTypes/PMWPaymentStatus.md) |
| [KeyAdd.md](KeyAdd.md) | Add a new signing key to a TEE machine | `TeeWalletKeyManager` | [Key Management](../TeeManagement/Keys.md), [Wallets](../TeeManagement/Wallets.md) |
| [KeyDelete.md](KeyDelete.md) | Delete a key from a TEE machine and clean up stale TEE IDs | `TeeWalletKeyManager` | [Key Management](../TeeManagement/Keys.md) |
| [KeyRestore.md](KeyRestore.md) | Restore a key from backup onto a new TEE machine | `TeeWalletKeyManager`, `TeeWalletBackupManager` | [Key Management](../TeeManagement/Keys.md) |
| [MachineLifecycle.md](MachineLifecycle.md) | Post-registration machine operations: pause, resume, upgrade, ownership transfer | `TeeMachineRegistry` | [Registration](../TeeManagement/Registration.md), [State](../TeeManagement/State.md) and [Attestation](../TeeManagement/Attestation.md) |
| [ExtensionInstructions.md](ExtensionInstructions.md) | Send custom instructions to extensions and retrieve the result | `TeeExtensionRegistry` | [Extensions](../Extensions/README.md), [Actions](../Operations/Actions.md) |
| [VrfProof.md](VrfProof.md) | Generate and verify a VRF proof using a TEE-managed VRF key | `TeeWalletKeyManager`, `TeeVRFVerifier` | [Key Management](../TeeManagement/Keys.md), [F_WALLET--VRF](../Operations/Commands/F_WALLET/Vrf.md) |
| [MultiTeeOperations.md](MultiTeeOperations.md) | Distributed workflows with multiple TEE machines sharing a wallet | All of the above | All of the above |
