# Events

Events emitted by FCC smart contracts, organized by contract.

| Contract | Events |
|----------|--------|
| [TeeWalletManager](TeeWalletManager.md) | `WalletCreated`, `WalletAdminsSet`, `WalletAdminConfirmed`, `WalletCosignersSet`, `WalletCosignerConfirmed`, `WalletInitialized`, `WalletEnabled`, `WalletPaused` |
| [TeeWalletKeyManager](TeeWalletKeyManager.md) | `WalletMultisigThresholdSet`, `WalletKeyAdded`, `WalletKeyConfirmed`, `WalletKeyDeleted`, `WalletKeysNotAvailable` |
| [TeeWalletProjectManager](TeeWalletProjectManager.md) | `ProjectCreated`, `BackupManagerSet`, `NewOwnerProposed`, `OwnershipConfirmed` |
| [TeeWalletBackupManager](TeeWalletBackupManager.md) | `BackupRestoreTriggered` |
| [TeeMachineRegistry](TeeMachineRegistry.md) | `TeeMachineRegistered`, `TeeMachineStatusChanged`, `TeeMachineSettingsUpdated`, `NewOwnerProposed`, `NewOwnerConfirmed` |
| [TeeExtensionRegistry](TeeExtensionRegistry.md) | `TeeInstructionsSent`, `TeeExtensionRegistered`, `TeeExtensionContractsSet`, `TeeVersionAdded`, `CodeHashPlatformDisabled`, `SupportedKeyTypesAdded`, `SupportedKeyTypesRemoved`, `NewOwnerProposed`, `NewOwnerConfirmed`, `SystemInstructionsSendersRegistered`, `SystemInstructionsSendersUnregistered`, `SystemSupportedPlatformsAdded`, `SystemSupportedKeyTypesAndSigningAlgosAdded` |
| [TeeUpgradeManager](TeeUpgradeManager.md) | `TeeUpgradeStarted`, `TeeUpgradePathsAdded`, `TeeUpgradeFinalized`, `TeeUpgradeSourceSignatureAdded`, `TeeUpgradeTargetSignatureAdded`, `TeeUpgradeSigned` |
| [TeeReplication](TeeReplication.md) | `PauseBeforeUpgradeMinDurationSecondsSet`, `TeeMachinePausedForUpgrade`, `TeeMachineReplicationTriggered`, `TeeMachineReplicationConfirmed` |
| [TeePayments](TeePayments.md) | `PMWMultisigAccountAdded`, `BatchSettingsSet` |
| [TeePaymentsFeeScheduleManager](TeePaymentsFeeScheduleManager.md) | `FeeScheduleConfigsSet`, `FeeScheduleConfigsCleared`, `ProjectFeeScheduleSet`, `ProjectFeeScheduleCleared`, `AccountFeeScheduleSet`, `AccountFeeScheduleCleared` |
| [TeePaymentsLimitsManager](TeePaymentsLimitsManager.md) | `PaymentLimitsSet` |
| [TeePaymentsRegistry](TeePaymentsRegistry.md) | `SourcesRegistered`, `SourcesUnregistered` |
| [TeeVerification](TeeVerification.md) | `TeeAttestationRequested`, `AvailabilityCheckValidityExtended`, `CosignersSet`, `SettingsUpdated` |
| [TeeVrf](TeeVrf.md) | `VrfRequested`, `VrfAuthorizationAddressSet` |
| [TeeOwnerAllowlist](TeeOwnerAllowlist.md) | `AllowedTeeMachineOwnersAdded`, `AllowedTeeMachineOwnersRemoved`, `AllowedTeeWalletProjectOwnersAdded`, `AllowedTeeWalletProjectOwnersRemoved`, `AllTeeMachineOwnersAllowed`, `AllTeeMachineOwnersDisallowed`, `AllTeeWalletProjectOwnersAllowed`, `AllTeeWalletProjectOwnersDisallowed` |
| [TeeGovernance](TeeGovernance.md) | `NewTeeGovernanceSet`, `NewPausingAddressesSet`, `NewPausingAddressesSigned` |
| [TeeFeeCalculator](TeeFeeCalculator.md) | `DefaultFeeSet`, `OperationFeesSet` |
