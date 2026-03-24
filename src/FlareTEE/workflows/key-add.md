# Add Key to TEE Machine

## Overview

This workflow covers adding a new signing key to a TEE machine for an existing wallet.
For key data structures, see [Key Management](../TEE%20Management/Key%20Management.md).

## Prerequisites

- Wallet must be in `INITIALIZED` or `PRODUCTION` status.
- The target TEE machine must be in `PRODUCTION` status.
- The TEE machine's extension ID must match the wallet's project extension ID.
- The project must have a supported key type and signing algorithm configured on the extension.

---

## Steps

### Step 1: Add Key — `TeeWalletKeyManager.addKey()`

**Who can call:** Project owner (wallet owner).

**Parameters:**
- `teeId` (`address`) — the TEE machine on which to generate the key.
- `walletId` (`bytes32`) — the wallet ID.
- `claimBackAddress` (`address`) — address to claim back unused instruction fees.

**Requirements:**
- The TEE machine must be in `PRODUCTION` status.
- The TEE machine's extension ID must match the wallet's project extension ID.

**What happens:**
1. The contract generates a new `keyId` by incrementing the wallet's key counter.
2. A `KEY_GENERATE` instruction is sent to the specified TEE machine, parameterized as `KEY_GENERATE(teeId, walletId, keyId, opType, opTypeConstants, adminsPublicKeys, adminsThreshold, cosigners, cosignersThreshold)`.
3. The instruction includes the wallet configuration (admins, cosigners), key type, and signing algorithm from the project.
4. The TEE machine generates a new key pair inside the enclave and associates it with the wallet.
5. The TEE machine automatically triggers a [key backup](key-restore.md#automatic-key-backup) for the newly generated key.

**Events emitted:** `WalletKeyAdded(teeId, walletId, keyId)`, `TeeInstructionsSent`

> **Note:** This step can be repeated to add keys on different TEE machines. Each invocation generates a unique `keyId`.

---

### Step 2: Confirm Key — `TeeWalletKeyManager.confirmKey()`

**Who can call:** Project owner or backup manager.

**Parameters:**
- `proof` (`KeyExistence`) — a `TeeKeyExistence` proof from the TEE machine containing:
  - `teeId` (`address`) — the TEE machine that generated the key.
  - `walletId` (`bytes32`) — the wallet ID.
  - `keyId` (`uint64`) — the key ID from `addKey`.
  - `nonce` (`uint256`) — key nonce ($0$ for new keys).
  - `publicKey` (`bytes`) — the generated public key.
  - `keyType` (`bytes32`) — must match the project's key type.
  - `signingAlgo` (`bytes32`) — must match the project's signing algorithm.
  - `configConstants` (`KeyConfigConstants`) — wallet config with `adminsPublicKeys`, `adminsThreshold`, `cosigners`, `cosignersThreshold` (must match wallet).
  - `restored` (`bool`) — `false` for new keys.
  - `settingsVersion` (`bytes32`) — settings version hash.
  - `settings` (`bytes`) — settings data.
- `teeSignature` (`Signature`) — signature from the TEE machine over the proof.

**Requirements:**
- The TEE machine must be in `PRODUCTION` status.
- The key ID must exist (created by `addKey` in Step 1).
- For new keys: `nonce == 0` and `restored == false`.
- Key type, signing algorithm, and `configConstants` must match the project and wallet configuration.
- The TEE signature must be valid.

**What happens:**
1. The contract verifies the proof and TEE signature.
2. Stores the public key on-chain.
3. Adds the `teeId` to the key's TEE list, indicating the key exists on this machine.

**Events emitted:** `WalletKeyConfirmed`

---

## Notes

- To remove keys from TEE machines, see the [key delete workflow](key-delete.md). To restore keys from backup onto a new TEE, see the [key restore workflow](key-restore.md).
- For key definitions and project configuration details, see [Projects and Ownership](../Operations/Projects%20and%20Ownership.md).
