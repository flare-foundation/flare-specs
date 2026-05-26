# Wallets

Some FCC use cases need a TEE machine to hold a long-lived private key — typically because the key signs transactions on an external blockchain (XRPL, EVM chains) on a user's behalf.
_Projects_, _wallets_, and _wallet keys_ are the on-chain bookkeeping that controls those keys: who may authorize their use, under what threshold, and on which TEE machines they live.

They are scoped per [FCE](../FCE/README.md): each FCE has its own pool of projects, and every project is pinned to a single FCE at creation.
The pattern is the foundation of the [Protocol Managed Wallet (PMW)](../../PMW/README.md) infrastructure on the system extension, and is available to any FCE whose [TEE machines](../Reference/Components/Machine.md) need the same custody.
FCEs that only sign with the TEE's identity key (pure compute, [FDC2 proofs](../../FDC2/README.md), registration attestation) do not need them.

The on-chain state and the entry points that drive it live on [`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md); see [Project Management](../Reference/Contracts/FlareTeeManager.md#project-management) and [Wallet Management](../Reference/Contracts/FlareTeeManager.md#wallet-management) for the function catalog.

## Overview

The data model is three nested levels:

1. **Project** — the top-level grouping. Bound at creation to a single FCE (the `extensionId` is immutable and a project never spans extensions) and to one `(keyType, signingAlgo)` pair, so a project targets one external-chain family (e.g. XRPL keys, EVM keys). Owned by a single Flare address — the [project owner](../../Terminology/Roles.md#project-owner) — which is the only address allowed to add or configure wallets under it.
2. **Wallet** — sits inside a project. Defines _who can authorize operations against the wallet's keys_: a set of admin public keys with a $k$-of-$n$ threshold for [backup operations](Keys.md#backup-procedure), and optionally a set of [cosigner](Instructions.md#cosigners) addresses with a threshold for transaction-level multisig. A wallet progresses through statuses (`CREATED` → `INITIALIZED` → `PRODUCTION`, with a `PAUSED` side state) before its keys can be used.
3. **Wallet key** — a single private key, generated inside one or more TEE machines, confirmed on-chain via a [key existence proof](Keys.md#tee-key-existence-proof). A wallet's `multisigThreshold` sets how many distinct keys must sign for the wallet to authorize a transaction; combined with the per-chain native multisig (e.g. XRPL `SignerList`), this gives a $k$-of-$n$ split across TEE machines.

## Projects

A project is created by an allowlisted [project owner](../../Terminology/Roles.md#project-owner). The owner picks the FCE the project lives under and a single `(keyType, signingAlgo)` pair shared by every wallet in the project. Both are fixed at creation: a project never spans FCEs and never mixes key types.

Project state captured on-chain:

- `owner`: project-owner address; changes only through a two-step transfer.
- `extensionId`: the FCE the project lives under; immutable.
- `keyType` and `signingAlgo`: shared by every wallet in the project; immutable, constrained to the [pairs the FCE supports](Keys.md#signing-algorithms).
- `backupManager`: optional second address authorized to trigger [key restoration](Keys.md#key-restoration).

Both owner roles are checked against the FCE's [owner allowlist](Machines.md#owner-allowlist) at every state-changing call.

## Wallets

A wallet lives inside a project. Wallet state captured on-chain:

- `projectId`: the parent project.
- `adminsPublicKeys` and `adminsThreshold`: the [key admin](../../Terminology/Roles.md#key-admin) public keys and the $k$-of-$n$ threshold over them; set during initialization, finalized at close.
- `cosigners` and `cosignersThreshold`: optional [cosigner](Instructions.md#cosigners) address set and its threshold; set during initialization, finalized at close.
- `multisigThreshold`: minimum number of confirmed keys required to sign with the wallet.
- `status`: one of `CREATED`, `INITIALIZED`, `PRODUCTION`, `PAUSED`.

Once a wallet leaves `CREATED`, its admins, cosigners, and their thresholds are immutable.
A copy of these is also written into every TEE-side [`configConstants`](Keys.md#wallet-private-key-data-structure) record at key generation, for [cosigner enforcement](../Reference/Components/Machine.md#cosigner-enforcement) by the TEE machine.

### Lifecycle

A wallet moves through four statuses, gated by the project owner:

1. `CREATED → INITIALIZED` — once every admin and every cosigner has confirmed from its own address.
2. `INITIALIZED → PRODUCTION` — once `multisigThreshold` is set and at least that many keys have been [confirmed](Keys.md#tee-key-existence-proof).
3. `PRODUCTION → PAUSED` — owner-initiated stop.
4. `PAUSED → PRODUCTION` — resume; the multisig check is not re-run.

### Pausing Keys at the TEE

Pausing a wallet only changes its on-chain status; it does not reach the TEE machines that hold the wallet's keys.
To pause individual keys at their machines, the project owner additionally installs _pausing addresses_ (authorized to pause those keys) and later resumes specific `(teeId, keyId, nonce)` triples. Both calls are payable; the fee covers TEE-side execution.

## Wallet Keys

A wallet holds zero or more [private keys](Keys.md#wallet-private-key-data-structure), each replicated across one or more TEE machines.
A key is identified within its wallet by a sequential `keyId`, assigned at the moment a key generation is requested.

For each `(walletId, keyId)` the contract tracks:

1. `publicKey`: set when the first TEE machine [confirms](Keys.md#tee-key-existence-proof) the generated key.
2. `teeIds`: the set of TEE machines that hold a copy.
3. `nonces`: per-machine replay counters used by state-changing commands (`KEY_DELETE`, `RESUME`).

See [Keys](Keys.md) for off-chain key generation, the existence-proof construction, and the backup/restoration procedures.
