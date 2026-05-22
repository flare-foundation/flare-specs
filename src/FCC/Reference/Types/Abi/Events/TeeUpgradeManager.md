# TeeUpgradeManager Events

### TeeUpgradeStarted

Emitted by: `startUpgrade()`

```solidity
event TeeUpgradeStarted(
    uint256 indexed extensionId,
    uint256 indexed teeUpgradeId,
    bytes32 sourceTeeGovernanceHash,
    bytes32 targetTeeGovernanceHash
);
```

### TeeUpgradePathsAdded

Emitted by: `addUpgradePaths()`

```solidity
event TeeUpgradePathsAdded(
    uint256 indexed teeUpgradeId,
    TeeUpgradePath[] upgradePaths
);
```

### TeeUpgradeFinalized

Emitted by: `finalizeUpgrade()`

```solidity
event TeeUpgradeFinalized(
    uint256 indexed teeUpgradeId
);
```

### TeeUpgradeSourceSignatureAdded

Emitted by: `signUpgradeAsSource()`

```solidity
event TeeUpgradeSourceSignatureAdded(
    uint256 indexed teeUpgradeId,
    address indexed signer
);
```

### TeeUpgradeTargetSignatureAdded

Emitted by: `signUpgradeAsTarget()`

```solidity
event TeeUpgradeTargetSignatureAdded(
    uint256 indexed teeUpgradeId,
    address indexed signer
);
```

### TeeUpgradeSigned

Emitted by: `signUpgradeAsSource()`, `signUpgradeAsTarget()` (when both source and target thresholds are met)

```solidity
event TeeUpgradeSigned(
    uint256 indexed teeUpgradeId
);
```
