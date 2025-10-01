# Signing Policy

The _Signing Policy_ record defines entities that are eligible to participate in FSP, and their corresponding voting power.
A new policy is generated for every reward epoch, denoting its starting voting epoch, registered entities (voters) and their weights, as well as the signing weight threshold required for policy updates and finalizations.
See [SigningPolicy](./Encoding.md/#signingpolicy) encoding reference for more details.

## Definition Protocol

The _Signing Policy Definition Protocol_ is a system protocol that produces the policy record for next reward epoch, which ensures that voters and their weights are locked and signed by a threshold weight of current voters.

The protocol works in phases, as follows:

1. **Random Number Acquisition**: $2$ hours before the end of the current reward epoch, a [random number](RandomNumber.md) is fetched through the FTSO protocol.
2. **Vote Power Block Selection**: Once a random number is obtained, a block from the current reward epoch is selected at random.
   The vote power registered in this selected block will be used for the new reward epoch.
3. **Voter Registration**: Once a random number is obtained, registration for the new reward epoch can begin.
   This lasts $30$ minutes, allowing self-registration based on the selected block's vote power.
4. **Signing Policy Snapshot**: When the voter registration phase ends, a snapshot of the data providers' addresses and weights is taken.
5. **Signing Policy Sign Phase**: After the voter registration phase, the signing phase begins.
   In this phase the data providers registered for the ongoing epoch submit signatures for updating the signing policy.
   This phase ends when the threshold of signatures is reached.
   Delays beyond $20$ minutes or $600$ blocks will incur penalties.

While there are no direct rewards, delays in finalization cause a global lock of reward claiming and additional penalization when claiming is finally allowed.
More specifically, each signer gets punished with burn of their fee claims, scaled quadratically with the length of the delay.

## Lifecycle

The protocol progress can be tracked by the following emitted smart contract events:

1. `FlareSystemsManager.RandomAcquisitionStarted`: indicates the start of a secure random acquisition process.
2. `FlareSystemsManager.VotePowerBlockSelected`: indicates that a secure random number has been acquired and the vote power block has been selected.
   It also signifies the beginning of the voter registration period.
3. `Relay.SigningPolicyInitialized`: indicates that the voter registration period has ended and the signing policy is assembled and initialized.
4. `FlareSystemsManager.RewardEpochStarted:`: indicates the start of the reward epoch.

The definition protocol is encoded in the [FlareSystemsManager](https://github.com/flare-foundation/flare-smart-contracts-v2/blob/main/contracts/protocol/implementation/FlareSystemsManager.sol#L257) smart contract, and the [Flare Daemon](Contracts/Daemon.md) ensures the relevant logic is triggered on every block.

## Random Acquisition

The `RandomAcquisitionStarted` event for reward epoch ID $j$ is emitted with the first block with timestamp $T$ such that:

$$ T \geq \mathrm{max}(\mathrm{expectedStart}(j)- \mathrm{initializationDuration}, \mathrm{start}(j-1)) $$

where:

* $\mathrm{expectedStart}(j)$ is the expected start time of the reward epoch $j$.
* $\mathrm{initializationDuration}$ is the duration of the signing policy initialization ($2$ hours).
* $\mathrm{start}(j-1)$ is the start time of the previous reward epoch $j-1$.

This timestamp $T$ is then used as the start of the random acquisition process, $T_\text{start}$.

Starting from the next block, the `Relay` smart contract is polled to retrieve a random number using the [getRandomNumber](./RandomNumber.md) function until either:

1. A secure random with a timestamp larger than $T_\text{start}$ is acquired.
2. $\mathrm{randomAcquisitionMaxDurationBlocks}$ ($15000$ blocks) and $\mathrm{randomAcquisitionMaxDurationTime}$ ($8$ hours) have passed with no secure random acquired.

## Vote Power Block Selection

If a secure random is acquired, it is used to select the voter power block for the next reward epoch.
Otherwise, the random and vote power block is re-used from the previous reward epoch.

Once the vote power block number is selected, the `VotePowerBlockSelected` event is emitted, triggering the start of voter registration.

## Voter Registration

Entities can register for the next reward epoch via the [VoterRegistry](Voters.md#voterregistry) smart contract.
Registration is open until the following three conditions governed by system parameters are met:

1. $\mathrm{voterRegistrationMinDurationSeconds}$: minimum duration of the voter registration window ($30$ min).
2. $\mathrm{voterRegistrationMinDurationBlocks}$: minimum duration of the voter registration window in blocks ($900$).
3. $\mathrm{signingPolicyMinNumberOfVoters}$: minimum number of registered voters required ($10$).

Entities included in the current signing policy can pre-register for the next reward epoch any time using the [VoterPreRegistry](Voters.md#voterpreregistry) smart contract.

## Maximum Entity Count

At most $100$ entities can be registered in a single signing policy.
If a $101$st entity tries to register, the entity with the lowest registration weight is removed.
In such case, an event:

```Solidity
event VoterRemoved(address indexed voter, uint256 indexed rewardEpochId);
```

is emitted, indicating the removal of the entity with `voter` corresponding to their `identityAddress`.

## Signing Policy Initialization

On the first block for which voter registration is no longer enabled, the signing policy for the next reward epoch is initialized, containing the chosen random seed and registered entities.
This causes the `SigningPolicyInitialized` event to be emitted by the `Relay` smart contract.

### Normalized weights

Let $\mathrm{weightSum}$ be the sum of [registrationWeights](Weighting.md#signing-weight) of all registered entities.
The normalized weight of an entity is

$$\mathrm{normalizedWeight} = \mathrm{registrationWeight} * \mathrm{max} \, \mathrm{uint}16 /  \mathrm{weightSum},$$

where integer division is used.

The signing threshold is then defined as one half of the sum of the normalized weights, rounded up.
