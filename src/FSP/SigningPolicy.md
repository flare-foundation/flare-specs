# Signing Policy

## Signing Policy lifecycle

1. An event `RandomAcquisitionStarted` is emitted by FlareSystemsManager smart contract indicating the start of a secure random acquisition process.
2. An event `VotePowerBlockSelected` is emitted by FlareSystemsManager smart contract indicating that a secure random has been acquired and the vote power block has been selected.
   It also signifies the beginning of the voter registration period.
3. An event `SigningPolicyInitialized` is emitted by Relay contract indicating that the voter registration period has ended and the signing policy is assembled and initialized.
4. An event `RewardEpochStarted` is emitted by FlareSystemsManager indication the start of the reward epoch and the start of uptime voting window.
5. Events `UptimeVoteSigned` are emitted by FlareSystemsManager whenever a voter successfully votes for an uptime using signUptimeVote function on FlareSystemsManager.
   Once such an event has thresholdReached parameter with value true, the uptime voting window closes and the reward voting window starts.
6. Events `RewardsSigned` are emitted by FlareSystemsManager whenever a voter successfully votes for [rewards](Rewarding.md).
   Once such an event has thresholdReached parameter with value true, the reward voting window closes and the rewards are available for claiming.

## Random Acquisition Process and Vote Power Block

`RandomAcquisitionStarted` event for rewardEpochId $j$ is emitted in the first block with timestamp over

$$ \mathrm{max}(\mathrm{expectedStart}(j)- \mathrm{initializationDuration}, \mathrm{start}(j-1)) $$
and it indicated the start of the random acquisition process.
Starting from the next block, a random number is queried from Relay smart contract using [getRandomNumber](./RandomNumber.md) function until:

- A secure random with a timestamp later than RandomAcquisitionStartedTs is acquired.
  In this case, VotePowerBlock is calculated with the secure random.
- randomAcquisitionMaxDurationBlocks (15000 blocks) and randomAcquisitionMaxDurationTime (8 hours) have passed.
  In this case, either:
  - Unsecure random is used to compute VotePowerBlock if $j$ is the initial rewardEpoch.
  - random and VotePowerBlock of the previous reward epoch are used.

When the VotePowerBlock is selected the event

```solidity
VotePowerBlockSelected(j, votePowerBlock, block.timestamp);
```

is emitted.

## Voter Registration

After the VotePowerBlockSelected event, entities can register on [VoterRegistry](VoterRegistration.md#voterregistry) smart contract using registerVoter functions until:

- voterRegistrationDurationTime (30 min) has passed,
- voterRegistrationDurationBlocks (900 blocks) have passed, and
- at least a minimal number of entities (10) have registered.

The entities that are included in the active signing policy can [preregister](VoterRegistration.md#voterpreregistry) on VoterPerRegistry smart contract using preRegisterVoter function.

## Signing Policy Initialization

Signing policy initialization is managed by [Flare Daemon](Daemon.md).

`SigningPolicyInitialized` event

```Solidity
event SigningPolicyInitialized(
   uint24 indexed rewardEpochId,
   uint32 startVotingRoundId,
   uint16 threshold,
   uint256 seed,
   address[] voters,
   uint16[] weights,
   bytes signingPolicyBytes,
   uint64 timestamp
);
```

is emitted when a signing policy is initialized.

The uint256 `seed` is the random seed (obtained in Random Acquisition process).
The array `voters` contains signingPolicyAddresses of the entities, the position of the address in the array is the entity index.
The array `weights` contains normalized weights of entities, the weight at position $i$ corresponds to entity at position $i$.

See [SigningPolicy](/src/FSP/Encoding.md#signingpolicy) for the byte encoding of `signingPolicyBytes`.

### Normalized weights

Let $\mathrm{weightSum}$ be the sum of [registrationWeights](VoterRegistration.md#registration-weight) of all registered entities.
The normalized weight of an entity is
$$\mathrm{registrationWeight} * \mathrm{maxUint}16 /  \mathrm{weightSum},$$
where integer division is used.

Threshold is than one half of the sum of the normalized weights rounded up.

## Uptime Vote Signed
