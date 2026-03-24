# Extension Configuration

## Overview

This workflow covers registering and configuring a custom TEE extension, from deploying the instruction sender contract through to configuring the TEE node.
For background on the extension framework, see [Extensions](../Extensions/Extensions.md).

## Prerequisites

- Deployed Flare TEE system contracts (`TeeExtensionRegistry`, `TeeOwnerAllowlist`, `TeeMachineRegistry`, `TeeWalletProjectManager`, `TeeWalletManager`, `TeeWalletKeyManager`)
- A funded Ethereum account to submit transactions
- A TEE node running inside a Confidential VM (or in local dev mode with `MODE=1`)
- Access to the TEE node's Configuration API on port $5500$
- A TEE proxy server deployed and running
- A reproducible Docker image hash for the extension code

---

## Steps

### Step 1: Deploy Instruction Sender Contract

**Who can call:** Any address

**Parameters:**
- `_teeExtensionRegistry` (`ITeeExtensionRegistry`): Address of the `TeeExtensionRegistry` contract
- `_teeWalletProjectManager` (`ITeeWalletProjectManager`): Address of the `TeeWalletProjectManager` contract
- `_teeWalletManager` (`ITeeWalletManager`): Address of the `TeeWalletManager` contract
- `_teeWalletKeyManager` (`ITeeWalletKeyManager`): Address of the `TeeWalletKeyManager` contract
- `_teeMachineRegistry` (`ITeeMachineRegistry`): Address of the `TeeMachineRegistry` contract

**Requirements:**
- All referenced system contract addresses must be valid and deployed on the target network

**What happens:**
1. A new instruction sender contract is deployed on-chain. This contract is responsible for encoding and sending instructions to the TEE extension via `TeeExtensionRegistry.sendInstructions()`.
2. The deployed contract address will be used as the `_teeExtensionInstructionsSender` parameter when registering the extension in the next step.
3. The instruction sender contract inherits from a `Base` contract that holds references to all required system contracts, and implements domain-specific instruction methods (e.g., `signTransaction()`, `generateRandomUint64()`).

**Events emitted:** None (contract deployment).

> **Note:** The instruction sender contract must call `setExtensionId()` after the extension is registered (Step 2) to discover and store its own extension ID. This is required before any instructions can be sent.

---

### Step 2: Register Extension -- `TeeExtensionRegistry.register()`

**Who can call:** Any address (the caller becomes the extension owner)

**Parameters:**
- `_teeExtensionStateVerifier` (`address`): Address of a state verifier contract for the extension. Can be `address(0)` initially if no state verification is needed.
- `_teeExtensionInstructionsSender` (`address`): Address of the instruction sender contract deployed in Step 1. Must be non-zero.

**Requirements:**
- The `_teeExtensionInstructionsSender` address must be non-zero
- Extension ID 0 is reserved for the system extension and cannot be registered by users

**What happens:**
1. A new `extensionId` is assigned by incrementing the internal `extensionsCounter`.
2. `msg.sender` is set as the extension owner.
3. The state verifier and instructions sender addresses are stored for the extension.
4. The extension is now registered but has no TEE machines, code versions, or key types associated with it yet.

**Events emitted:**
- `TeeExtensionRegistered(extensionId, owner)` -- confirms the extension was created with its assigned ID
- `TeeExtensionContractsSet(extensionId, teeExtensionStateVerifier, teeExtensionInstructionsSender)` -- records the contract addresses

> **Note:** After registration, call `setExtensionId()` on the instruction sender contract so it can discover its extension ID from the registry.

---

### Step 3: Add TEE Code Version -- `TeeExtensionRegistry.addTeeVersion()`

**Who can call:** Extension owner only

**Parameters:**
- `_extensionId` (`uint256`): The extension ID returned from Step 2
- `_version` (`string`): Version string (e.g., `"v0.1.0"`)
- `_codeHash` (`bytes32`): Hash of the TEE extension Docker image. This must be reproducible and will be verified during machine attestation.
- `_platforms` (`bytes32[]`): Array of supported TEE platforms (e.g., `GOOGLE_INTEL`, `GOOGLE_AMD`). Each platform must already be registered as a system-supported platform.
- `_governanceHash` (`bytes32`): Optional governance hash. Can be `bytes32(0)` if not applicable. If provided, it must match the latest governance hash.

**Requirements:**
- Caller must be the extension owner
- All platforms in `_platforms` must be in the system-supported platforms list (added by governance via `addSystemSupportedPlatforms`)
- If `_governanceHash` is non-zero, it must match the latest governance hash

**What happens:**
1. The code hash is mapped to the provided version info.
2. Each platform in `_platforms` is associated with this code hash for the extension.
3. TEE machines can now register with this code hash and platform combination.

**Events emitted:**
- `TeeVersionAdded(extensionId, version, codeHash, platforms, governanceHash)`

---

### Step 4: Configure Owner Allowlists -- `TeeOwnerAllowlist`

This step configures which addresses are permitted to register TEE machines and create wallet projects for this extension. Two separate allowlists must be configured.

### Step 4a: Machine Owner Allowlist -- `addAllowedTeeMachineOwners()` or `allowAllTeeMachineOwners()`

**Who can call:** Extension owner only

**Parameters (specific allowlist):**
- `_extensionId` (`uint256`): The extension ID
- `_owners` (`address[]`): Array of addresses to allow as TEE machine owners

**Parameters (allow all):**
- `_extensionId` (`uint256`): The extension ID

**What happens:**
1. The specified addresses are added to the machine owner allowlist for this extension.
2. Alternatively, `allowAllTeeMachineOwners()` opens registration to any address.
3. Only allowlisted addresses can register TEE machines for this extension via `TeeMachineRegistry.register()`.

**Events emitted:**
- `AllowedTeeMachineOwnersAdded(extensionId, owners)` -- when specific owners are added

### Step 4b: Project Owner Allowlist -- `addAllowedTeeWalletProjectOwners()` or `allowAllTeeWalletProjectOwners()`

**Who can call:** Extension owner only

**Parameters (specific allowlist):**
- `_extensionId` (`uint256`): The extension ID
- `_owners` (`address[]`): Array of addresses to allow as wallet project owners

**Parameters (allow all):**
- `_extensionId` (`uint256`): The extension ID

**What happens:**
1. The specified addresses are added to the wallet project owner allowlist for this extension.
2. Alternatively, `allowAllTeeWalletProjectOwners()` opens project creation to any address.
3. Only allowlisted addresses can create wallet projects for this extension via `TeeWalletProjectManager.createProject()`.

**Events emitted:**
- `AllowedTeeWalletProjectOwnersAdded(extensionId, owners)` -- when specific owners are added

---

### Step 5: Add Supported Key Types -- `TeeExtensionRegistry.addSupportedKeyTypes()`

**Who can call:** Extension owner only

**Parameters:**
- `_extensionId` (`uint256`): The extension ID
- `_keyTypes` (`bytes32[]`): Array of key type identifiers to support. Common values include:
  - `"EVM"` -- for Keccak256-Secp256k1 ECDSA signing (used with EVM transactions)
  - `"XRP"` -- for SHA512Half-Secp256k1 ECDSA signing (used with XRP transactions)

**Requirements:**
- Caller must be the extension owner
- Each key type in `_keyTypes` must be system-supported (added by governance via `addSystemSupportedKeyTypesAndSigningAlgos`)

**What happens:**
1. The specified key types are registered as supported for this extension.
2. Wallet projects created under this extension can use these key types.
3. The associated signing algorithms are determined by the system-level key type registration.

**Events emitted:**
- `SupportedKeyTypesAdded(extensionId, keyTypes)`

---

### Step 6: Configure TEE Node -- Config API

Before the TEE machine can be registered on-chain, it must be configured with the proxy URL, initial owner, and extension ID via the TEE Configuration API (not yet published) on port 5500. These are the same three endpoints used in [machine-registration.md](machine-registration.md) Steps 2–4, which documents the full Config API details including curl examples and requirements.

**Who can call:** TEE machine owner (network access to port 5500 required)

**Endpoints:**
- `POST /proxy` -- set the TEE proxy URL (e.g., `http://<TEE_PROXY_INTERNAL_IP>:6661`)
- `POST /initial-owner` -- set the initial owner address (immutable once set)
- `POST /extension-id` -- set the extension ID (fixed after `TeeAvailabilityCheck` verification)

**Events emitted:** None (off-chain configuration)

> **Note:** All three configuration endpoints can alternatively be set via environment variables (`PROXY_URL`, `INITIAL_OWNER`, `EXTENSION_ID`) before the TEE node starts. The API endpoints allow runtime configuration after boot, which is the typical workflow when the TEE machine is already running inside a confidential VM.

---

### Step 7: Extension Ownership Transfer (Optional) -- `proposeNewOwner()` / `confirmOwnership()`

**Who can call:** Current extension owner (for proposal), proposed new owner (for confirmation)

**Parameters (propose):**
- `_extensionId` (`uint256`): The extension ID
- `_newOwner` (`address`): The proposed new owner address

**Parameters (confirm):**
- `_extensionId` (`uint256`): The extension ID

**Requirements:**
- `proposeNewOwner()` must be called by the current extension owner
- `confirmOwnership()` must be called from the proposed new owner address

**What happens:**
1. The current owner calls `proposeNewOwner(extensionId, newOwnerAddress)` to propose a new owner.
2. The proposed new owner calls `confirmOwnership(extensionId)` to accept the transfer.
3. Ownership of the extension is transferred to the new address.
4. The extension owner is typically a multisig governance account for production deployments.

**Events emitted:** `NewOwnerProposed(extensionId, oldOwner, newOwner)` and `NewOwnerConfirmed(extensionId, newOwner)`

---

## Notes

- After completing extension configuration, proceed to [Machine Registration](machine-registration.md) to register TEE machines, then [Wallet Setup](wallet-setup.md) to create wallet projects and keys, and finally [Extension Instructions](extension-instructions.md) to send custom instructions.
- The extension owner is typically a multisig governance account for production deployments.
- All three TEE node configuration endpoints (Step 6) can alternatively be set via environment variables (`PROXY_URL`, `INITIAL_OWNER`, `EXTENSION_ID`) before the TEE node starts.

