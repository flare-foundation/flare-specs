# TeeWalletProjectManager Events

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
