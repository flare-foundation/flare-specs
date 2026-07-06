# Configuration

State machine for bringing a new (custom) [FCE](../README.md) to a ready-to-receive-instructions configuration: registering it on chain, adding a supported code version, gating which addresses may register machines or create projects, declaring supported key types, and provisioning the first TEE machine's local settings.

For the framework concepts, see [FCE Concepts](../Concepts.md); contract surface in [`FlareTeeManager`](../../Reference/Contracts/FlareTeeManager.md).

## Preconditions

- The Flare TEE system contracts are deployed (the [`FlareTeeManager`](../../Reference/Contracts/FlareTeeManager.md) diamond and, if PMW is in use, the [`Payments`](../../../PMW/Reference/Contracts/Payments.md) family).
- The caller controls a funded Flare address.
- The FCE's TEE machine Docker image has a reproducible `codeHash`.
- A TEE proxy server is deployed (or planned) so machines can be paired with it.
- For `provisionTeeMachine`, a TEE machine is running inside an enclave (or in local dev mode with `MODE=1`), with the Configuration API reachable.

## States

- `Unregistered`: no on-chain record of the FCE.
- `Registered`: `register` has assigned an `extensionId`; the extension has an owner and an `instructionsSender`, but no code, key types, or allowlist entries.
- `CodeAdded`: at least one `(codeHash, platform)` combination is registered.
- `Allowlisted`: machine owner and project owner allowlists are populated (or explicitly opened with the "allow all" toggle).
- `KeyTypesAdded`: `supportedKeyTypes` contains at least one entry (or the FCE does not custody keys, in which case this state is skipped).
- `Provisioned`: the first TEE machine has been configured (proxy URL, initial owner, extension ID) and is ready to register.
- `OwnerTransferred` (optional): the extension's `owner` has been handed to a governance/multisig address via two-step transfer.

## Initial State

`Unregistered`.

## Transitions

### deployInstructionsSender: (off-chain) → preserves state

- **Action**: deploy the extension's `instructionsSender` contract. The contract has no required interface beyond calling [`FlareTeeManager.sendInstructions`](../../Reference/Contracts/FlareTeeManager.md#sending-instructions) on behalf of its users. Its address is needed by the next transition.
- **Caller**: any.
- **Effects**: no on-chain state change in `FlareTeeManager` yet; the address is recorded for use in `register`.

### register: Unregistered → Registered

- **Action**: `FlareTeeManager.register(stateVerifier, instructionsSender)` (the [`ExtensionManagerFacet`](../../Reference/Contracts/FlareTeeManager.md#facets) entry). Governance-reserved IDs ($1$–$65535$) are minted instead via `registerReserved(extensionId, owner)` (immediate-governance only); the public path described here allocates IDs from `nextPublicExtensionId` starting at $65536$.
- **Caller**: must be on the extension owner allowlist (`OwnerAllowlistFacet`, `allExtensionOwnersAllowed` toggle or explicit add by immediate governance). The caller becomes the extension's `owner`.
- **Guards**:
  - `instructionsSender ≠ 0`.
  - `msg.sender` is allowlisted as an extension owner.
- **Effects**:
  - Assigns a fresh `extensionId` from `nextPublicExtensionId` and increments it.
  - Stores `(owner = msg.sender, stateVerifier, instructionsSender)`.
  - Emits [`TeeExtensionRegistered`](../../Reference/Contracts/FlareTeeManagerEvents.md#teeextensionregistered) and [`TeeExtensionContractsSet`](../../Reference/Contracts/FlareTeeManagerEvents.md#teeextensioncontractsset).
  - The deployed `instructionsSender` should now call its own discovery function (typically `setExtensionId`) to learn its `extensionId` for later `sendInstructions` calls.

### addTeeVersion: Registered → CodeAdded (repeatable)

- **Action**: `FlareTeeManager.addTeeVersion(extensionId, version, codeHash, platforms)`.
- **Caller**: extension owner.
- **Guards**:
  - `version` non-empty.
  - `codeHash ≠ 0` and not already registered for this extension.
  - `platforms` non-empty, no duplicates, each one is system supported.
- **Effects**:
  - Records the `(codeHash, version, platforms)` tuple.
  - Each `(codeHash, platform)` pair is now eligible for [machine registration](../../Workflows/MachineRegistration.md).
  - Emits [`TeeVersionAdded`](../../Reference/Contracts/FlareTeeManagerEvents.md#teeversionadded).

### setAllowlists: Registered/CodeAdded → Allowlisted

- **Action**: any combination of `addAllowedTeeMachineOwners(extensionId, owners)`, `allowAllTeeMachineOwners(extensionId)`, `addAllowedTeeWalletProjectOwners(extensionId, owners)`, `allowAllTeeWalletProjectOwners(extensionId)` on the [`OwnerAllowlistFacet`](../../Reference/Contracts/FlareTeeManager.md#owner-allowlist).
- **Caller**: extension owner.
- **Effects**:
  - Machine owner and/or project owner allowlists are populated. The "allow all" variants open up participation.
  - Emits [`AllowedTeeMachineOwnersAdded`](../../Reference/Contracts/FlareTeeManagerEvents.md#allowedteemachineownersadded), [`AllTeeMachineOwnersAllowed`](../../Reference/Contracts/FlareTeeManagerEvents.md#allteemachineownersallowed), [`AllowedTeeWalletProjectOwnersAdded`](../../Reference/Contracts/FlareTeeManagerEvents.md#allowedteewalletprojectownersadded), or [`AllTeeWalletProjectOwnersAllowed`](../../Reference/Contracts/FlareTeeManagerEvents.md#allteewalletprojectownersallowed) as applicable.

### addKeyTypes: Allowlisted → KeyTypesAdded (skip if the FCE custodies no keys)

- **Action**: `FlareTeeManager.addSupportedKeyTypes(extensionId, keyTypes)`.
- **Caller**: extension owner.
- **Guards**: each entry of `keyTypes` is system supported (registered by governance via `addSystemSupportedKeyTypesAndSigningAlgos`).
- **Effects**: wallet projects under this extension can be created with one of the listed key types. Emits [`SupportedKeyTypesAdded`](../../Reference/Contracts/FlareTeeManagerEvents.md#supportedkeytypesadded).

### provisionTeeMachine: KeyTypesAdded → Provisioned

- **Action**: configure the TEE machine via its Configuration API (or via environment variables before boot):
  - `POST /proxy`: set the paired TEE proxy URL.
  - `POST /initial-owner`: set the machine's initial owner address. Immutable once set.
  - `POST /extension-id`: set the extension ID. Fixed after a successful [`TeeAvailabilityCheck`](../../../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md).
  - `POST /chain-ID`: the ID of the chain (e.g. Flare, Songbird) for the machine.
  - `POST /governance`: the governance signers and threshold for the machine.
- **Caller**: TEE machine owner (with network access to the machine's Configuration API).
- **Effects**: no on-chain state. The TEE machine now knows where to fetch actions, which address to register under, and which extension to join. [MachineRegistration](../../Workflows/MachineRegistration.md) can proceed.

### transferOwnership: any → OwnerTransferred (optional, repeatable)

- **Action**: two-step, first `FlareTeeManager.proposeNewOwner(extensionId, newOwner)` then `confirmOwnership(extensionId)` from `newOwner`.
- **Caller**: current owner (propose), proposed owner (confirm).
- **Guards**: the proposed owner must be on the extension owner allowlist (or `address(0)` to cancel); the confirming address must also be on the allowlist.
- **Effects**: extension `owner` becomes `newOwner`. Emits [`NewOwnerProposed`](../../Reference/Contracts/FlareTeeManagerEvents.md#newownerproposed) and [`NewOwnerConfirmed`](../../Reference/Contracts/FlareTeeManagerEvents.md#newownerconfirmed). Production deployments typically transfer to a multisig governance address.

## Invariants

- An extension's `extensionId` is fixed at registration; only `owner`, `stateVerifier`, `instructionsSender`, allowlists, code versions, and supported key types may change.
- `instructionsSender` is never `address(0)` after `register`.
- The `(codeHash, platform)` pairs accepted by `addTeeVersion` are a subset of the system-supported set; changes to the system list do not retroactively invalidate already registered pairs.
- The state machine is monotonic until `transferOwnership`: progress from `Unregistered` only moves forward.

## Terminal States

`Provisioned`. The extension is ready for [MachineRegistration](../../Workflows/MachineRegistration.md), and once at least one machine reaches `PRODUCTION` the extension can receive [custom instructions](Instructions.md).

## Notes

- After [`register`](#register-unregistered--registered), the deployed `instructionsSender` contract must learn its own `extensionId` (typically via a `setExtensionId` call) before it can forward user calls to `FlareTeeManager.sendInstructions`.
- All TEE machine configuration endpoints can be supplied via environment variables (`PROXY_URL`, `INITIAL_OWNER`, `EXTENSION_ID`, `CHAIN_ID`, `GOVERNANCE`) at boot instead of via the Configuration API.
- The same allowlist and key type calls are also used by the [system extension](../System.md) via its governance entry points.