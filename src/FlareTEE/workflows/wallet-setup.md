# Project and Wallet Lifecycle — From Creation to PRODUCTION

## Overview

This workflow describes the complete process of creating a project, configuring a wallet within that project, generating keys on TEE machines, and enabling the wallet for production use. The process follows a strict sequence: project creation, wallet creation, admin/cosigner configuration, initialization closure, key generation and confirmation, and finally wallet enablement.

## Prerequisites

- **TEE machine(s) in PRODUCTION status** — at least one TEE machine must be registered and operational on the target extension (see [machine-registration.md](machine-registration.md))
- **Extension registered** with supported key types and signing algorithms (see [extension-configuration.md](extension-configuration.md))
- **Funded owner account** — the Flare address that will own the project must have sufficient funds for transaction fees
- **Admin key pairs** — ECDSA key pairs for each admin that will be configured on the wallet
- **(Optional) Cosigner accounts** — Flare addresses for any cosigners

---

## Steps

### Step 1: Create Project — `TeeWalletProjectManager.createProject()`

**Who can call:** Must be allowlisted as a wallet project owner for the extension. If default extension 0, anyone can call.

**Parameters:**
- `extensionId` (uint256) — the TEE extension ID
- `keyType` (bytes32) — key type for all wallets in the project (e.g., "EVM", "XRP")
- `signingAlgo` (bytes32) — signing algorithm for the key type
- `authorizationAddress` (address) — address authorized to submit payment instructions for wallets on the project

**Requirements:**
- Caller must be allowlisted for the extension (or extension 0)

**What happens:**

1. A new project is created with a unique `projectId`.
2. The caller (`msg.sender`) is set as the project owner.
3. The `extensionId`, `keyType`, and `signingAlgo` are stored and are **immutable** after creation.
4. The `authorizationAddress` is stored as the submit address for payment instruction transactions.

**Events emitted:** Project created event

> **Optional:** After creation, the project owner can set a backup manager via `setBackupManager(projectId, address)` and a default wallet via `setDefaultWallet(projectId, walletId)`.

---

### Step 2: Create Wallet — `TeeWalletManager.createWallet()`

**Who can call:** Project owner only

**Parameters:**
- `projectId` (bytes32) — the project ID returned from Step 1

**Requirements:**
- Caller must be the project owner

**What happens:**

1. Generates a unique `walletId` (hash of "WALLET", owner address, and counter).
2. Sets the wallet status to `CREATED`.
3. Links the wallet to the specified project.

`Status: --> CREATED`

**Events emitted:** `WalletCreated`

---

### Step 3: Set Admins — `TeeWalletManager.setAdmins()`

**Who can call:** Project owner (wallet owner)

**Parameters:**
- `walletId` (bytes32) — the wallet ID
- `adminsPublicKeys` (PublicKey[]) — array of admin public keys, each with `{x: bytes32, y: bytes32}`
- `adminsThreshold` (uint256) — number of admin signatures required (k-of-n)

**Requirements:**
- Wallet must be in `CREATED` status
- `adminsPublicKeys.length >= adminsThreshold`
- `adminsThreshold > 0`
- All public keys must be valid
- No duplicate public keys

**What happens:**

1. Replaces any existing admin configuration.
2. Stores the admin public keys and threshold.
3. Admins are used for encrypting Shamir secret shares for key backups and for multisig confirmation of configuration changes (e.g., halting and resuming signings).

> **Note:** Can be called multiple times while in `CREATED` status. Each call replaces the previous admin set.

**Events emitted:** `WalletAdminsSet`

---

### Step 4: Confirm Admins — `TeeWalletManager.confirmAdmin()`

**Who can call:** Each admin (must match one of the admin public keys set in Step 3)

**Parameters:**
- `walletId` (bytes32) — the wallet ID

**Requirements:**
- Wallet must be in `CREATED` status
- Caller must correspond to one of the admin public keys

**What happens:**

1. The admin confirms their participation by sending a transaction from the address corresponding to their public key.
2. The admin is marked as confirmed for this wallet.

> **Note:** All admins must confirm before wallet initialization can be closed (Step 7).

**Events emitted:** `WalletAdminConfirmed`

---

### Step 5: Set Cosigners (Optional) — `TeeWalletManager.setCosigners()`

**Who can call:** Project owner (wallet owner)

**Parameters:**
- `walletId` (bytes32) — the wallet ID
- `cosigners` (address[]) — array of cosigner addresses
- `cosignersThreshold` (uint256) — number of cosigner signatures required

**Requirements:**
- Wallet must be in `CREATED` status
- If cosigners are provided: `cosigners.length >= cosignersThreshold` and `cosignersThreshold > 0`
- If no cosigners desired: `cosigners.length == 0` and `cosignersThreshold == 0`
- No duplicate addresses
- No zero addresses

**What happens:**

1. Stores the cosigner addresses and threshold.
2. Cosigners determine the (n, k) threshold signature requirements — k of n cosigner addresses must sign a payment instruction before a TEE machine executes it.

> **Note:** Can be updated while in `CREATED` status, but once initialization is closed (Step 7), cosigners become **immutable**. The TEE machines store cosigner information as metadata alongside wallet keys to enforce cosigning requirements.

**Events emitted:** `WalletCosignersSet`

---

### Step 6: Confirm Cosigners — `TeeWalletManager.confirmCosigner()`

**Who can call:** Each cosigner (must match one of the cosigner addresses set in Step 5)

**Parameters:**
- `walletId` (bytes32) — the wallet ID

**Requirements:**
- Wallet must be in `CREATED` status
- Caller must be one of the cosigner addresses

**What happens:**

1. The cosigner confirms their participation by sending a transaction from their address.
2. The cosigner is marked as confirmed for this wallet.

> **Note:** All cosigners must confirm before wallet initialization can be closed (Step 7).

**Events emitted:** `WalletCosignerConfirmed`

---

### Step 7: Close Initialization — `TeeWalletManager.closeWalletInitialization()`

**Who can call:** Project owner (wallet owner)

**Parameters:**
- `walletId` (bytes32) — the wallet ID

**Requirements:**
- Wallet must be in `CREATED` status
- At least one admin must be set
- All admins must have confirmed (Step 4)
- All cosigners must have confirmed (Step 6), if any were set

**What happens:**

1. The wallet status changes from `CREATED` to `INITIALIZED`.
2. Admin and cosigner configuration is **locked** — it cannot be changed after this point.
3. The wallet can now proceed to key configuration.

`Status: CREATED --> INITIALIZED`

**Events emitted:** `WalletInitialized`

---

### Step 8: Set Multisig Threshold — `TeeWalletKeyManager.setMultisigThreshold()`

**Who can call:** Project owner (wallet owner)

**Parameters:**
- `walletId` (bytes32) — the wallet ID
- `multisigThreshold` (uint256) — number of keys required for multisig operations

**Requirements:**
- Wallet must be in `INITIALIZED` status
- `multisigThreshold > 0`

**What happens:**

1. Sets the multisig threshold k for the wallet, defining how many key signatures are required to authorize a transaction on the external chain.
2. This determines the k parameter in the (k, n) multisig configuration.

> **Note:** Can be updated while in `INITIALIZED` status (before enabling the wallet).

**Events emitted:** `WalletMultisigThresholdSet`

---

### Step 9: Add Key(s) — `TeeWalletKeyManager.addKey()`

**Who can call:** Project owner (wallet owner)

**Parameters:**
- `teeId` (address) — the TEE machine on which to generate the key
- `walletId` (bytes32) — the wallet ID

**Requirements:**
- Wallet must be in `INITIALIZED` status
- The TEE machine must be in `PRODUCTION` status
- The TEE machine's extension ID must match the wallet's project extension ID

**What happens:**

1. Generates a new `keyId` by incrementing the wallet's key counter.
2. Sends a `KEY_GENERATE` instruction to the specified TEE machine.
3. The instruction includes the wallet configuration (admins, cosigners), key type, and signing algorithm from the project.
4. The TEE machine generates a new key pair inside the enclave and associates it with the wallet.
5. This step can be repeated multiple times to add keys on different TEE machines (each gets a unique `keyId`).

**Events emitted:** `WalletKeyAdded`, `TeeInstructionsSent`

---

### Step 10: Confirm Key — `TeeWalletKeyManager.confirmKey()`

**Who can call:** Project owner or backup manager

**Parameters:**
- `proof` (struct `KeyExistence`) — key existence proof from the TEE machine containing:
  - `teeId` (address) — the TEE machine that generated the key
  - `walletId` (bytes32) — the wallet ID
  - `keyId` (uint64) — the key ID from `addKey`
  - `nonce` (uint256) — key nonce (0 for new keys)
  - `publicKey` (bytes) — the generated public key
  - `keyType` (bytes32) — must match project's key type
  - `signingAlgo` (bytes32) — must match project's signing algorithm
  - `configConstants` (struct) — wallet config with `adminsPublicKeys`, `adminsThreshold`, `cosigners`, `cosignersThreshold` (must match wallet)
  - `restored` (bool) — `false` for new keys, `true` for restored keys
  - `settingsVersion` (bytes32) — settings version hash
  - `settings` (bytes) — settings data
- `teeSignature` (Signature: `{v: uint8, r: bytes32, s: bytes32}`) — signature from the TEE machine over the proof

**Requirements:**
- Wallet must be in `INITIALIZED` status (for new keys)
- TEE machine must be in `PRODUCTION` status
- Key ID must exist (created by `addKey` in Step 9)
- Nonce must match expected value
- Key type and signing algorithm must match project configuration
- Config constants (admins, cosigners) must match the wallet's locked configuration
- TEE signature must be valid
- For new keys: `nonce == 0` and `restored == false`
- For restored keys: `nonce > 0` and `restored == true`

**What happens:**

1. **First confirmation (new key):**
   - Stores the public key on-chain.
   - Adds the `keyId` to the wallet's key list.
   - Adds the `teeId` to the key's TEE list.
2. **Subsequent confirmations (restore on another TEE):**
   - Verifies the public key matches the previously stored value.
   - Adds the `teeId` to the existing key's TEE list.

**Events emitted:** `WalletKeyConfirmed`

---

### Step 11: Enable Wallet — `TeeWalletManager.enableWallet()`

**Who can call:** Project owner (wallet owner)

**Parameters:**
- `walletId` (bytes32) — the wallet ID

**Requirements:**
- Wallet must be in `INITIALIZED` or `PAUSED` status
- Multisig threshold must be set (Step 8)
- Number of confirmed keys >= multisig threshold

**What happens:**

1. The wallet status changes to `PRODUCTION`.
2. The wallet is now fully operational and can accept payment instructions.

`Status: INITIALIZED --> PRODUCTION` (or `PAUSED --> PRODUCTION`)

**Events emitted:** `WalletEnabled`

---

## Notes

- **Architecture overview:** For the architectural overview of projects, wallets, and key data structures, see the [Projects and Ownership specification](../Operations/Projects%20and%20Ownership.md).
- **Project ownership transfer — `proposeNewOwner()` + `confirmOwnership()`:** Project ownership transfer is a two-step process to ensure security and proper authorization.
  - *Step A — Propose new owner via `TeeWalletProjectManager.proposeNewOwner()`:* Current project owner calls with `projectId` and `newOwner` address (can be `address(0)` to cancel). If `newOwner` is not `address(0)`, the new owner must be allowlisted. Stores the proposed new owner address but does not transfer ownership yet. Emits `NewOwnerProposed`.
  - *Step B — Confirm ownership via `TeeWalletProjectManager.confirmOwnership()`:* Proposed new owner calls with `projectId`. Caller must be allowlisted. Transfers project ownership, clears the proposal. Emits `OwnershipConfirmed`.
- **Wallet pausing — `pauseWallet()` and `enableWallet()`:** `TeeWalletManager.pauseWallet(walletId)` can be called by the project owner or pausing addresses. Changes wallet status to `PAUSED` and indicates that existing payment instructions should be reverted. To resume, call `enableWallet(walletId)` as described in Step 11 (transitions from `PAUSED` back to `PRODUCTION`).
- **Setting default wallet — `TeeWalletProjectManager.setDefaultWallet()`:** Project owner calls with `projectId` and `walletId` to set the default wallet for the project, which will be used for all signings (payments).
- **Setting backup manager — `TeeWalletProjectManager.setBackupManager()`:** Project owner calls with `projectId` and backup manager `address`. Sets the backup manager address that can trigger key restores for backed-up keys.
- **Key deletion — `TeeWalletKeyManager.deleteKey()`:** Project owner can call at any wallet status (but the TEE must be in `PRODUCTION`). Removes the `teeId` from the key's TEE list and sends a `KEY_DELETE` instruction to the TEE machine. Does not remove the key entirely, only removes it from a specific TEE. Emits `WalletKeyDeleted`.
- **Setting pausing addresses — `TeeWalletManager.setPausingAddresses()`:** Project owner calls with `walletId` and an array of `pausingAddresses`. Issues a `SET_PAUSING_ADDRESSES` instruction to all active TEE machines with keys belonging to the wallet.

