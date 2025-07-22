# Entities
The FSP, and Flare's other enshrined protocols, rely on the participation of a variety of types of participants. These participants, and their requirements for participation, are laid out in this section.

## Participants
The entities that will be referred to throughout this documentation are:

- *Data Provider*: The entities responsible for the core functionality of Flare's protocols, who provide data and perform off-chain computations required for enshrined protocols. Unless otherwise specified, an *entity* referred to in the FSP will mean a data provider.
- *Voter*: Another name for data providers, typically used in cases where data provider's are voting on the acceptance of an event.
- *User*: Any owner of an address on the Flare network.
- *Governance*: The Flare network's system for updating itself, such as modifying system parameters or introducing new protocols. Proposals are submitted by the Flare Foundation, then voted upon by all users holding wrapped Flare tokens.
- *Delegator*: A user who has delegated wrapped FLR tokens to a data provider address.

## Addresses 
All participants on the Flare network are identified by their unique identityAddress. Additionally, data providers in the FSP need to provide and register 5 addresses to participate in enshrined protocols:

- identityAddress
- submitAddress
- submitSignaturesAddress
- signingPolicyAddress
- delegationAddress.

Each such address is registered via the EntityManager smart contract by first calling propose\<addressType>Address from the provider's identityAddress and then calling confirm\<addressType>Address from the respective proposed address.

## Entity Manager
The Entity manager contract is used for address and node ID registration.
The registered addresses and nodes have to be registered before `RandomAcquisitionStarted` event to be considered in the signing policy of the next reward epoch.

### Node ID
Registering a new node ID is done by calling
```Solidity
function registerNodeId(bytes20 _nodeId, bytes calldata _certificateRaw, bytes calldata _signature) external;
```
from the owner's identityAddress.

A node ID can be unregistered by calling
```Solidity
function unregisterNodeId(bytes20 _nodeId) external;
```
from the address that has the respective node ID registered to it.
