# Add Key to TEE Machine

## Overview

This workflow covers adding a new signing key to a TEE machine for an existing wallet.
For canonical key semantics and data structures, see [Key Management](../TeeManagement/Keys.md) and [Wallets](../TeeManagement/Wallets.md).

## Prerequisites

- Wallet must be in `INITIALIZED` status.
- The target TEE machine must be in `PRODUCTION` status.
- The TEE machine's extension ID must match the wallet's project extension ID.

---

## Steps

### Step 1: Add Key — `FlareTeeManager.addKey()`

**Who can call:** [Project owner](../../Terminology/Roles.md#project-owner) only.

**Parameters:**
- `teeId` (`address`) — the TEE machine on which to generate the key.
- `walletId` (`bytes32`) — the wallet ID.
- `claimBackAddress` (`address`) — address to claim back unused instruction fees.

**Requirements:**
- Wallet must be in `INITIALIZED` status.
- The TEE machine must be in `PRODUCTION` status.
- The TEE machine's extension ID must match the wallet's project extension ID.
- The function is `payable` — sufficient value must be included to cover the instruction fee.

**What happens:**
1. The contract generates a new `keyId` by incrementing the wallet's key counter.
2. A [`KEY_GENERATE`](../Operations/System/F_WALLET.md#key_generate) instruction is sent to the specified TEE machine.
3. The TEE machine generates a new key pair inside the enclave and associates it with the wallet.
4. The TEE machine automatically triggers a key backup for the newly generated key.

**Events emitted:** [`WalletKeyAdded`](../Types/Abi/Events/TeeWalletKeyManager.md#walletkeyadded), [`TeeInstructionsSent`](../Types/Abi/Events/TeeExtensionRegistry.md#teeinstructionssent)

> **Note:** This step can be repeated to add keys on different TEE machines. Each invocation generates a unique `keyId`.

---

### Step 2: Confirm Key — `FlareTeeManager.confirmKey()`

**Who can call:** Project owner only (for new keys).

**Parameters:**
- `proof` (`KeyExistence`) — a key existence proof from the TEE machine.
- `teeSignature` (`Signature`) — signature from the TEE machine over the proof.

**Requirements:**
- Wallet must be in `INITIALIZED` status.
- The TEE machine must be in `PRODUCTION` status.
- The key ID must exist (created by `addKey` in Step 1).
- The proof must be consistent with the on-chain wallet and project configuration.
- The TEE signature must be valid.

**What happens:**
1. The contract verifies the proof and TEE signature.
2. Stores the public key on-chain.
3. Adds the `teeId` to the key's TEE list, indicating the key exists on this machine.

**Events emitted:** [`WalletKeyConfirmed`](../Types/Abi/Events/TeeWalletKeyManager.md#walletkeyconfirmed)

---

## Notes

- To remove keys from TEE machines, see the [key delete workflow](KeyDelete.md). To restore keys from backup onto a new TEE, see the [key restore workflow](KeyRestore.md).
- For key definitions and project configuration details, see [Wallets](../TeeManagement/Wallets.md).
