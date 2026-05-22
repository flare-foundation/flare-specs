# Concepts

Cross-cutting concept pages — _the "what and why" of FCC_. Each page defines a concept and its invariants; precise validation rules and field-level schemas live under [Reference/](../Reference/Components/README.md).

## Pages

| Page | Contents |
|---|---|
| [Instructions](Instructions.md) | The off-chain payload that requests an operation: issuance, signing, augmentation; the on-chain event and its off-chain envelope. |
| [Actions](Actions.md) | What a TEE machine receives and produces, including direct actions and action responses. |
| [Voting](Voting.md) | Data-provider and cosigner threshold rules; pass conditions. |
| [Rewarding](Rewarding.md) | Per-vote receipts and the reward-attribution payload. |

The path an operation takes through these phases:

- _Instruction operations_ flow through Instructions → Voting → Actions → Rewarding.
- _Direct operations_ skip Instructions and Voting and arrive as actions directly; see [Actions § Direct Actions](Actions.md#direct-actions).

## Pending pages

Phase B will add:

- `Machines.md` — TEE identity, attestation, registration, statuses, replication (from `../TeeManagement/{Attestation,Registration,State}.md`).
- `Keys.md` — wallet key custody, backup, restoration (from `../TeeManagement/Keys.md`).
- `Wallets.md` — projects, wallets, multisig (from `../TeeManagement/Wallets.md`).
- `Policy.md` — signing-policy lifecycle on the FCC side (defers to FSP for the canonical spec).

## Reading order

1. [Architecture](../Architecture.md) — high-level overview and trust model.
2. `Instructions.md`, `Actions.md` — the lifecycle of one operation.
3. `Voting.md` — how proxies aggregate signatures into a pass.
4. `Rewarding.md` — how participation is attributed and reconstructed off-chain.
5. (Pending) `Machines.md`, `Keys.md`, `Wallets.md` — TEE machine state and the keys they custody.
