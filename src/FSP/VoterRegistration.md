# Voter Registration

An entity has 5 addresses to fully participate in the protocols:

- identityAddress
- submitAddress
- submitSignaturesAddress
- signingPolicyAddress
- delegationAddress

The addresses are register via EntityManager smart contract by first calling propose...Address from the identityAddress and then calling confirm...Address from proposed address.

## Entity Manager

Entity manager is used for address and node IDs registration.
The registered addresses and nodes have to be registered before `RandomAcquisitionStarted` event to be considered in the signing policy.

### Node ID

Registering node ID is done by calling

```Solidity
function registerNodeId(bytes20 _nodeId, bytes calldata _certificateRaw, bytes calldata _signature) external;
```

from the identityAddress.

A node ID can be unregistered by calling

```Solidity
function unregisterNodeId(bytes20 _nodeId) external;
```

from address that has node ID registered to.

### Addresses

The addresses are registered by first calling propose\<addressType>Address from the identity address and
then calling confirm\<addressType>AddressRegistration from the proposed address.

For example, to set set the submitAddress, an entity first calls

```Solidity
function proposeSubmitAddress(address _submitAddress) external;
```

with an that has not been registered before and then
calls

```Solidity
function confirmSubmitAddressRegistration(address _voter) external;
```

from the proposed address with identityAddress as an input.

## VoterRegistry

Entities have a time window in which they indicate intention to participate in the next signing policy.
The window starts with `VoterPowerBlockSelected` event and lasts at least 30 min (and 900 blocks) and until at least 10 entities are register.
The end of the window is indicate with `SigningPolicyInitialized` event emitted by Relay contract in the first block outside the window.

Registration is done on VoterRegistry smart contract using function

```Solidity
 function registerVoter(address _voter, Signature calldata _signature) external
```

on VoterRegistry smart contract.
Function can be called from any address, `_voter` has to be the identityAddress of the entity and `_signature` has to be ECDSA signature of `keccak256(abi.encode(rewardEpochId, _voter));` by private key corresponding to signingPolicyAddress as set on EntityManager smart contract before the latest `RandomAcquisitionStarted` event was emitted.

At registration the event

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

is emitted.
Registration weight of an entity is computed based on the amount staked to the entity (registered node IDs) on P-chain and on the amount delegated to the entity (delegationAddress) on C-chain at VoterPowerBlock.
The computation is done by FlareSystemCalculator smart contract.

At most 100 entities can be registered.
If 101st entity tries to register, the entity with the lowest registration weight is removed.
In such case, an event

```Solidity
event VoterRemoved(address indexed voter, uint256 indexed rewardEpochId);
```

is emitted, indicating the removal of the entity with identityAddress voter.

## VoterPreRegistry

PreRegistration is available on VoterPreRegistry smart contract for the entities included in the current signing policy, from the start of the signing policy until the start of the registration period.

PreRegistration is done using function

```Solidity
function preRegisterVoter(address _voter, IIVoterRegistry.Signature calldata _signature) external;
```

The requirements for the input are the same as for the registerVoter function.

The registration of PreRegistered entities is triggered by [Daemon](Daemon.md) right after the `VoterPowerBlockSelected` event is emitted.

## Registration weight

Registration weight is calculated at registration using FlareSystemCalculator's function

```Solidity
function calculateRegistrationWeight(
    address _voter,
    uint24 _rewardEpochId,
    uint256 _votePowerBlockNumber
)
    external
    returns (uint256 _registrationWeight);
```

with VoterPowerBlockNumber selected for the reward epoch.

The registration weight is calculated as follows:

Let $p$ denote the entity, $W_P(p)$ the amount of FLR staked to their node IDs as shown by [P-Chain mirroring](Mirroring.md) and $W_D(p)$ the amount of WFLR delegated to their delegationAddress.
Let $W'_D(p) = \min\{W_D(p), 0.025 * \mathrm{totalSupplyWFLR}\}$ be the capped delegation amount (capped to $2.5\%$ of all the WFLR).

The registration weight is

$$
W_R(p)= \left(W'_D(p) + W_P(p)\right)^\frac{3}{4}.
$$

The exact computation is done by:

$$
W_R(p) = \mathrm{floor}\left(\mathrm{floor}\left(W^\frac{1}{2}\right)^\frac{1}{2}\right)\mathrm{floor}\left(W^\frac{1}{2}\right),
$$

where $W=W'_D(p) + W_P(p)$.

After the calculation the event

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

is emitted by FlareSystemsCalculator smart contract.

## WNatDelegationFee

Anyone who delegates WFLR to an entity is entitled to a proportional share of their rewards.
The entity gets a fee from the share in a set percentage.

The percentage is set on WNatDelegationFee smart contract with function

```Solidity
function setVoterFeePercentage(uint16 _feePercentageBIPS) external returns (uint256);
```

that has to be called from the identity address.
