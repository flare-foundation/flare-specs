# TeeGovernance Events

### NewTeeGovernanceSet

Emitted by: `setNewTeeGovernance()`

```solidity
event NewTeeGovernanceSet(
    uint256 indexed extensionId,
    bytes32 indexed governanceHash,
    address[] signers,
    uint64 signersThreshold
);
```

### NewPausingAddressesSet

Emitted by: `setTeePausingAddresses()`

```solidity
event NewPausingAddressesSet(
    uint256 indexed extensionId,
    uint256 indexed nonce,
    address[] pausingAddresses
);
```

### NewPausingAddressesSigned

Emitted by: `signTeePausingAddresses()`

```solidity
event NewPausingAddressesSigned(
    uint256 indexed extensionId,
    uint256 indexed nonce,
    address indexed signer,
    Signature signature
);
```
