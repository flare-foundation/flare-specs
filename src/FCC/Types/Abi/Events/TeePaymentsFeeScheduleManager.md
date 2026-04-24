# TeePaymentsFeeScheduleManager Events

### FeeScheduleConfigsSet

Emitted by: `setFeeScheduleConfigs()`

```solidity
event FeeScheduleConfigsSet(
    FeeScheduleConfigInput[] configs
);
```

### FeeScheduleConfigsCleared

Emitted by: `clearFeeScheduleConfigs()`

```solidity
event FeeScheduleConfigsCleared(
    bytes32[] sourceIds
);
```

### ProjectFeeScheduleSet

Emitted by: `setProjectFeeSchedule()`

```solidity
event ProjectFeeScheduleSet(
    bytes32 indexed projectId,
    bytes32 indexed sourceId,
    FeeSchedule[] schedule
);
```

### ProjectFeeScheduleCleared

Emitted by: `clearProjectFeeSchedule()`

```solidity
event ProjectFeeScheduleCleared(
    bytes32 indexed projectId,
    bytes32 indexed sourceId
);
```

### AccountFeeScheduleSet

Emitted by: `setAccountFeeSchedule()`

```solidity
event AccountFeeScheduleSet(
    bytes32 indexed projectId,
    bytes32 indexed sourceId,
    string accountAddress,
    bytes32 indexed accountHash,
    FeeSchedule[] schedule
);
```

### AccountFeeScheduleCleared

Emitted by: `clearAccountFeeSchedule()`

```solidity
event AccountFeeScheduleCleared(
    bytes32 indexed projectId,
    bytes32 indexed sourceId,
    string accountAddress,
    bytes32 indexed accountHash
);
```
