# TEE Extensions
Applications within the Flare Confidential Compute infrastructure are managed via a system of *extensions*.
Each application is run on an extension, defining the code deployed by TEEs participating in the application along with other information.
An [initial extension](System Extension.md), known as the *system extension*, operates certain TEE protocols necessary for the functionality of the TEE infrastructure.
New extensions can be proposed and managed by users on Flare. Functionally, TEE extensions extend the concept of smart contracts on Flare to enable the use of TEE machines.

## Defining an Extension
An individual TEE extension consists of an isolated set of functionalities supported by a specified set of TEE machines.
Extensions are designed to be flexible, and thus are defined by only two features:

- A set of one or more supported *code versions*. A code version is defined as a hash of the docker image running in a virtual machine inside a TEE machine, and must be reproducible. These define the functionality of the extension.
- A set of TEE machines registered to the extension, which run the supported code versions. Each is identified by a unique TEE identity.

This pair is sufficient for enabling the desired functionality of an extension: a specified set of TEEs each run the supported code and thus can implement the instructions available on the extension.

## Extension Data Structure

Each extension registered on the `TeeExtensionRegistry` contract has the following properties:

- `owner` — the Flare address that owns and manages the extension.
- `stateVerifier` — the `ITeeExtensionStateVerifier` contract used for on-chain state verification.
- `instructionsSender` — the contract address permitted to send instructions for this extension.
- `supportedCodeHashes` — the set of allowed code hashes (docker image hashes) for TEE machines on this extension.
- `supportedKeyTypes` — the set of wallet key types supported by the extension (e.g., `EVM`, `XRP`).

## System vs. Custom Extensions

Extensions are identified by a unique extension ID. Extension ID $0$ is reserved for the [system extension](System Extension.md), which hosts core infrastructure (PMW and FDC2). Custom extensions use extension IDs greater than $0$.

The distinction is enforced via an operation type prefix system:

- **System operations** use the `F_` prefix (e.g., `F_WALLET`, `F_XRP`, `F_FDC2`).
These are handled by dedicated built-in processors on every TEE machine, regardless of which extension the machine belongs to.
At the smart contract level, sending system operations via `sendInstructions()` is restricted to extension ID $0$, unless the caller is a governance-registered system instruction sender.
Some system operations (e.g., `F_WALLET` key operations, `F_GET`, `F_POLICY`) are fundamental TEE operations used by all extensions.
Others (e.g., `F_XRP`, `F_FDC2`) are specific to the [system extension's](System%20Extension.md) PMW and FDC2 applications.
- **Custom operations** do not use the `F_` prefix (e.g., `SAY_HELLO`, `ORDERBOOK`). These are forwarded by the TEE node to the extension service running alongside the TEE machine.

## Initializing an Extension
To initialize a new extension, a Flare user calls the function `register(teeExtensionStateVerifier, teeExtensionInstructionsSender)` on the `TeeExtensionRegistry` smart contract.
The address that calls this function automatically becomes the owner of the extension; note that this address will typically differ from the instruction sender address.

The initialization call does not register any TEEs to the extension, which must be registered separately as described [here](../TEE Management/Ownership.md).

## Extension Lifecycle
Compute extensions may change or upgrade code versions over time, incorporating additional functionalities or deprecating existing ones. This is achieved by adding and/or removing active code versions on the extension as described in the next section.
Each extension is created and managed by its owner account, typically a multisig governance account specific to the extension.

While TEE machines within an extension may run the same code, their state can differ.
For example, in the case of [PMWs](PMW/PMW.md), each TEE machine has different wallet keys.
Each machine may behave differently based on its state.
Users interact with selected machines via their specific identities and execute functions on them, whose outputs depend on this state.
Users may employ multiple machines for redundancy and multisig-type consensus calculations to partially circumvent this.

## Action Routing

When a TEE node receives an action, it routes it based on the operation type:

1. If the `(opType, opCommand)` pair matches a registered system processor (e.g., `F_WALLET::KEY_GENERATE`), it is executed by the dedicated processor.
2. If the pair is not registered and the TEE node is configured with the `ForwardRouter` (for custom extensions), the action is forwarded via HTTP to the extension service running on `localhost` at the configured extension port.
3. The extension service processes the action and returns an `ActionResult`.

The `PMWRouter` (used for system-extension-only TEEs) does not have default forwarding — unregistered operations return an error.

## Extension Management
Once an extension has been initialized, the owner of the extension is responsible for its management.
A variety of functions are available on the `TeeExtensionRegistry` smart contract:

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

- `sendInstructions(instructionId, teeIds, opType, opCommand, message, cosigners, cosignerThreshold)`: Sends an instruction to the specified TEE machines. All TEE machines must belong to the same extension. The extension's `instructionsSender` contract must be the caller.

### System Administration Functions (Governance Only)

These functions are only available for the system extension (ID $0$) and require governance privileges:

- `addSystemSupportedPlatforms(platforms)`: Adds new TEE hardware platforms.
- `addSystemSupportedKeyTypesAndSigningAlgos(keyTypes, signingAlgos)`: Registers key types and signing algorithms for the system extension.
- `registerSystemInstructionsSenders(instructionsSenders)`: Whitelists instruction sender contracts for the system extension.
- `unregisterSystemInstructionsSenders(instructionsSenders)`: Removes instruction sender contracts from the system extension whitelist.

### Instruction Validation

When `sendInstructions` is called, the contract validates:

1. All TEE machines belong to the same extension ID.
2. Non-production TEEs are rejected for non-system operations.
3. The caller must be either a registered system instruction sender or the extension's designated `instructionsSender`.
4. For non-system-sender callers, system operations (`F_` prefix) can only be sent from extension ID $0$.
5. The fee is sufficient to cover the operation.
6. The cosigner threshold does not exceed the number of cosigners.
