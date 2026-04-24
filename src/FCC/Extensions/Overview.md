# TEE Extensions
Applications within the Flare Confidential Compute infrastructure are managed via a system of *extensions*.
Each application is run on an extension, defining the code deployed by TEEs participating in the application along with other information.
An [initial extension](SystemExtension.md), known as the *system extension*, operates certain TEE protocols necessary for the functionality of the TEE infrastructure.
New extensions can be proposed and managed by users on Flare. Functionally, TEE extensions extend the concept of smart contracts on Flare to enable the use of TEE machines.

## Defining an Extension
An individual TEE extension consists of an isolated set of functionalities supported by a specified set of TEE machines.
Extensions are designed to be flexible, and thus are defined by only two features:

- A set of one or more supported *code versions*. A code version is defined as a hash of the docker image running in a virtual machine inside a TEE machine, and must be reproducible. These define the functionality of the extension.
- A set of TEE machines registered to the extension, which run the supported code versions. Each is identified by a unique TEE identity.

This pair is sufficient for enabling the desired functionality of an extension: a specified set of TEEs each run the supported code and thus can implement the instructions available on the extension.

## Extension Data Structure

Each extension registered on the `TeeExtensionRegistry` contract is identified by the following information:

- `owner`: The Flare address that owns and manages the extension.
- `stateVerifier`: The `ITeeExtensionStateVerifier` contract used for on-chain state verification.
- `instructionsSender`: The contract address permissioned to send instructions on this extension.
- `supportedCodeHashes`: The set of allowed code for TEE machines on this extension, identified by their code hashes (docker images).
- `supportedKeyTypes`: The set of wallet key types supported by the extension (e.g., `EVM`, `XRP`).

## System vs. Custom Extensions

Extensions are identified by a unique extension ID.
Extension ID $0$ is reserved for the [system extension](SystemExtension.md), which hosts core infrastructure (PMW and FDC2). Custom extensions use extension IDs greater than $0$.

The distinction is enforced via an operation type prefix system.
System operations use the `F_` prefix (e.g., `F_WALLET`, `F_XRP`, `F_FDC2`) and are handled by dedicated processors on every TEE machine.
System operations include both fundamtenal TEE operations necessary for all extensions and operations specific to the [system extension's](SystemExtension.md) PMW and FDC2 applications.
Sending system operations using `sendInstructions()` is restricted to the system extension unless the caller is a governance-registered system instruction sender.
Custom operations do not use the `F_` prefix.

## Initializing an Extension
To initialize a new extension, a Flare user calls the function `register(teeExtensionStateVerifier, teeExtensionInstructionsSender)` on the `teeExtensionRegistry` smart contract, with the two parameters definining the state verifier and instruction sender address for the extension.
The address that calls this function automatically becomes the owner of the extension; note that this address will typically differ from the instruction sender address.

The initialization call does not register any TEEs to the extension, which must be registered separately as described [here](../TeeManagement/Registration.md).

## Extension Lifecycle
Compute extensions may change or upgrade code versions over time, incorporating additional functionalities or deprecating existing ones.
This is achieved by adding and/or removing active code versions on the extension as described in the next section.
Each extension is created and managed by its owner account, typically a multisig governance account specific to the extension.

While TEE machines within an extension may run the same code, their state can differ.
For example, in the case of [PMWs](PMW.md), each TEE machine has different wallet keys.
Each machine may behave differently based on its state.
Users interact with selected machines via their specific identities and execute functions on them, whose outputs depend on this state.
Users may employ multiple machines for redundancy and multisig-type consensus calculations to partially circumvent this.

## Extension Management
Once an extension has been initialized, the owner of the extension is responsible for its management.
A variety of functions are available on the `teeExtensionRegistry` smart contract.

### Extension Owner Functions
- `register(teeExtensionStateVerifier, teeExtensionInstructionsSender)`: Creates a new extension. Returns the assigned extension ID.
- `setExtensionContracts(extensionId, teeExtensionStateVerifier, teeExtensionInstructionsSender)`: Specifies replacement extension verifier and instruction sender addresses.
- `addTeeVersion(extensionId, version, codeHash, platforms, governanceHash)`: Adds a new code version to the extension, identified by its code hash, supported platforms (e.g., `SEV`, `TDX`), and governance details.
- `disableCodeHashPlatform(extensionId, codeHash, platform)`: Disables a code version and platform combination on the extension.
- `addSupportedKeyTypes(extensionId, keyTypes)`: Adds additional supported key types to the extension.
- `removeSupportedKeyTypes(extensionId, keyTypes)`: Removes supported key types from the extension.
- `proposeNewOwner(extensionId, newOwner)`: Proposes a new owner address for the extension. To complete the change of ownership, `confirmOwnership(extensionId)` must be called from the new owner address.
- `confirmOwnership(extensionId)`: Confirms and completes the ownership transfer.

### Sending Instructions

- `sendInstructions(teeIds, instructionParams)`: Sends an instruction to the specified TEE machines. The `instructionParams` struct contains `opType`, `opCommand`, `message`, `cosigners`, `cosignersThreshold`, and `claimBackAddress`. All TEE machines must belong to the same extension. The caller must be either the extension's `instructionsSender` or a registered system instruction sender.

### System Administration Functions (Governance Only)

These functions are only available for the system extension (ID $0$) and require governance privileges:

- `addSystemSupportedPlatforms(platforms)`: Adds new TEE hardware platforms.
- `addSystemSupportedKeyTypesAndSigningAlgos(keyTypes, signingAlgos)`: Registers key types and signing algorithms for the system extension.
- `registerSystemInstructionsSenders(instructionsSenders)`: Whitelists instruction sender contracts for the system extension.
- `unregisterSystemInstructionsSenders(instructionsSenders)`: Removes instruction sender contracts from the system extension whitelist.