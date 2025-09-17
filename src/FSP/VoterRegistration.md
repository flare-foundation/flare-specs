# Voter Registration

## Voter Registry
During each reward epoch, there is a specific time window in which entities can indicate their intention to participate in the next signing policy. The window starts when the `VoterPowerBlockSelected` event is is emitted by the FlareSystemsManager contract (see [todo:cite signing policy section on this]) and lasts at least 30 minutes (900 blocks) and until at least 10 entities are registered. The end of the window is indicated by the `SigningPolicyInitialized` event emitted by the Relay contract in the first block outside the registration window.

Entities register on the VoterRegistry smart contract using the function
```Solidity
 function registerVoter(address _voter, Signature calldata _signature) external
```

An entity can call this function from any address. When an entity calls this function to register, `_voter` has to be the identityAddress of the entity and `_signature` has to be ECDSA signature of `keccak256(abi.encode(rewardEpochId, _voter));` prefixed by `"\x19Ethereum Signed Message:\n32"` which is signed by the private key corresponding to the signingPolicyAddress set on the EntityManager smart contract before the latest `RandomAcquisitionStarted` event was emitted.  

Upon registration of an entity the [VoterRegistered](https://github.com/flare-foundation/flare-smart-contracts-v2/blob/main/contracts/userInterfaces/IVoterRegistry.sol#L23) event is emitted. 

### Voter PreRegistry
Pre-registration for the next signing policy is available on the VoterPreRegistry smart contract for entities included in the current signing policy. It is available from the start of the signing policy until the start of the registration period. PreRegistration is performed by an entity using the function
```Solidity
function preRegisterVoter(address _voter, IIVoterRegistry.Signature calldata _signature) external;
```
The requirements on the inputs are the same as for the registerVoter function.
The registration of PreRegistered entities is triggered by the[Daemon](Contracts/Daemon.md) smart contract immediately after the `VoterPowerBlockSelected` event is emitted.


### Maximum Entity Count
At most 100 entities can be registered in a single signing policy. If a 101st entity tries to register, the entity with the lowest registration weight is removed. In such case, an event
```Solidity
event VoterRemoved(address indexed voter, uint256 indexed rewardEpochId);
```
is emitted, indicating the removal of the entity whose identityAddress is voter.


## Registration weight
The registration weight of an entity is computed based on the amount staked to the entity (or its registered node IDs) on P-chain and on the amount delegated to the entity (at its delegationAddress) on C-chain during the VoterPowerBlock. The computation is done by FlareSystemCalculator smart contract. This weight is calculated at registration using FlareSystemCalculator's function:
```Solidity
function calculateRegistrationWeight(
 address _voter,
 uint24 _rewardEpochId,
 uint256 _votePowerBlockNumber
)
 external
 returns (uint256 _registrationWeight);
```
with VoterPowerBlockNumber selected for the reward epoch. The registration weight is calculated in the same manner as the signing weight [todo:link]. After the calculation the [VoterRegistrationInfo](https://github.com/flare-foundation/flare-smart-contracts-v2/blob/main/contracts/userInterfaces/IFlareSystemsCalculator.sol#L11) event is emitted by the FlareSystemsCalculator smart contract.

## WNatDelegationFee
Anyone who delegates WFLR to an entity is entitled to a proportional share of their rewards, known as delegation rewards. In return, the entity implicitly charges a fee to its delegators: a percentage of delegation rewards are given to the entity, with each entity able to this percentage themselves.

The percentage is set by each entity on the WNatDelegationFee smart contract by calling the function
```Solidity
function setVoterFeePercentage(uint16 _feePercentageBIPS) external returns (uint256);
```
which is called from the entity's identity address.

