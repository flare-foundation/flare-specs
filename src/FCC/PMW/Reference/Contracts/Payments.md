# TeePayments

The `TeePayments` contract is the PMW-side on-chain hub: it receives payment requests from users and emits them as [`F_XRP PAY`](../Operations/Pay.md) / [`F_XRP REISSUE`](../Operations/Reissue.md) instructions via [`FlareTeeManager`](../../../Reference/Contracts/FlareTeeManager.md). Fee schedules, payment limits, and source-chain registration are managed alongside.

For the request shape and on-chain flow, see [PMW Transactions](../../Transactions.md).

## Payments Events

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

## Fee Schedule Events

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

## Limits Events

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

## Registry Events

### SourcesRegistered

Emitted by: `registerSources()`

```solidity
event SourcesRegistered(
    SourceRegistration[] registrations
);
```

### SourcesUnregistered

Emitted by: `unregisterSources()`

```solidity
event SourcesUnregistered(
    bytes32[] sourceIds
);
```

