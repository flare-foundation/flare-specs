# Delete Key from TEE Machine

## Overview

This workflow covers deleting a signing key from a TEE machine and cleaning up stale TEE associations. Deleting a key removes the private key material from the specified TEE but does not remove the key definition from the wallet — the key can still be [restored from backup](key-restore.md) or may continue to exist on other TEE machines.

For full details on key data structures, see the [Key Management specification](../TEE%20Management/Key%20Management.md).

## Prerequisites

- Wallet must be in `PRODUCTION` status.
- The TEE machine holding the key must be in `PRODUCTION` status.
- The key must exist on the specified TEE machine (i.e., the `teeId` must be in the key's TEE list).

---

## Step 1: Delete Key — `TeeWalletKeyManager.deleteKey()`

**Who can call:** Project owner or wallet admin.

**Parameters:**
- `teeId` (`address`) — the identity address of the TEE machine from which the key should be deleted.
- `walletId` (`bytes32`) — the wallet ID containing the key.
- `keyId` (`uint64`) — the key ID to delete from the specified TEE.

**Requirements:**
- The TEE machine identified by `teeId` must be in `PRODUCTION` status.
- The key must exist on the specified TEE (i.e., `teeId` must be in the key's TEE list).

**What happens:**
1. The contract sends a `KEY_DELETE` instruction to the specified TEE machine, parameterized as `KEY_DELETE(teeId, walletId, keyId)`.
2. The TEE machine verifies the `nonce` in the instruction is strictly greater than the current nonce stored for that key.
3. The TEE machine removes the private key material from its memory.
4. The `teeId` is removed from the key's TEE list on-chain.
5. The key definition itself remains on the wallet — only the association with the specific TEE is removed. The key may still exist on other TEE machines.
6. On the TEE machine, the wallet key variables (`nonce`, `pauseNonce`, `status`, `expiry`) for that key are *retained* even after deletion, preventing nonce reuse if the key is later restored.

**Events emitted:** `WalletKeyDeleted`

> **Note:** Deleting a key from all TEEs does not remove the key definition from the wallet. The key can be restored via the [key restore workflow](key-restore.md).

---

## Step 2: Clean Up Stale TEE IDs — `TeeWalletKeyManager.cleanUpTeeIds()`

After deleting keys or decommissioning TEE machines, stale TEE IDs may remain in a key's TEE list. This step removes them.

**Who can call:** Project owner or wallet admin.

**Parameters:**
- `walletId` (`bytes32`) — the wallet ID.
- `keyId` (`uint64`) — the key ID whose TEE list should be cleaned.

**Requirements:**
- The key must exist on the wallet.
- There must be stale TEE IDs in the key's TEE list (TEEs that no longer hold the key or have been decommissioned).

**What happens:**
1. The contract iterates through the TEE IDs associated with the specified key.
2. TEE IDs corresponding to machines that no longer hold the key are removed from the key definition's TEE list.
3. This is typically used after a TEE machine has been decommissioned or retired from the network.

**Events emitted:** None specified in the contract interface.

---

## Cross-References

- [key-add.md](key-add.md) — adding new keys to TEE machines.
- [key-restore.md](key-restore.md) — restoring deleted keys from backup.
- [machine-lifecycle.md](machine-lifecycle.md) — TEE machine decommissioning and status changes.
- [Key Management specification](../TEE%20Management/Key%20Management.md) — key data structures and wallet key variables.
