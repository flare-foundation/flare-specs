# TeeVerification Events

### TeeAttestationRequested

Emitted by: `requestTeeAttestation()`

```solidity
event TeeAttestationRequested(
    address indexed teeId,
    bytes32 challenge
);
```

### AvailabilityCheckValidityExtended

Emitted by: `confirmAvailability()`

```solidity
event AvailabilityCheckValidityExtended(
    address indexed teeId,
    address indexed owner,
    uint256 endTs
);
```

### CosignersSet

Emitted by: `setCosigners()`

```solidity
event CosignersSet(
    address[] cosigners,
    uint64 cosignersThreshold
);
```

### SettingsUpdated

Emitted by: `updateSettings()`

```solidity
event SettingsUpdated(
    uint64 availabilityCheckValidityDurationSeconds,
    uint64 signingPolicyValidityDurationInRewardEpochs,
    uint64 challengeValidityDurationSeconds
);
```
