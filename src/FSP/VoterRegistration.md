# Voter Registration

A voter has 5 addresses to fully participate in the protocols:

- identityAddress
- submitAddress
- submitSignaturesAddress
- signingPolicyAddress
- delegationAddress

The addresses are register via EntityManager smart contract by first calling propose...Address from the identityAddress and then calling confirm...Address from proposed address.

## Entity Manager

Entity manager is used for address and node IDs registration.
The registered addresses and nodes have to be registered before RandomAcquisitionStarted event to be considered in the signing policy.

### Node ID

Registering node ID is done with registerNodeId function

```Solidity
function registerNodeId(bytes20 _nodeId, bytes calldata _certificateRaw, bytes calldata _signature) external;
```

from the identity address.

A node ID can be unregistered by calling

```Solidity
function unregisterNodeId(bytes20 _nodeId) external;
```

from address that has node ID registered to.

### Addresses

The addresses are registered by first calling propose\<addressType>Address from the identity address and
then calling confirm\<addressType>AddressRegistration from proposed address.

For example, to set set the submitAddress, a user first calls

```Solidity
function proposeSubmitAddress(address _submitAddress) external;
```

with a submit address that has not been registered before and then
calls

```Solidity
function confirmSubmitAddressRegistration(address _voter) external;
```

from the proposed submitAddress with identity address as an input.

## VoterRegistry

Providers have a time window starting with VoterPowerBlockSelected that lasts at least 30 min (and 900 blocks) and until at least 10 providers are register in which they indicate intention to participate in the next signing policy.
The end of the window is indicate with ends with SigningPolicyInitialized event emitted by Relay contract in the first block outside the window.

Registration is done on VoterRegistry smart contract using function

```Solidity
 function registerVoter(address _voter, Signature calldata _signature) external
```

on VoterRegistry smart contract.
Function can be called from any address, `_voter` has to be the identity address of the provider and `_signature` has to be ECDSA signature of `keccak256(abi.encode(rewardEpochId, _voter));` by private key corresponding to signingPolicyAddress as set on Entity manager before the latest RandomAcquisitionStarted event was emitted.

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
Registration weight is computed based on the amount staked to the provider (registered node IDs) on P-chain and on the amount delegated to the provider (delegation address) on C-chain at VoterPowerBlock.
The computation is done by FlareSystemCalculator smart contract.

At most 100 providers can be registered.
If 101st provider tries to register, the provider with the lowest registration weight is removed.
In such case, an event

```Solidity
event VoterRemoved(address indexed voter, uint256 indexed rewardEpochId);
```

is emitted, indicating the removed voter.

## VoterPreRegistry

PreRegistration is available on VoterPreRegistry smart contract for the providers included in the current signing policy, from the start of the signing policy until the start of the registration period.

PreRegistration is done using function

```Solidity
function preRegisterVoter(address _voter, IIVoterRegistry.Signature calldata _signature) external;
```

The registration of PreRegistered providers is triggered by [Daemon](Daemon.md) right after the VoterPowerBlockSelected event is emitted.

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

Let p denote the provider, $W_P(p)$ the amount of FLR staked to their node IDs as shown by [P-Chain mirroring](Mirroring.md) and $W_D(p)$ the amount of WFLR delegated to their delegationAddress.
Let $W'_D(p) = \min\{W_D(p), 0.025 * \mathrm{totalSupplyWFLR}\}$ be the capped delegation amount (capped to 2.5% of all the WFLR).

The registration weight is

TODO (exact computation)

$$
W_R(p)= \left(W'_D(p) + W_P(p)\right)^\frac{3}{4}.
$$

## WNatDelegationFee

Anyone who delegates WFLR to the provider is entitled to a proportional share of their rewards.
The provider gets a fee from the share in a set percentage.

The percentage is set on WNatDelegationFee smart contract with function

```Solidity
function setVoterFeePercentage(uint16 _feePercentageBIPS) external returns (uint256);
```

that has to be called from the identity address.
