# Events Reference

## FlareSystemsManager

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

## VoterRegistry

### VoterRegistered

```Solidity
event VoterRegistered(
    address indexed voter,
    uint24 indexed rewardEpochId,
    address indexed signingPolicyAddress,
    address submitAddress,
    address submitSignaturesAddress,
    bytes32 publicKeyPart1,
    bytes32 publicKeyPart2,
    uint256 registrationWeight
);
```

## FlareSystemsCalculator

### VoterRegistrationInfo

```Solidity
event VoterRegistrationInfo(
    address indexed voter,
    uint24 indexed rewardEpochId,
    address delegationAddress,
    uint16 delegationFeeBIPS,
    uint256 wNatWeight,
    uint256 wNatCappedWeight,
    bytes20[] nodeIds,
    uint256[] nodeWeights
);
```