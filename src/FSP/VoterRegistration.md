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

The registered addresses and nodes have to be set before RandomAcquisitionStarted event to be considered in the signing policy.

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
Function can be called from any address, `_voter` has to be the identity address of the voter and `_signature` has to be ECDSA signature of `keccak256(abi.encode(rewardEpochId, _voter));` by private key corresponding to signingPolicyAddress as set on Entity manager before the latest RandomAcquisitionStarted event was emitted.

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

Providers that are PreRegistered are Registered by Daemon right after the VoterPowerBlockSelected event is emitted.

## FlareSystemCalculator
