# Events

This page lists all events emitted by FlareTEE smart contracts.

## TeeWalletManager

### WalletCreated

Emitted by: `createWallet()`

```solidity
event WalletCreated(
    bytes32 indexed projectId,
    bytes32 indexed walletId
);
```

### WalletAdminsSet

Emitted by: `setAdmins()`

```solidity
event WalletAdminsSet(
    bytes32 indexed walletId,
    PublicKey[] adminsPublicKeys,
    uint64 adminsThreshold
);
```

### WalletAdminConfirmed

Emitted by: `confirmAdmin()`

```solidity
event WalletAdminConfirmed(
    bytes32 indexed walletId,
    address indexed admin
);
```

### WalletCosignersSet

Emitted by: `setCosigners()`

```solidity
event WalletCosignersSet(
    bytes32 indexed walletId,
    address[] cosigners,
    uint64 cosignersThreshold
);
```

### WalletCosignerConfirmed

Emitted by: `confirmCosigner()`

```solidity
event WalletCosignerConfirmed(
    bytes32 indexed walletId,
    address indexed cosigner
);
```

### WalletInitialized

Emitted by: `closeWalletInitialization()`

```solidity
event WalletInitialized(
    bytes32 indexed walletId
);
```

### WalletEnabled

Emitted by: `enableWallet()`

```solidity
event WalletEnabled(
    bytes32 indexed walletId
);
```

### WalletPaused

Emitted by: `pauseWallet()`

```solidity
event WalletPaused(
    bytes32 indexed walletId
);
```

## TeeWalletKeyManager

### WalletMultisigThresholdSet

Emitted by: `setMultisigThreshold()`

```solidity
event WalletMultisigThresholdSet(
    bytes32 indexed walletId,
    uint64 multisigThreshold
);
```

### WalletKeyAdded

Emitted by: `addKey()`

```solidity
event WalletKeyAdded(
    address indexed teeId,
    bytes32 indexed walletId,
    uint64 indexed keyId
);
```

### WalletKeyConfirmed

Emitted by: `confirmKey()`

```solidity
event WalletKeyConfirmed(
    address indexed teeId,
    bytes32 indexed walletId,
    uint64 indexed keyId,
    bytes publicKey
);
```

### WalletKeyDeleted

Emitted by: `deleteKey()`, `cleanUpTeeIds()`

```solidity
event WalletKeyDeleted(
    address indexed teeId,
    bytes32 indexed walletId,
    uint64 indexed keyId
);
```

### WalletKeysNotAvailable

Emitted by: `receivingTeesAndKeys()`

```solidity
event WalletKeysNotAvailable(
    bytes32 indexed walletId,
    uint64[] keyIds
);
```

## TeeWalletProjectManager

### ProjectCreated

Emitted by: `createProject()`

```solidity
event ProjectCreated(
    bytes32 indexed projectId,
    address indexed owner,
    uint256 extensionId,
    bytes32 keyType,
    bytes32 signingAlgo
);
```

### BackupManagerSet

Emitted by: `setBackupManager()`

```solidity
event BackupManagerSet(
    bytes32 indexed projectId,
    address indexed backupManager
);
```

### NewOwnerProposed

Emitted by: `proposeNewOwner()`

```solidity
event NewOwnerProposed(
    bytes32 indexed projectId,
    address indexed newOwner
);
```

### OwnershipConfirmed

Emitted by: `confirmOwnership()`

```solidity
event OwnershipConfirmed(
    bytes32 indexed projectId,
    address indexed newOwner
);
```

## TeeWalletBackupManager

### BackupRestoreTriggered

Emitted by: `backupRestore()`

```solidity
event BackupRestoreTriggered(
    address indexed teeId,
    bytes32 indexed walletId,
    uint64 indexed keyId,
    uint256 nonce
);
```

## TeeMachineRegistry

### TeeMachineRegistered

Emitted by: `register()`

```solidity
event TeeMachineRegistered(
    address indexed teeId,
    address indexed teeProxyId,
    address indexed owner,
    uint256 extensionId,
    string url,
    bytes32 codeHash,
    bytes32 platform
);
```

### TeeMachineStatusChanged

Emitted by: `toProduction()`, `pause()`, `pauseWithProof()`, `ban()`, `unban()`, `updateTeeMachineSettings()`, `changeStatus()`, `replicate()`

```solidity
event TeeMachineStatusChanged(
    address indexed teeId,
    TeeStatus indexed newStatus
);
```

### TeeMachineSettingsUpdated

Emitted by: `updateTeeMachineSettings()`

```solidity
event TeeMachineSettingsUpdated(
    address indexed teeId,
    address indexed teeProxyId,
    string url
);
```

### NewOwnerProposed

Emitted by: `proposeNewOwner()`

```solidity
event NewOwnerProposed(
    address indexed teeId,
    address indexed oldOwner,
    address indexed newOwner
);
```

### NewOwnerConfirmed

Emitted by: `confirmOwnership()`

```solidity
event NewOwnerConfirmed(
    address indexed teeId,
    address indexed newOwner
);
```

## TeeExtensionRegistry

### TeeInstructionsSent

Emitted by: `_sendInstructions()` (called internally by all instruction-sending functions)

```solidity
event TeeInstructionsSent(
    uint256 indexed extensionId,
    bytes32 indexed instructionId,
    uint32 indexed rewardEpochId,
    ITeeMachineRegistry.TeeMachine[] teeMachines,
    bytes32 opType,
    bytes32 opCommand,
    bytes message,
    address[] cosigners,
    uint64 cosignersThreshold,
    address claimBackAddress,
    uint256 fee
);
```

### TeeExtensionRegistered

Emitted by: `register()`

```solidity
event TeeExtensionRegistered(
    uint256 indexed extensionId,
    address indexed owner
);
```

### TeeExtensionContractsSet

Emitted by: `register()`, `setExtensionContracts()`

```solidity
event TeeExtensionContractsSet(
    uint256 indexed extensionId,
    ITeeExtensionStateVerifier indexed teeExtensionStateVerifier,
    address indexed teeExtensionInstructionsSender
);
```

### TeeVersionAdded

Emitted by: `addTeeVersion()`

```solidity
event TeeVersionAdded(
    uint256 indexed extensionId,
    string version,
    bytes32 indexed codeHash,
    bytes32[] platforms,
    bytes32 governanceHash
);
```

### CodeHashPlatformDisabled

Emitted by: `disableCodeHashPlatform()`

```solidity
event CodeHashPlatformDisabled(
    uint256 indexed extensionId,
    bytes32 indexed codeHash,
    bytes32 indexed platform
);
```

### SupportedKeyTypesAdded

Emitted by: `addSupportedKeyTypes()`

```solidity
event SupportedKeyTypesAdded(
    uint256 indexed extensionId,
    bytes32[] keyTypes
);
```

### SupportedKeyTypesRemoved

Emitted by: `removeSupportedKeyTypes()`

```solidity
event SupportedKeyTypesRemoved(
    uint256 indexed extensionId,
    bytes32[] keyTypes
);
```

### NewOwnerProposed

Emitted by: `proposeNewOwner()`

```solidity
event NewOwnerProposed(
    uint256 indexed extensionId,
    address indexed oldOwner,
    address indexed newOwner
);
```

### NewOwnerConfirmed

Emitted by: `confirmOwnership()`

```solidity
event NewOwnerConfirmed(
    uint256 indexed extensionId,
    address indexed newOwner
);
```

## TeePayments

### PMWMultisigAccountAdded

Emitted by: `addPMWMultisigAccount()`

```solidity
event PMWMultisigAccountAdded(
    bytes32 indexed walletId,
    bytes32 sourceId,
    string accountAddress,
    uint64 initialNonce,
    address authorizationAddress,
    uint64 batchSize,
    uint64 batchDurationSeconds
);
```

### BatchSettingsSet

Emitted by: `setBatchSettings()`

```solidity
event BatchSettingsSet(
    bytes32 indexed walletId,
    bytes32 sourceId,
    string accountAddress,
    uint64 batchSize,
    uint64 batchDurationSeconds
);
```

### FeeScheduleSet

Emitted by: `setFeeSchedule()`

```solidity
event FeeScheduleSet(
    bytes32 indexed walletId,
    bytes32 sourceId,
    string accountAddress,
    int16[] factorsBIPS,
    uint16[] delaysSeconds
);
```

### PaymentLimitsSet

Emitted by: `setPaymentLimits()`

```solidity
event PaymentLimitsSet(
    bytes32 indexed walletId,
    bytes32 sourceId,
    string accountAddress,
    uint256 transactionLimit,
    uint256 dailyLimit
);
```

### SupportedSourceIdsAdded

Emitted by: `_addSupportedSourceIds()`

```solidity
event SupportedSourceIdsAdded(
    bytes32[] sourceIds
);
```

## TeeVerification

### TeeAttestationRequested

Emitted by: `requestTeeAttestation()`

```solidity
event TeeAttestationRequested(
    address indexed teeId,
    bytes32 challenge
);
```

### AvailabilityCheckValidityExtended

Emitted by: `confirmAvailability()`

```solidity
event AvailabilityCheckValidityExtended(
    address indexed teeId,
    address indexed owner,
    uint256 endTs
);
```

### CosignersSet

Emitted by: `setCosigners()`

```solidity
event CosignersSet(
    address[] cosigners,
    uint64 cosignersThreshold
);
```

### SettingsUpdated

Emitted by: `_updateSettings()`

```solidity
event SettingsUpdated(
    uint64 availabilityCheckValidityDurationSeconds,
    uint24 signingPolicyValidityDurationInRewardEpochs,
    uint64 challengeValidityDurationSeconds
);
```

## TeeVrf

### VrfRequested

Emitted by: `requestVrf()`

```solidity
event VrfRequested(
    bytes32 indexed walletId,
    uint64 keyId,
    bytes32 instructionId
);
```

### VrfAuthorizationAddressSet

Emitted by: `setVrfAuthorizationAddress()`

```solidity
event VrfAuthorizationAddressSet(
    bytes32 indexed walletId,
    address authorizationAddress
);
```

## TeeOwnerAllowlist

### AllowedTeeMachineOwnersAdded

```solidity
event AllowedTeeMachineOwnersAdded(uint256 extensionId, address[] owners);
```

### AllowedTeeMachineOwnersRemoved

```solidity
event AllowedTeeMachineOwnersRemoved(uint256 extensionId, address[] owners);
```

### AllowedTeeWalletProjectOwnersAdded

```solidity
event AllowedTeeWalletProjectOwnersAdded(uint256 extensionId, address[] owners);
```

### AllowedTeeWalletProjectOwnersRemoved

```solidity
event AllowedTeeWalletProjectOwnersRemoved(uint256 extensionId, address[] owners);
```

### AllTeeMachineOwnersAllowed

```solidity
event AllTeeMachineOwnersAllowed(uint256 extensionId);
```

### AllTeeMachineOwnersDisallowed

```solidity
event AllTeeMachineOwnersDisallowed(uint256 extensionId);
```

### AllTeeWalletProjectOwnersAllowed

```solidity
event AllTeeWalletProjectOwnersAllowed(uint256 extensionId);
```

### AllTeeWalletProjectOwnersDisallowed

```solidity
event AllTeeWalletProjectOwnersDisallowed(uint256 extensionId);
```

## TeeGovernance

### NewTeeGovernanceSet

Emitted by: `setNewTeeGovernance()`

```solidity
event NewTeeGovernanceSet(
    uint256 indexed extensionId,
    bytes32 indexed governanceHash,
    address[] signers,
    uint64 signersThreshold
);
```

### NewPausingAddressesSet

Emitted by: `setTeePausingAddresses()`

```solidity
event NewPausingAddressesSet(
    uint256 indexed extensionId,
    uint256 indexed nonce,
    address[] pausingAddresses
);
```

### NewPausingAddressesSigned

Emitted by: `signTeePausingAddresses()`

```solidity
event NewPausingAddressesSigned(
    uint256 indexed extensionId,
    uint256 indexed nonce,
    address indexed signer,
    Signature signature
);
```

## TeeFeeCalculator

### DefaultFeeSet

Emitted by: `initialize()`, `setDefaultFee()`

```solidity
event DefaultFeeSet(
    uint256 defaultFee
);
```

### OperationFeesSet

Emitted by: `setOperationFees()`

```solidity
event OperationFeesSet(
    bytes32[] opTypes,
    bytes32[] opCommands,
    uint256[] fees
);
```
