# TeePaymentsLimitsManager Events

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
