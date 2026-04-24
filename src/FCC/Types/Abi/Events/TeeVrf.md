# TeeVrf Events

### VrfRequested

Emitted by: `requestVrf()`

```solidity
event VrfRequested(
    bytes32 indexed walletId,
    uint64 keyId,
    bytes32 instructionId
);
```

### VrfAuthorizationAddressSet

Emitted by: `setVrfAuthorizationAddress()`

```solidity
event VrfAuthorizationAddressSet(
    bytes32 indexed walletId,
    address authorizationAddress
);
```
