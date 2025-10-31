# FlareTEE Extensions

Applications within the FlareTEE infrastructure managed via a system of *extensions*. Each application is run on an extension,  defining the code deployed by TEEs participating in the application along with other information. An initial extension, known as the *system extension*, operates certain TEE protocols necessary for the functionality of the TEE infrastructure. New extensions can be proposed and managed by users on Flare. Functionally, TEE extensions extend the concept of smart contracts on Flare to enable the use of TEE machines.

## Defining an Extension
An individual TEE extension consists of an isolated set of functionalities supported by a specified set of TEE machines. By nature, extensions are designed to be flexible, and thus are defined by only two features:

- A set of one or more supported *code versions*. A code version is defined as a hash of the docker image running in a virtual machine inside a TEE machine, and must be reproducible. These define the functionality of the extension.
- A set of TEE machines registered to the extension, which run the supported code versions. Each is identified by a unique TEE identity. Registering a TEE to an extension is described in [reference].

This pair is sufficient for enabling the desired functionality of an extension: a specified set of TEEs each run the supported code and thus can implement the functions required by the extension.

## Initializing an Extension
To initialise a new extension, a Flare user issues calls the function `register(teeExtensionStateVerifier,teeExtensionInstructionsSender)` on the `teeExtensionRegistry` smart contract, with parameters $\mathrm{teeExtensionStateVerifier}$ and $\mathrm{teeExtensionInstructionSender}$ denoting the [?] and the address from which instructions will be sent to participating TEEs. The address that calls this function automatically becomes the owner of the extension; note that this address will typically differ from the instruction address.

The initialization call does not register any TEEs to the extension. These must be registered separately, as described in [cite TEE ownership].

## Extension Management
Once an extension has been initialized, the owner of the extension is responsible for its management. A variety of functions are available to the owner on the `teeExtensionRegistry` smart contract:

- `sendInstructions(instructionId, teeIds, opType, opCommand, message, cosigners, cosignerThreshold)`: sends an instruction of type $\text{instructionId}$ to the TEE machines with ids in $\text{teeIds}. More details can be found in [cite instructions].
- `setExtensionContracts(extensionId,teeExtensionStateVerifier,teeExtensionInstructionsSender)`: specifies new extension verifier and instruction sender addresses for the extension.
- `addTeeVersion(extensionId,version,codeHash,platforms,governanceHash)`: adds a new code version $\mathrm{version}$ to the extension, specifying the hash, supported platforms, and governance details.
- `disableCodeHashPlatform(extensionId,codeHash,platform)`: disables a code version on the extension.
- `addSystemSupportedPlatforms(platforms)`: adds new TEE platforms to the system extension
-  `proposeNewOwner(extensionId, address_new)`: proposes a new owner address `address_new` for the extension. To complete the change of ownership, the function `confirmOwnership(extensionId)` must be called from `address_new`.
- `registerSystemInstructionsSenders(instructionsSenders)`: registers a new instruction sender to the extension; this will typically be a smart contract on Flare that is permitted to send instructions. Registered senders can be unregistered with the command `unregisterSystemInstructionsSenders(instructionsSenders)`.

 
## Key Types
Do we need this?