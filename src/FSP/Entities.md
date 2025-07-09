## Entities

An entity in FSP needs to provide and register 5 addresses to participate in protocols:

- identityAddress
- submitAddress
- submitSignaturesAddress
- signingPolicyAddress
- delegationAddress

The addresses are registered via EntityManager smart contract by first calling propose...Address from the identityAddress and then calling confirm...Address from proposed address.

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