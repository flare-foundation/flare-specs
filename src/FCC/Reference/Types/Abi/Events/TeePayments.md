# TeePayments Events

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
