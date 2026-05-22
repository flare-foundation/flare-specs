# KeyDelete

State machine for removing one wallet key from one TEE machine.
The on-chain key definition (admins, multisig threshold) survives; only the binding to the specified TEE machine is severed, and the key material inside that machine is wiped.

## Preconditions

- The `(walletId, keyId)` is in [`Confirmed`](KeyAdd.md#terminal-states) state — i.e. has a `publicKey` on chain and the target `teeId` appears in the key's `teeIds` list.
- The target TEE machine is in `PRODUCTION` and is registered to the wallet's project's `extensionId`.
- The [project owner](../../Terminology/Roles.md#project-owner) (or, for the cleanup transition, the project's `backupManager`) holds the caller address.

## States

- `OnTee` — the key material is present on `teeId`; `teeId ∈ key.teeIds` on chain.
- `Deleted` — the TEE has been instructed to wipe the material; `teeId` no longer appears in `key.teeIds`.
- `Stale` — a transient on-chain state where the key's `teeIds` list still contains TEE machines that are no longer in `PRODUCTION`. Cleaning is optional.

## Initial State

`OnTee`.

## Transitions

### deleteKey: OnTee → Deleted

- **Action**: [`FlareTeeManager.deleteKey(walletId, keyId, teeId, claimBackAddress)`](../Reference/Contracts/FlareTeeManager.md#key-custody) — payable.
- **Caller**: project owner.
- **Guards**:
  - `key.publicKey ≠ 0` (the key has been confirmed)
  - `teeMachine.status = PRODUCTION`
  - `teeMachine.extensionId = project.extensionId`
  - `msg.value ≥ fee(F_WALLET, KEY_DELETE)`
- **Effects**:
  - Sends a [`F_WALLET KEY_DELETE`](../Reference/Operations/F_WALLET.md#key_delete) instruction to `teeId`.
  - Removes `teeId` from `key.teeIds` (if present; absence is silently ignored as a retry path).
  - Emits [`WalletKeyDeleted`](../Reference/Contracts/FlareTeeManagerEvents.md#walletkeydeleted) and [`TeeInstructionsSent`](../Reference/Contracts/FlareTeeManagerEvents.md#teeinstructionssent).
  - On the TEE machine: the private key material is wiped, but the [wallet-key variables](../Concepts/Keys.md#wallet-key-variables) (`nonce`, `pauseNonce`, `status`, `expiry`) are retained so a later [restoration](KeyRestore.md) cannot reuse a stale nonce.

### cleanUpTeeIds: Stale → OnTee (per remaining TEE)

- **Action**: [`FlareTeeManager.cleanUpTeeIds(walletId, keyId)`](../Reference/Contracts/FlareTeeManager.md#key-custody) — non-payable.
- **Caller**: project owner or `project.backupManager`.
- **Guards**:
  - `key.publicKey ≠ 0`
- **Effects**:
  - For each entry of `key.teeIds` whose machine is not in `PRODUCTION`, removes the entry.
  - Emits [`WalletKeyDeleted`](../Reference/Contracts/FlareTeeManagerEvents.md#walletkeydeleted) for each removed entry.
  - Does not touch the TEE machines themselves (they may already be paused, banned, or replicated).

## Invariants

- The key's `publicKey` is immutable; deletion never clears it.
- `wallet.status` is unrestricted: `deleteKey` is callable across all four statuses.
- A TEE machine that was once associated with the key keeps its nonce records even after the binding is removed; this lets [KeyRestore](KeyRestore.md) detect and reject stale nonces.

## Terminal States

`Deleted` (for the `(walletId, keyId, teeId)` triple). The key as a whole is _not_ terminal:

- If at least one other TEE still holds the key, the wallet can keep operating with reduced redundancy.
- If all TEEs are deleted, the key definition remains, and [KeyRestore](KeyRestore.md) can re-instantiate it from backup.

## Notes

- `deleteKey` is unconditional with respect to wallet status — useful for emergency removal even on `PAUSED` wallets.
- The cleanup transition is a separate convenience; the `Deleted` state can be reached without ever invoking `cleanUpTeeIds` if the project owner keeps the `teeIds` list tidy via direct `deleteKey` calls.
