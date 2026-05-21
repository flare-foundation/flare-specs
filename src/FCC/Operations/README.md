# Operations

An _operation_ is a piece of work a [TEE machine](../Components/TeeMachine.md) performs, identified by an `(opType, opCommand)` pair (e.g. `F_WALLET KEY_GENERATE`).
System operations carry the `F_` op-type prefix and are handled by every TEE machine regardless of [FCE](../Extensions/README.md); custom operations are defined by individual FCEs.

This directory documents the operation lifecycle and the system catalog:

| Page | Contents |
|---|---|
| [Instructions](Instructions.md) | The off-chain payload that requests an operation: issuance, signing, augmentation; the on-chain event and its off-chain envelope. |
| [Voting](Voting.md) | Data provider and cosigner threshold rules; pass conditions. |
| [Actions](Actions.md) | What a TEE machine receives and produces, including direct actions (which bypass instructions and voting) and action responses. |
| [Rewarding](Rewarding.md) | Per-vote receipts and the reward-attribution payload they feed into. |
| [Commands](Commands/README.md) | Reference for each system `(opType, opCommand)` pair, organized by op-type. |

The path an operation takes through this directory depends on its kind:

- _Instruction operations_ flow through Instructions → Voting → Actions.
- _Direct operations_ skip Instructions and Voting and arrive as actions directly; see [Actions](Actions.md#direct-actions).

For the off-chain participants that implement this flow, see [Components](../Components/README.md).
For extension-app commands that live outside this directory, see [PMW commands](../Extensions/PMW/Commands/README.md) and [FDC2 commands](../Extensions/FDC2/Commands/README.md).
