# TEE Extensions
Applications within the Flare Confidential Compute infrastructure managed via a system of *extensions*.
Each application is run on an extension, defining the code deployed by TEEs participating in the application along with other information. 
An [initial extension](System Extension.md), known as the *system extension*, operates certain TEE protocols necessary for the functionality of the TEE infrastructure. 
New extensions can be proposed and managed by users on Flare. Functionally, TEE extensions extend the concept of smart contracts on Flare to enable the use of TEE machines.

## Defining an Extension
An individual TEE extension consists of an isolated set of functionalities supported by a specified set of TEE machines. 
Extensions are designed to be flexible, and thus are defined by only two features:

- A set of one or more supported *code versions*. A code version is defined as a hash of the docker image running in a virtual machine inside a TEE machine, and must be reproducible. These define the functionality of the extension.
- A set of TEE machines registered to the extension, which run the supported code versions. Each is identified by a unique TEE identity.

This pair is sufficient for enabling the desired functionality of an extension: a specified set of TEEs each run the supported code and thus can implement the instructions available on the extension.

## Initializing an Extension
To initialise a new extension, a Flare user issues calls the function `register(teeExtensionStateVerifier,teeExtensionInstructionsSender)` on the `teeExtensionRegistry` smart contract, with parameters $\mathrm{teeExtensionStateVerifier}$ and $\mathrm{teeExtensionInstructionSender}$ denoting the [?] and the address from which [instructions](Instructions.md) can be issued. 
The address that calls this function automatically becomes the owner of the extension; note that this address will typically differ from the instruction address.

The initialization call does not register any TEEs to the extension, which must be registered separately as described [here](Ownership.md).

## Extension Lifecycle
Compute extensions may change or upgrade code versions over time, incorporating additional functionalities or deprecating existing ones. This is achieved by adding and/or removing active code versions on the extension as described in the next section. 
Each extension is created and managed by its owner account, typically a multisig governance account specific to the extension.

While TEE machines within an extension may run the same code, their state can differ.
For example, in the case of [PMWs](PMW.md), each TEE machine has different wallet keys.
Each machine may behave differently based on its state. 
Users interact with selected machines via their specific identities and execute functions on them, whose outputs depend on this state.
Users may employ multiple machines for redundancy and multisig-type consensus calculations to partially circumvent this.

## Extension Management
Once an extension has been initialized, the owner of the extension is responsible for its management.
A variety of functions are available to the owner on the `teeExtensionRegistry` smart contract:

- `sendInstructions(instructionId, teeIds, opType, opCommand, message, cosigners, cosignerThreshold)`: Sends an instruction of type $\text{instructionId}$ to the TEE machines with ids in $\text{teeIds}.
- `setExtensionContracts(extensionId,teeExtensionStateVerifier,teeExtensionInstructionsSender)`: Specifies replacement extension verifier and instruction sender addresses for the extension.
- `addTeeVersion(extensionId,version,codeHash,platforms,governanceHash)`: Adds a new code version $\mathrm{version}$ to the extension, identified by its code hash, supported platforms, and governance details.
- `disableCodeHashPlatform(extensionId,codeHash,platform)`: Disables a code version and platform, identified by the code hash, on the extension.
- `addSystemSupportedPlatforms(platforms)`: Adds new TEE platforms to the extension.
- `addSupportedKeyTypes(extensionId, keyTypes)`: Adds additional supported key types to the extension.
- `removeSupportedKeyTypes(extensionId, keyTypes)`: Removes supported key types from the extension.-  `proposeNewOwner(extensionId, address_new)`: Proposes a new owner address `address_new` for the extension. To complete the change of ownership, the function `confirmOwnership(extensionId)` must be called from `address_new` after the function is called, at which point ownership of the extension is transferred.
- `registerSystemInstructionsSenders(instructionsSenders)`: Registers a list of new instruction sender to the extension; this will typically be a smart contract on Flare that is permitted to send instructions. 
-`unregisterSystemInstructionsSenders(instructionsSenders)`: Unregisters a list of instruction senders from the extension.