# Relay Client

A _relay client_ transforms [instruction events](Instructions.md#instruction-events) into signed [TEE instructions](Instructions.md#tee-instructions) and submits them to [TEE proxies](../TeeManagement/TeeProxy.md).
It runs as either a _[data provider](../../Terminology/Roles.md#data-provider)_ or a _[cosigner](../../Terminology/Roles.md#cosigner)_, identified by the address of a configured private key (its _operator_).

## Relay Flow

1. Observe an instruction event via a C-chain indexer database (the operator must provide the indexer).
   Only `TeeInstructionsSent` events emitted by the `FlareTeeManager` contract are accepted; identically-named events from other contracts are ignored.
2. Filter by mode:
   - _Data provider_: accept all instructions.
   - _Cosigner_: accept only instructions whose [`cosigners` list](Instructions.md#cosigners) includes the operator's address.
3. For [augmented](Instructions.md#augmentation) commands, run the per-command procedure to populate `additionalFixedMessage` and `additionalVariableMessage`:
   - [`F_FDC2 PROVE`](../Commands/F_FDC2--PROVE.md#augmentation-procedure)
   - [`F_WALLET KEY_DATA_PROVIDER_RESTORE`](../Commands/F_WALLET--KEY_DATA_PROVIDER_RESTORE.md#augmentation-procedure)
4. For each [`TeeMachine`](../Types/Abi/TeeMachine.md#teemachine) record in the event's `teeMachines` field, build one TEE instruction with that record's `teeId`.
5. Sign the instruction over [`HashForSigning(data)`](Instructions.md#signature-format) and submit it via [`POST /instruction`](../TeeManagement/TeeProxy.md#external-write-apis) to the record's `url`.

## Behavior

- _Best effort_: delivery and ordering are not guaranteed; the same instruction may be submitted more than once or arrive in different orders at different proxies.
- Instructions are processed concurrently, so one slow or failing instruction does not block others.
- Compatible with proxy [voting](Voting.md) and, where required, replay protection inside the TEE machine.
- Instructions emitted while the relay client is offline may not be relayed; undelivered instructions are not persisted across restarts.
