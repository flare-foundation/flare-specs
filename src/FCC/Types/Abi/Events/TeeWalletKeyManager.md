# TeeWalletKeyManager Events

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
