# TeeFeeCalculator Events

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
