# FlareSystemsManager

## Events

### RandomAcquisitionStarted

```solidity
  event RandomAcquisitionStarted(
    uint24 indexed rewardEpochId,
    uint64 timestamp
  );
```

### VotePowerBlockSelected

```solidity
  event VotePowerBlockSelected(
    uint24 indexed rewardEpochId,
    uint64 votePowerBlock,
    uint64 timestamp
  );
```

### RewardEpochStarted

```solidity
  event RewardEpochStarted(
    uint24 indexed rewardEpochId,
    uint32 startVotingRoundId,
    uint64 timestamp
  );
```
