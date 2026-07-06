# Wallets

Some FCC use cases need a TEE machine to hold a long-lived private key, typically because the key signs transactions on an external blockchain (XRPL, EVM chains) on a user's behalf.
_Projects_, _wallets_, and _wallet keys_ are the on-chain bookkeeping that controls those keys: who may authorize their use, under what threshold, and on which TEE machines they live.

They are scoped per [FCE](../FCE/README.md): each FCE has its own pool of projects, and every project is pinned to a single FCE at creation.
The pattern is the foundation of the [Protocol Managed Wallet (PMW)](../../PMW/README.md) infrastructure on the system extension, and is available to any FCE whose [TEE machines](../Reference/Components/Machine.md) need the same custody.
FCEs that only sign with the TEE's identity key (pure compute, [FDC2 proofs](../../FDC2/README.md), registration attestation) do not need them.

The on-chain state and the entry points that drive it live on [`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md); see [Project Management](../Reference/Contracts/FlareTeeManager.md#project-management) and [Wallet Management](../Reference/Contracts/FlareTeeManager.md#wallet-management) for the function catalog.

## Overview

As data structures, wallets are maanged in three levels:

1. **Project**: the top-level grouping of wallets. Bound at creation to a single FCE identified by its `extensionId` (a project never spans extensions) and to one `(keyType, signingAlgo)` pair to be used by its wallet keys. Owned by a single Flare address, the [project owner](../../Terminology/Roles.md#project-owner), which is the only address allowed to add or configure wallets under it.
2. **Wallet**: sits inside a project. Each wallet defines who can authorize operations against that wallet's keys, via a set of admin public keys with a $k$-of-$n$ threshold for [backup operations](Keys.md#backup-procedure), and optionally a set of [cosigner](Instructions.md#cosigners) addresses with a threshold for transaction-level multisigs. A wallet must progresses through statuses (`CREATED` → `INITIALIZED` → `PRODUCTION`, with a `PAUSED` side state) before its keys can be used. See below for lifecycle information.
3. **Wallet key**: a single private key, generated inside one or more TEE machines, confirmed on-chain via a [key existence proof](Keys.md#tee-key-existence-proof). These keys are what are used to e.g. authorize transactions. A wallet's `multisigThreshold` sets how many distinct keys must sign for the wallet to authorize a transaction; combined with the per-chain native multisig (e.g. XRPL `SignerList`), this enforces a $k$-of-$n$ split across TEE machines.

## Projects

A project is created by an allowlisted [project owner](../../Terminology/Roles.md#project-owner).
The owner selects an FCE for the project and a single `(keyType, signingAlgo)` pair shared by every wallet in the project.
Both are fixed at creation of the project.

A Project is identified by a unique `projectID` and has the following on-chain state:

- `owner`: project-owner address; changes only through a two-step transfer.
- `extensionId`: the FCE the project lives under; immutable.
- `keyType` and `signingAlgo`: shared by every wallet in the project; immutable, constrained to the [pairs the FCE supports](Keys.md#signing-algorithms).
- `backupManager`: optional second address authorized to trigger [key restoration](Keys.md#key-restoration).

The project owner role is checked against the FCE's [owner allowlist](Machines.md#owner-allowlist) at every state-changing call.

## Wallets

A wallet lives inside a project, is identified by a unique `walletID` and has the following on-chain state:

- `projectId`: the parent project.
- `adminsPublicKeys` and `adminsThreshold`: the [key admin](../../Terminology/Roles.md#key-admin) public keys and the $k$-of-$n$ threshold over them; set during creation.
- `cosigners` and `cosignersThreshold`: optional [cosigner](Instructions.md#cosigners) address set and its signing threshold; set during creation.
- `multisigThreshold`: minimum number of confirmed keys required to sign with the wallet.
- `status`: one of `NONE`, `CREATED`, `INITIALIZED`, `PRODUCTION`, `PAUSED`.

Once a wallet leaves `CREATED`, its admins, cosigners, and their thresholds are immutable.
A copy of these is also written into every TEE-side [`configConstants`](Keys.md#wallet-private-key-data-structure) record at key generation.
This facilitates [cosigner enforcement](../Reference/Components/Machine.md#cosigner-enforcement) by the TEE machine.

### Lifecycle

A wallet moves through four statuses, gated by the project owner:

1. `CREATED → INITIALIZED`: once every admin and every cosigner has confirmed participation from its own address.
2. `INITIALIZED → PRODUCTION`: once `multisigThreshold` is set and at least that many keys have been [confirmed](Keys.md#tee-key-existence-proof).
3. `PRODUCTION → PAUSED`: triggered by an owner-initiated stop or by a designated pausing address.
4. `PAUSED → PRODUCTION`: triggered by an owner-initiated resumption or by a designated pausing address; the multisig check is not re-run.

## Wallet Keys

A wallet holds [private keys](Keys.md#wallet-private-key-data-structure), each replicated across one or more TEE machines.
A key is identified within its wallet by a sequential `keyId`, assigned at the moment a key generation is requested.

For each `(walletId, keyId)` the contract tracks:

1. `publicKey`: set when the first TEE machine [confirms](Keys.md#tee-key-existence-proof) the generated key.
2. `teeIds`: the set of TEE machines that hold a copy.
3. `nonces`: per-machine replay counters used by state-changing commands (`KEY_DELETE`).

See [Keys](Keys.md) for off-chain key generation, the existence-proof construction, and the backup/restoration procedures.