# Concepts

Cross-cutting concept pages — _the "what and why" of FCC_. Each page defines a concept and its invariants; precise validation rules, field schemas, and contract function surfaces live under [Reference/](../Reference/Components/README.md).

## Pages

| Page | Contents |
|---|---|
| [Instructions](Instructions.md) | The off-chain payload that requests an operation: issuance, signing, augmentation; the on-chain event and its off-chain envelope. |
| [Actions](Actions.md) | What a TEE machine receives and produces, including direct actions and action responses. |
| [Voting](Voting.md) | Data-provider and cosigner threshold rules; pass conditions. |
| [Rewarding](Rewarding.md) | Per-vote receipts and the reward-attribution payload. |
| [Machines](Machines.md) | TEE identity, attestation, state, registration, statuses, replication. |
| [Keys](Keys.md) | Wallet key custody, signing algorithms, backup, restoration. |
| [Wallets](Wallets.md) | Projects, wallets, multisig, wallet-key bookkeeping. |

The path an operation takes through these phases:

- _Instruction operations_ flow through Instructions → Voting → Actions → Rewarding.
- _Direct operations_ skip Instructions and Voting and arrive as actions directly; see [Actions § Direct Actions](Actions.md#direct-actions).

## Reading order

1. [Architecture](../Architecture.md) — high-level overview and trust model.
2. [Machines](Machines.md) — what a TEE machine is and how it joins the network.
3. [Instructions](Instructions.md), [Actions](Actions.md) — the lifecycle of one operation.
4. [Voting](Voting.md) — how proxies aggregate signatures into a pass.
5. [Wallets](Wallets.md), [Keys](Keys.md) — what TEEs custody, and how.
6. [Rewarding](Rewarding.md) — how participation is attributed and reconstructed off-chain.
