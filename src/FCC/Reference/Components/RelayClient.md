# Relay Client

A _relay client_ transforms [instruction events](../../Concepts/Instructions.md#sending-instructions) into signed [instructions](../../Concepts/Instructions.md) and submits them to [TEE proxies](Proxy.md).
It runs as either a _[data provider](../../../Terminology/Roles.md#data-provider)_ or a _[cosigner](../../Concepts/Instructions.md#cosigners)_, identified by the address of a private key (its _operator_).

## Relay Flow

1. Observe [`TeeInstructionsSent`](../Contracts/FlareTeeManagerEvents.md#teeinstructionssent) events from [`FlareTeeManager`](../Contracts/FlareTeeManager.md) by polling an operator-run C-chain indexer database (identically-named events from other contracts are ignored).
2. Filter by mode:
   - _Data provider_: accept all instructions.
   - _Cosigner_: accept only instructions whose [`cosigners` list](../../Concepts/Instructions.md#cosigners) includes the operator's address.
3. For [augmented](../../Concepts/Instructions.md#augmentation) commands, run the per-command procedure:
   - [`F_FDC2 PROVE`](../../../FDC2/Reference/Operations/Prove.md#augmentation-procedure)
   - [`F_WALLET KEY_DATA_PROVIDER_RESTORE`](../Operations/F_WALLET.md#augmentation)
4. De-duplicate the event's `teeMachines` list and, for each remaining [`TeeMachine`](../Types/Abi/TeeMachine.md#teemachine) record, build one [`Instruction`](../Types/Wire/Instruction.md#instruction):
   - Copy from the event: `instructionId`, `rewardEpochId`, `opType`, `opCommand`, `cosigners`, `cosignersThreshold`, and the event's `message` (as `originalMessage`).
   - Set `timestamp` to the emitting block's timestamp.
   - Set `teeId` to the record's `teeId`.
   - For augmented commands, set `additionalFixedMessage` and `additionalVariableMessage` from step 3; otherwise leave them empty.
   - Set `signature` to the [ECDSA signature](../../../Utilities/Signing.md) over [`hashForSigning`](../../Concepts/Instructions.md#hashes) with the operator's private key.
5. Submit the resulting `Instruction` as JSON via [`POST /instruction`](Proxy.md#external-write-apis) to the record's `url`.

## Behavior

1. **Best-effort delivery**: The same instruction may be submitted more than once or arrive in different orders at different proxies.
2. **Concurrent processing**: A slow or failing instruction does not block others.
3. **No persistence**: Instructions emitted while the relay client is offline may not be relayed, and undelivered ones do not survive restarts.
