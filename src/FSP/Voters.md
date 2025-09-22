# Voters

Flare's enshrined protocols operate using a voting-based consensus mechanism facilitated by the Flare Systems Protocol (
FSP). 
To participate in the FSP, data providers must register as _entities_, and go through the _voter_ registration process every reward epoch.

## Entity Definition

To participate in FSP, a data provider must first create an _entity_ through the [EntityManager](https://github.com/flare-foundation/flare-smart-contracts-v2/blob/main/contracts/protocol/implementation/EntityManager.sol) smart contract.

An entity is defined by the following set of addresses:
1. `identityAddress`: The primary identifier, used for administrative functions. It is not needed during
   the actual voting process and is meant to be secured in cold storage.
2. `submitAddress`: Used for submitting protocol-specific data during voting rounds.
3. `submitSignaturesAddress`: Used for submitting signed voting round result data transactions for finalization.
4. `signingPolicyAddress`: Used for signing policy-related operations.
5. `delegationAddress`: Used for receiving WFLR token delegation from users. 

## Entity Registration

Each address must be registered via a two-step process on the `EntityManager` smart contract:

1. **Proposal Phase**: Call `propose<addressType>Address` from the entity's identityAddress
2. **Confirmation Phase**: Call `confirm<addressType>Address` from the respective proposed address
   This two-step process ensures that the entity controls all registered addresses.

Additionally, then entity must link their validator node(s) by registering the corresponding node IDs.
This is done by calling `registerNodeId` from the entity's `identityAddress`.

To participate in the FTSO [block-latency feeds](../FTSO/BlockLatency.md) protocol, the entity must also generate and register a sortition key, which is done by calling `registerPublicKey` from the entity's `identityAddress`.

## Voter Definition

An entity can become a _voter_ by registering through the [VoterRegistry](https://github.com/flare-foundation/flare-smart-contracts-v2/blob/main/contracts/protocol/implementation/VoterRegistry.sol) smart contract.
A voter is able to participate in sub-protocols by [submitting](Submission.md) and [finalizing](./Finalization.md) voting round data, obtaining [rewards](Rewarding.md) for high quality submissions and honest behaviour.

## Voter Registration
Voter registration is valid for the duration of a reward epoch ($3.5$ days). During each reward epoch, there is a specific registration window where entities can register as voters for the _next_ reward epoch. See the [Signing Policy Definition Protocol](SigningPolicy.md) for more details.

### VoterRegistry
Entities can register through the `VoterRegistry` smart contract using the function:
```Solidity
 function registerVoter(address _voter, Signature calldata _signature) external
```
It can be called from any address. The `_voter` parameter should be the `identityAddress` of the entity and `_signature`, an ECDSA signature of `abi.encode(rewardEpochId, _voter)` [signed](../Utilities/Signing.md) by the entity's `signingPolicyAddress` key.

On successful registration the [VoterRegistered](https://github.com/flare-foundation/flare-smart-contracts-v2/blob/main/contracts/userInterfaces/IVoterRegistry.sol#L23) event is emitted.

### VoterPreRegistry
Since the registration window is relatively short (typically less than $1 $hour) a *pre-registration* mechanism is provided to reduce the chance of entities missing registration.
Entities included (registered) in the current signing policy can pre-register for the next reward epoch during almost the entire duration of the current reward epoch (up until the point when the regular registration window starts).

Entities can pre-register through the [VoterPreRegistry](https://github.com/flare-foundation/flare-smart-contracts-v2/blob/main/contracts/protocol/implementation/VoterPreRegistry.sol) smart contract using the function:
```Solidity
function preRegisterVoter(address _voter, IIVoterRegistry.Signature calldata _signature) external;
```
The requirements on the inputs are the same as for the `registerVoter` function above.

On successful pre-registration the [VoterPreRegistered](https://github.com/flare-foundation/flare-smart-contracts-v2/blob/main/contracts/userInterfaces/IVoterPreRegistry.sol#L9C11-L9C29) event is emitted.

The actual registration of pre-registered entities is triggered by the [Daemon](https://gitlab.com/flarenetwork/flare-smart-contracts/-/blob/master/docs/specs/flareDaemon.md) smart contract immediately after the `VoterPowerBlockSelected` event is [emitted](SigningPolicy.md#vote-power-block-selection).