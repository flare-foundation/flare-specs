# Relay Client

A _relay client_ transforms [instruction events](../Operations/Instructions.md#sending-instructions) into signed [instructions](../Operations/Instructions.md) and submits them to [TEE proxies](TeeProxy.md).
It runs as either a _[data provider](../../Terminology/Roles.md#data-provider)_ or a _[cosigner](../Operations/Instructions.md#cosigners)_, identified by the address of a private key (its _operator_).

## Relay Flow

1. Observe [`TeeInstructionsSent`](../Types/Abi/Events/TeeExtensionRegistry.md#teeinstructionssent) events from the [`FlareTeeManager`](../TeeManagement/FlareTeeManager.md) contract by polling an operator-run C-chain indexer database.
   Identically-named events from other contracts are ignored.
2. Filter by mode:
   - _Data provider_: accept all instructions.
   - _Cosigner_: accept only instructions whose [`cosigners` list](../Operations/Instructions.md#cosigners) includes the operator's address.
3. For [augmented](../Operations/Instructions.md#augmentation) commands, run the per-command procedure:
   - [`F_FDC2 PROVE`](../Extensions/FDC2/Commands/Prove.md#augmentation-procedure)
   - [`F_WALLET KEY_DATA_PROVIDER_RESTORE`](../Operations/Commands/F_WALLET/KeyDataProviderRestore.md#augmentation-procedure)
4. De-duplicate the event's `teeMachines` list and, for each remaining [`TeeMachine`](../Types/Abi/TeeMachine.md#teemachine) record, build one [`Instruction`](../Types/Wire/Instruction.md#instruction):
   - Copy from the event: `instructionId`, `rewardEpochId`, `opType`, `opCommand`, `cosigners`, `cosignersThreshold`, and the event's `message` (as `originalMessage`).
   - Set `timestamp` to the timestamp of the block that emitted the event.
   - Set `teeId` to the record's `teeId`.
   - Set `additionalFixedMessage` and `additionalVariableMessage` from step 3 for augmented commands; otherwise leave them empty.
   - Set `signature` to the [ECDSA signature](../../Utilities/Signing.md) over [`hashForSigning`](../Operations/Instructions.md#hashes) with the operator's private key.
5. Submit the resulting `Instruction` as JSON via [`POST /instruction`](TeeProxy.md#external-write-apis) to the record's `url`.

## Behavior

1. **Best-effort delivery**: The same instruction may be submitted more than once or arrive in different orders at different proxies.
2. **Concurrent processing**: A slow or failing instruction does not block others.
3. **No persistence**: Instructions emitted while the relay client is offline may not be relayed, and undelivered ones do not survive restarts.
