# Wallets

Some FCC use cases need a TEE machine to hold a long-lived private key — typically because the key signs transactions on an external blockchain (XRPL, EVM chains) on a user's behalf.
_Projects_, _wallets_, and _wallet keys_ are the on-chain bookkeeping that controls those keys: who may authorize their use, under what threshold, and on which TEE machines they live.

They are scoped per [FCE](../FCE/README.md): each FCE has its own pool of projects, and every project is pinned to a single FCE at creation.
The pattern is the foundation of the [Protocol Managed Wallet (PMW)](../PMW/README.md) infrastructure on the system extension, and is available to any FCE whose [TEE machines](../Reference/Components/Machine.md) need the same custody.
FCEs that only sign with the TEE's identity key (pure compute, [FDC2 proofs](../FDC2/README.md), registration attestation) do not need them.

All state lives on the [`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md) contract.

## Overview

The data model is three nested levels:

1. **Project** — the top-level grouping. Bound at creation to a single FCE (the `extensionId` is immutable and a project never spans extensions) and to one `(keyType, signingAlgo)` pair, so a project targets one external-chain family (e.g. XRPL keys, EVM keys). Owned by a single Flare address — the [project owner](../../Terminology/Roles.md#project-owner) — which is the only address allowed to add or configure wallets under it.
2. **Wallet** — sits inside a project. Defines _who can authorize operations against the wallet's keys_: a set of admin public keys with a $k$-of-$n$ threshold for [backup operations](Keys.md#backup-procedure), and optionally a set of [cosigner](Instructions.md#cosigners) addresses with a threshold for transaction-level multisig. A wallet progresses through statuses (`CREATED` → `INITIALIZED` → `PRODUCTION`, with a `PAUSED` side state) before its keys can be used.
3. **Wallet key** — a single private key, generated inside one or more TEE machines, confirmed on-chain via a [key existence proof](Keys.md#tee-key-existence-proof). A wallet's `multisigThreshold` sets how many distinct keys must sign for the wallet to authorize a transaction; combined with the per-chain native multisig (e.g. XRPL `SignerList`), this gives a $k$-of-$n$ split across TEE machines.

The rest of this file describes each level in detail.

## Projects

A project is created when an address allowlisted as a [project owner](../../Terminology/Roles.md#project-owner) for an [FCE](../FCE/README.md) calls `createProject(extensionId, keyType, signingAlgo)`.
The new `projectId` is `keccak256(abi.encode("PROJECT", msg.sender, counter))` and the caller becomes the project owner.

Project state:

1. `owner`: The current project owner address; changes only through a two-step transfer (`proposeNewOwner` / `confirmOwnership`).
2. `extensionId`: The FCE the project lives under; immutable.
3. `keyType` and `signingAlgo`: The [key type and algorithm](Keys.md#signing-algorithms) shared by every wallet in the project; immutable, and constrained to the pairs the FCE supports.
4. `backupManager`: An optional second address authorized to trigger [key restoration](Keys.md#key-restoration-procedure); set with `setBackupManager`.

Both owner roles are gated against the FCE's [owner allowlist](Machines.md#owner-allowlist) at every state-changing call.

Lifecycle events: [`ProjectCreated`](../Reference/Types/Abi/Events/TeeWalletProjectManager.md#projectcreated), [`BackupManagerSet`](../Reference/Types/Abi/Events/TeeWalletProjectManager.md#backupmanagerset), [`NewOwnerProposed`](../Reference/Types/Abi/Events/TeeWalletProjectManager.md#newownerproposed), [`OwnershipConfirmed`](../Reference/Types/Abi/Events/TeeWalletProjectManager.md#ownershipconfirmed).

## Wallets

A wallet is created when the project owner calls `createWallet(projectId)`.
The new `walletId` is `keccak256(abi.encode("WALLET", owner, counter))` and the wallet enters the `CREATED` status.

Wallet state:

1. `projectId`: The parent project.
2. `adminsPublicKeys` and `adminsThreshold`: The [key admin](../../Terminology/Roles.md#key-admin) public keys and the $k$-of-$n$ threshold over them; set with `setAdmins`, finalized at close.
3. `cosigners` and `cosignersThreshold`: An optional [cosigner](Instructions.md#cosigners) address set and its threshold; set with `setCosigners`, finalized at close.
4. `multisigThreshold`: The minimum number of confirmed keys required to sign with the wallet; set with `setMultisigThreshold`.
5. `status`: One of `CREATED`, `INITIALIZED`, `PRODUCTION`, `PAUSED`.

Once a wallet leaves `CREATED`, its admins, cosigners, and their thresholds are immutable.
A copy of these is also written into every TEE-side [`configConstants`](Keys.md#wallet-private-key-data-structure) record at key generation, for [cosigner enforcement](../Reference/Components/Machine.md#cosigner-enforcement) by the TEE machine.

### Lifecycle

Status transitions, with the call that triggers each:

1. `CREATED → INITIALIZED` — `closeWalletInitialization`, after every admin and every cosigner has called `confirmAdmin` / `confirmCosigner` from its own address.
2. `INITIALIZED → PRODUCTION` — `enableWallet`, once `multisigThreshold` is set and at least that many keys have been [confirmed](Keys.md#tee-key-existence-proof).
3. `PRODUCTION → PAUSED` — `pauseWallet`.
4. `PAUSED → PRODUCTION` — `enableWallet` (no multisig recheck).

The project owner is the sole caller for every transition.

Lifecycle events: [`WalletCreated`](../Reference/Types/Abi/Events/TeeWalletManager.md#walletcreated), [`WalletAdminsSet`](../Reference/Types/Abi/Events/TeeWalletManager.md#walletadminsset), [`WalletAdminConfirmed`](../Reference/Types/Abi/Events/TeeWalletManager.md#walletadminconfirmed), [`WalletCosignersSet`](../Reference/Types/Abi/Events/TeeWalletManager.md#walletcosignersset), [`WalletCosignerConfirmed`](../Reference/Types/Abi/Events/TeeWalletManager.md#walletcosignerconfirmed), [`WalletInitialized`](../Reference/Types/Abi/Events/TeeWalletManager.md#walletinitialized), [`WalletEnabled`](../Reference/Types/Abi/Events/TeeWalletManager.md#walletenabled), [`WalletPaused`](../Reference/Types/Abi/Events/TeeWalletManager.md#walletpaused).

### Pausing Keys at the TEE

`pauseWallet` only changes on-chain status; it does not reach the TEE machines that hold the wallet's keys.
To pause individual keys at their machines, the project owner additionally calls:

1. `setPausingAddresses(walletId, pausingAddresses, claimBackAddress)` — issues an `F_WALLET SET_PAUSING_ADDRESSES` instruction to every TEE machine listed in the wallet's key set, installing addresses authorized to pause those keys.
2. `resume(walletId, keysData, claimBackAddress)` — issues an `F_WALLET RESUME` instruction for the listed `(teeId, keyId, nonce)` triples.

Both calls are payable; the fee covers TEE-side execution and can be claimed back by `claimBackAddress` if the instructions do not execute.

## Wallet Keys

A wallet holds zero or more [private keys](Keys.md#wallet-private-key-data-structure), each replicated across one or more TEE machines.
A key is identified within its wallet by a sequential `keyId`, assigned at `addKey` time.

For each `(walletId, keyId)` the contract tracks:

1. `publicKey`: Set when the first TEE machine [confirms](Keys.md#tee-key-existence-proof) the generated key.
2. `teeIds`: The set of TEE machines that hold a copy; further TEE machines join by submitting a key existence proof, and machines drop off via `deleteKey` or `cleanUpTeeIds`.
3. `nonces`: A per-TEE-machine replay counter used by state-changing commands (`KEY_DELETE`, `RESUME`).

See [Key Management](Keys.md) for the off-chain key generation, existence proof, and backup procedures, and for the contract calls that drive them.
