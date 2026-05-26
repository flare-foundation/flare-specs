# Concepts

Cross-cutting concept pages — _the "what and why" of FCC_. Each page defines a concept and its invariants; precise validation rules, field schemas, and contract function surfaces live under [Reference/](../Reference/Components/README.md).

Most operations flow [Instructions](Instructions.md) → [Voting](Voting.md) → [Actions](Actions.md) → [Rewarding](Rewarding.md).
[Direct actions](Actions.md#direct-actions) skip the first two phases and arrive at the machine immediately.

## Reading order

1. [Architecture](../Architecture.md) — participants, instruction flow, deployment topology.
2. [Trust Model](TrustModel.md) — the integrity assumptions the rest of the spec relies on.
3. [Machines](Machines.md) — what a TEE machine is and how it joins the network.
4. [Instructions](Instructions.md), [Actions](Actions.md) — the lifecycle of one operation.
5. [Voting](Voting.md) — how proxies aggregate signatures into a pass.
6. [Wallets](Wallets.md), [Keys](Keys.md) — what TEEs custody, and how.
7. [Rewarding](Rewarding.md) — how participation is attributed and reconstructed off-chain.
