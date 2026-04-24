# TeeExtensionRegistry Events

### TeeInstructionsSent

Emitted by: `_sendInstructions()` (called internally by all instruction-sending functions)

```solidity
event TeeInstructionsSent(
    uint256 indexed extensionId,
    bytes32 indexed instructionId,
    uint32 indexed rewardEpochId,
    IMachineManagerFacet.TeeMachine[] teeMachines,
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

### SystemInstructionsSendersRegistered

Emitted by: `registerSystemInstructionsSenders()`

```solidity
event SystemInstructionsSendersRegistered(
    address[] instructionsSenders
);
```

### SystemInstructionsSendersUnregistered

Emitted by: `unregisterSystemInstructionsSenders()`

```solidity
event SystemInstructionsSendersUnregistered(
    address[] instructionsSenders
);
```

### SystemSupportedPlatformsAdded

Emitted by: `addSystemSupportedPlatforms()`

```solidity
event SystemSupportedPlatformsAdded(
    bytes32[] platforms
);
```

### SystemSupportedKeyTypesAndSigningAlgosAdded

Emitted by: `addSystemSupportedKeyTypesAndSigningAlgos()`

```solidity
event SystemSupportedKeyTypesAndSigningAlgosAdded(
    bytes32[] keyTypes,
    bytes32[][] _signingAlgosByKeyType
);
```
