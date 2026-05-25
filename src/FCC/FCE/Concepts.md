# Extension Concepts

A _Flare Compute Extension_ (FCE) packages an application on [Flare Confidential Compute](../README.md): a set of supported code versions, a set of TEE machines registered to run them, and (for extensions whose machines custody long-lived signing keys) a pool of [projects, wallets, and keys](../Concepts/Wallets.md).
Each extension has a unique `extensionId`.
Extension ID $0$ is reserved for the [system extension](System.md), which hosts FCC's PMW and FDC2 applications; custom extensions use IDs greater than $0$.

All extension state lives on the [`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md) contract.

## Extension Data

Each extension is identified by:

- `owner`: The Flare address that owns and manages the extension. Changed via a two-step `proposeNewOwner` / `confirmOwnership` transfer.
- `stateVerifier`: The `ITeeExtensionStateVerifier` contract used for on-chain state verification.
- `instructionsSender`: The contract permissioned to call `sendInstructions` on this extension. See [Instructions Senders](#instructions-senders).
- `supportedCodeHashes`: The set of code hashes (Docker images) that registered [TEE machines](../Reference/Components/Machine.md) may run.
- `supportedKeyTypes`: The set of [wallet key types](../Concepts/Keys.md#key-types) the extension permits (e.g. `EVM`, `XRP`).

The `(extensionId, instructionsSender, stateVerifier, supportedCodeHashes, supportedKeyTypes)` tuple is sufficient to operate an extension: registered TEE machines run one of the supported code versions and process [instructions](../Concepts/Instructions.md) routed through `sendInstructions`.

## System vs. Custom Extensions

The distinction is enforced by an operation-type prefix:

- _System operations_ use the `F_` prefix (e.g. `F_WALLET`, `F_XRP`, `F_FDC2`) and are handled in-process by the [node app](../Reference/Components/Machine.md) on every TEE machine. They cover both infrastructure operations (registration, key management, signing-policy updates) and the system extension's PMW and FDC2 applications. `F_`-prefixed instructions can be sent only by the system extension's instructions sender or by a registered [system instructions sender](#instructions-senders).
- _Custom operations_ have no `F_` prefix and are dispatched to the FCE's own [extension app](../Reference/Components/Machine.md) over a [local HTTP interface](Reference/Api.md).

## Instructions Senders

Two roles can call [`sendInstructions`](../Reference/Contracts/FlareTeeManager.md) on `FlareTeeManager`:

- An _extension's instructions sender_: the contract address stored in the extension's `instructionsSender` field. May send any non-system (`opType` without the `F_` prefix) instruction to TEE machines registered to its extension.
- A _system instructions sender_: any address whitelisted by governance via `registerSystemInstructionsSenders` (removed with `unregisterSystemInstructionsSenders`). May send `F_`-prefixed system instructions to any TEE machine and may call the `sendSystemInstructions` overloads that take an externally chosen `instructionId`.

## Lifecycle

An extension is initialized when a Flare address calls:

```solidity
register(teeExtensionStateVerifier, teeExtensionInstructionsSender)
```

on `FlareTeeManager`.
The caller becomes the extension's `owner` (typically distinct from the instructions sender) and is assigned a fresh `extensionId`.
[TEE machines are registered separately](../Concepts/Machines.md).

Extensions may evolve over time, adding and disabling code versions through the [management calls](#management-calls).
Each machine runs the extension's code against its own state — for the system extension's PMW, every machine holds different wallet keys.
Users typically operate against multiple machines for redundancy and multisig-style consensus.

## Management Calls

Functions exposed by `FlareTeeManager` for managing extensions:

### Extension Owner

- `register(stateVerifier, instructionsSender)`: Creates a new extension. Returns the assigned `extensionId`.
- `setExtensionContracts(extensionId, stateVerifier, instructionsSender)`: Replaces the state verifier and instructions sender.
- `addTeeVersion(extensionId, version, codeHash, platforms, governanceHash)`: Adds a code version (identified by `codeHash`) for the listed `platforms` (e.g. `SEV`, `TDX`).
- `disableCodeHashPlatform(extensionId, codeHash, platform)`: Disables a `(codeHash, platform)` combination.
- `addSupportedKeyTypes(extensionId, keyTypes)`, `removeSupportedKeyTypes(extensionId, keyTypes)`: Edit the set of supported key types.
- `proposeNewOwner(extensionId, newOwner)`, `confirmOwnership(extensionId)`: Two-step ownership transfer.

### Sending Instructions

- `sendInstructions(teeIds, instructionParams)`: Sends an [instruction](../Concepts/Instructions.md) to the specified TEE machines. The `instructionParams` struct carries `opType`, `opCommand`, `message`, `cosigners`, `cosignersThreshold`, and `claimBackAddress`. All target machines must belong to the same extension. Caller must be the extension's `instructionsSender` or a system instructions sender; for system-extension calls, the caller must additionally be a system instructions sender when sending an `F_` op-type.
- `sendSystemInstructions(instructionId, teeIds | teeMachines, instructionParams)`: System-only overloads that let the caller supply an externally chosen `instructionId`. Caller must be a system instructions sender.

### Governance (system extension only)

- `addSystemSupportedPlatforms(platforms)`: Adds TEE hardware platforms.
- `addSystemSupportedKeyTypesAndSigningAlgos(keyTypes, signingAlgosByKeyType)`: Registers key types and matching [signing algorithms](../Concepts/Keys.md#signing-algorithms) for the system extension.
- `registerSystemInstructionsSenders(instructionsSenders)`, `unregisterSystemInstructionsSenders(instructionsSenders)`: Manage the system-instructions-sender whitelist.
