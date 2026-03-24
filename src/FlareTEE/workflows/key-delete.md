# Delete Key from TEE Machine

## Overview

This workflow covers deleting a signing key from a TEE machine.
Deletion removes private key material from the specified TEE but retains the key definition on the wallet.

## Prerequisites

- The TEE machine holding the key must be in `PRODUCTION` status.
- The key must have been confirmed (public key must exist on-chain).
- The TEE machine's extension ID must match the wallet's project extension ID.

---

## Steps

### Step 1: Delete Key — `TeeWalletKeyManager.deleteKey()`

**Who can call:** Project owner only.

**Parameters:**
- `teeId` (`address`) — the identity address of the TEE machine from which the key should be deleted.
- `walletId` (`bytes32`) — the wallet ID containing the key.
- `keyId` (`uint64`) — the key ID to delete from the specified TEE.
- `claimBackAddress` (`address`) — address to claim back unused instruction fees.

**Requirements:**
- The TEE machine must be in `PRODUCTION` status.
- The key must have been confirmed (public key must exist on-chain).
- The TEE machine's extension ID must match the wallet's project extension ID.

**What happens:**
1. The contract sends a [`KEY_DELETE`](../commands/F_WALLET--KEY_DELETE.md) instruction to the specified TEE machine.
2. The TEE machine verifies the `nonce` in the instruction is strictly greater than the current nonce stored for that key.
3. The TEE machine removes the private key material from its memory.
4. The `teeId` is removed from the key's TEE list on-chain.
5. The key definition itself remains on the wallet — only the association with the specific TEE is removed.
6. On the TEE machine, the wallet key variables (`nonce`, `pauseNonce`, `status`, `expiry`) for that key are *retained* even after deletion, preventing nonce reuse if the key is later restored.

**Events emitted:** [`WalletKeyDeleted`](../Events.md#walletkeydeleted), [`TeeInstructionsSent`](../Events.md#teeinstructionssent)

> **Note:** Deleting a key from all TEEs does not remove the key definition from the wallet. The key can be restored via the [key restore workflow](key-restore.md).

---

### Step 2: Clean Up Stale TEE IDs — `TeeWalletKeyManager.cleanUpTeeIds()`

After deleting keys or decommissioning TEE machines, stale TEE IDs may remain in a key's TEE list.
This step removes them.

**Who can call:** Project owner or backup manager.

**Parameters:**
- `walletId` (`bytes32`) — the wallet ID.
- `keyId` (`uint64`) — the key ID whose TEE list should be cleaned.

**Requirements:**
- The key must exist on the wallet (public key must be non-empty).

**What happens:**
1. The contract iterates through the TEE IDs associated with the specified key.
2. TEE IDs corresponding to machines that no longer hold the key are removed from the key definition's TEE list.

**Events emitted:** [`WalletKeyDeleted`](../Events.md#walletkeydeleted) for each removed stale TEE ID.

---

## Notes

- The `deleteKey` function does not check wallet status — it can be called regardless of whether the wallet is in `CREATED`, `INITIALIZED`, `PRODUCTION`, or `PAUSED` status.
- For adding new keys to TEE machines, see the [key add workflow](key-add.md). For TEE machine decommissioning and status changes, see [machine lifecycle](machine-lifecycle.md).
- On the TEE machine, wallet key variables (`nonce`, `pauseNonce`, `status`, `expiry`) are retained even after deletion, preventing nonce reuse if the key is later [restored from backup](key-restore.md).
