# Concepts

Cross-cutting concept pages — _the "what and why" of FCC_. Each page defines a concept and its invariants; precise validation rules, field schemas, and contract function surfaces live under [Reference/](../Reference/Components/README.md).

Most operations flow [Instructions](Instructions.md) → [Voting](Voting.md) → [Actions](Actions.md) → [Rewarding](Rewarding.md).
[Direct actions](Actions.md#direct-actions) skip the first two phases and arrive at the machine immediately.

## Reading order

1. [Architecture](../Architecture.md) — participants, instruction flow, deployment topology.
2. [Trust Model](TrustModel.md) — the integrity assumptions the rest of the spec relies on.
3. [Machines](Machines.md) — what a TEE machine is and how it joins the network.
4. [Signing Policy](Policy.md) — the FSP voter set each machine tracks; it gates instruction verification and voting.
5. [Instructions](Instructions.md) — how an operation is sent and relayed to a machine.
6. [Voting](Voting.md) — how proxies aggregate signatures into a pass.
7. [Actions](Actions.md) — what a machine executes once an instruction passes.
8. [Wallets](Wallets.md) — the projects and wallets TEEs custody keys for.
9. [Keys](Keys.md) — what TEEs custody, and how.
10. [Rewarding](Rewarding.md) — how participation is attributed and reconstructed off-chain.
