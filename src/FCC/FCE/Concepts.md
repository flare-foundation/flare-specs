# Extension Concepts

A _Flare Compute Extension_ (FCE) packages an application on [Flare Confidential Compute](../README.md): a set of supported code versions, a set of TEE machines registered to run them, and (if required) a pool of [projects, wallets, and keys](../Concepts/Wallets.md).

Each extension has a unique `extensionId`.
Extension ID $0$ is reserved for the [system extension](System.md), which hosts FCC's PMW and FDC2 applications.
IDs $1$–$65535$ are reserved for governance minted extensions (`registerReserved`, immediate governance only).
Public `register` allocates IDs from $65536$ upward for custom extensions.

All extension state information lives on the [`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md) contract.

## Extension Data

Each extension is identified by:

- `owner`: the address that owns and manages the extension. Changed via a two-step `proposeNewOwner` / `confirmOwnership` transfer. Ownership is gated by the extension owner allowlist on `OwnerAllowlistFacet`.
- `stateVerifier`: the `ITeeExtensionStateVerifier` contract used for on-chain state verification.
- `instructionsSender`: the contract permissioned to call `sendInstructions` on this extension. See [Instructions Senders](#instructions-senders).
- `supportedCodeHashes`: the set of code hashes (Docker images) that registered [TEE machines](../Reference/Components/Machine.md) may run.
- `supportedKeyTypes`: the set of [wallet key types](../Concepts/Keys.md#key-types) the extension permits (e.g. `EVM`, `XRP`).
- `operatorAddress` (optional): an address that can perform certain preparation operations otherwise restricted to `owner`. Set by the `owner`.

The `(extensionId, instructionsSender, stateVerifier, supportedCodeHashes, supportedKeyTypes)` tuple is sufficient to operate an extension: registered TEE machines run one of the supported code versions and process [instructions](../Concepts/Instructions.md) routed through `sendInstructions`.

## System vs. Custom Extensions

The distinction between the two types is enforced by an operation-type prefix:

- **System operations**: use the `F_` prefix (e.g. `F_WALLET`, `F_XRP`, `F_FDC2`) and are handled in-process by the [node app](../Reference/Components/Machine.md) on every TEE machine. They cover both infrastructure operations (registration, key management, signing policy updates) and the system extension's PMW and FDC2 applications. `F_`-prefixed instructions can be sent only by a registered [system instructions sender](#instructions-senders).
- **Custom operations**: have no `F_` prefix and are dispatched to the FCE's own [extension app](../Reference/Components/Machine.md) over a [local HTTP interface](Reference/Api.md).

## Instructions Senders

Two roles can call [`sendInstructions`](../Reference/Contracts/FlareTeeManager.md) on `FlareTeeManager` to submit instructions to TEE proxies:

- **Extension's instructions sender**: the contract address stored in the extension's `instructionsSender` field. May send any non-system instruction to TEE machines registered to its extension.
- **System instructions sender**: any address whitelisted by governance via `registerSystemInstructionsSenders`. May send `F_`-prefixed system instructions to any TEE machine and may call the `sendSystemInstructions` overloads that take an externally chosen `instructionId`.

## Lifecycle

An extension is initialized when a Flare address calls:

```solidity
register(teeExtensionStateVerifier, teeExtensionInstructionsSender)
```

on `FlareTeeManager`.
The caller becomes the extension's `owner` and the extension is assigned a fresh `extensionId`.
The designated `teeExtensionInstructionsSender` address becomes the extension's instruction sender; typically distinct from the `owner`.
[TEE machines are registered separately](../Concepts/Machines.md).

Extensions may evolve over time, adding and disabling code versions through [management calls](#management-calls).
Each machine runs the extension's code against its own state; for the system extension's PMW, every machine holds different wallet keys.
Users typically operate against multiple machines for redundancy and multisig-style consensus.

## Management Calls

Functions exposed by `FlareTeeManager` for managing extensions:

### Extension Owner

- `register(stateVerifier, instructionsSender)`: creates a new extension. Returns the assigned `extensionId`.
- `setExtensionContracts(extensionId, stateVerifier, instructionsSender)`: replaces the state verifier and instructions sender.
- `addTeeVersion(extensionId, version, codeHash, platforms)`: adds a code version (identified by `codeHash`) for the listed `platforms` (e.g. `SEV`, `TDX`).
- `disableCodeHashPlatforms(extensionId, codeHash, platforms)`: disables one or more `(codeHash, platform)` combination(s).
- `addSupportedKeyTypes(extensionId, keyTypes)`, `removeSupportedKeyTypes(extensionId, keyTypes)`: edit the set of supported key types.
- `proposeNewOwner(extensionId, newOwner)`, `confirmOwnership(extensionId)`: two-step ownership transfer. Changes the ownership of the extension to `newOwner`.

### Sending Instructions

- `sendInstructions(teeIds, instructionParams)`: sends an [instruction](../Concepts/Instructions.md) to the specified TEE machines. The `instructionParams` struct carries `opType`, `opCommand`, `message`, `cosigners`, `cosignersThreshold`, and `claimBackAddress`. All target machines must belong to the same extension. Caller must be the extension's `instructionsSender` or a system instructions sender; for system extension calls, the caller must additionally be a system instructions sender when sending an `F_` op-type.
- `sendSystemInstructions(instructionId, teeIds, instructionParams)`: system-only overloads that let the caller supply an externally chosen `instructionId`. Caller must be a system instructions sender.

### Governance (system extension only)

- `addSystemSupportedPlatforms(platforms)`: adds supported `platform` values for machine registration.
- `removeSystemSupportedPlatforms(platforms)`: removes supported `platform` values for machine registration.
- `addSystemSupportedKeyTypesAndSigningAlgos(keyTypes, signingAlgosByKeyType)`: registers key types and matching [signing algorithms](../Concepts/Keys.md#signing-algorithms) for the system extension.
- `removeSystemSupportedKeyTypesAndSigningAlgos(keyTypes, signingAlgosByKeyType)`: removes supported key types and matching signing algorithms for the system extension. Does not block key types and signing algorithms on existing projects, only new ones.
- `registerSystemInstructionsSenders(instructionsSenders)`, `unregisterSystemInstructionsSenders(instructionsSenders)`: manage the system instructions sender whitelist.
