# Concepts

Cross-cutting concept pages — _the "what and why" of FCC_. Each page defines a concept and its invariants; precise validation rules and field-level schemas live under [Reference/](../Reference/Components/README.md).

This chapter is currently being populated from content in [`../Operations/`](../Operations/README.md) and [`../TeeManagement/`](../TeeManagement/README.md). Pending pages:

- `Operations.md` — the operation lifecycle (instructions → voting → actions → result → reward).
- `Machines.md` — identity, attestation, registration, statuses, replication.
- `Policy.md` — signing policy (FCC view; defers to FSP for the canonical spec).
- `Keys.md` — wallet key custody, backup, restoration.
- `Voting.md` — threshold consensus, cosigners.
- `Rewarding.md` — vote-receipt chain.

## Reading order

For new readers, the recommended path is:

1. [Architecture](../Architecture.md) — high-level overview and trust model.
2. `Operations.md` — what an operation is and how it flows.
3. `Machines.md` — what a TEE machine is and how it joins the network.
4. `Policy.md` — the cross-protocol signing policy that gates voting.
5. `Voting.md` and `Keys.md` — threshold rules and key custody, in either order.
6. `Rewarding.md` — last, since it is downstream of everything else.
