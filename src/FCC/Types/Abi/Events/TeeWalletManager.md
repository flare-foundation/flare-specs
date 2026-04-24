# TeeWalletManager Events

### WalletCreated

Emitted by: `createWallet()`

```solidity
event WalletCreated(
    bytes32 indexed projectId,
    bytes32 indexed walletId
);
```

### WalletAdminsSet

Emitted by: `setAdmins()`

```solidity
event WalletAdminsSet(
    bytes32 indexed walletId,
    PublicKey[] adminsPublicKeys,
    uint64 adminsThreshold
);
```

### WalletAdminConfirmed

Emitted by: `confirmAdmin()`

```solidity
event WalletAdminConfirmed(
    bytes32 indexed walletId,
    address indexed admin
);
```

### WalletCosignersSet

Emitted by: `setCosigners()`

```solidity
event WalletCosignersSet(
    bytes32 indexed walletId,
    address[] cosigners,
    uint64 cosignersThreshold
);
```

### WalletCosignerConfirmed

Emitted by: `confirmCosigner()`

```solidity
event WalletCosignerConfirmed(
    bytes32 indexed walletId,
    address indexed cosigner
);
```

### WalletInitialized

Emitted by: `closeWalletInitialization()`

```solidity
event WalletInitialized(
    bytes32 indexed walletId
);
```

### WalletEnabled

Emitted by: `enableWallet()`

```solidity
event WalletEnabled(
    bytes32 indexed walletId
);
```

### WalletPaused

Emitted by: `pauseWallet()`

```solidity
event WalletPaused(
    bytes32 indexed walletId
);
```
