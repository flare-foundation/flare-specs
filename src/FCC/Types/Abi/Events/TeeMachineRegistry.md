# TeeMachineRegistry Events

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

Emitted by: `toProduction()`, `pause()`, `pauseWithProof()`, `ban()`, `unban()`

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
