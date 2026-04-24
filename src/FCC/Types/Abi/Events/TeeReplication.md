# TeeReplication Events

### PauseBeforeUpgradeMinDurationSecondsSet

Emitted by: `setPauseBeforeUpgradeMinDurationSeconds()`

```solidity
event PauseBeforeUpgradeMinDurationSecondsSet(
    uint256 pauseBeforeUpgradeMinDurationSeconds
);
```

### TeeMachinePausedForUpgrade

Emitted by: `toPauseForUpgrade()`

```solidity
event TeeMachinePausedForUpgrade(
    address indexed teeId
);
```

### TeeMachineReplicationTriggered

Emitted by: `replicateFrom()`

```solidity
event TeeMachineReplicationTriggered(
    address indexed oldTeeId,
    address indexed newTeeId,
    uint256 teeUpgradeId
);
```

### TeeMachineReplicationConfirmed

Emitted by: `confirmReplicate()`

```solidity
event TeeMachineReplicationConfirmed(
    address indexed oldTeeId,
    address indexed newTeeId
);
```
