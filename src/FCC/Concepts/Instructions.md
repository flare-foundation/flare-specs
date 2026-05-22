# Instructions

An _instruction_ is an off-chain payload submitted to a [TEE proxy](../Reference/Components/Proxy.md), directing a [TEE machine](../Reference/Components/Machine.md) to execute an operation.

The [instruction](../Reference/Types/Wire/Instruction.md#instruction) has two fields:

1. `data`: The [`Data`](../Reference/Types/Wire/Instruction.md#data) payload (every field of [`TeeInstruction`](../Reference/Types/Abi/Instruction.md#teeinstruction) plus `additionalVariableMessage`).
2. `signature`: A [signature](../../Utilities/Signing.md) over [`hashForSigning`](#hashes), produced by the relaying [signer](#signers).

The signature covers `teeId`, so a compromised proxy cannot replay an instruction to a different machine.

## Signers

A _signer_ is a [data provider](../../Terminology/Roles.md#data-provider) or [cosigner](#cosigners) that signs an instruction over [`hashForSigning`](#hashes) and submits it to a [TEE proxy](../Reference/Components/Proxy.md).

- Data providers come from the [signing policy](../../FSP/SigningPolicy.md) for the instruction's reward epoch.
- Cosigners are attached per-instruction.
- A data provider also listed in `cosigners` counts toward both [voting](Voting.md) tallies.

### Cosigners

A _cosigner_ is any Flare [address](../../Terminology/Concepts.md#addresses-accounts-and-keys) attached to an instruction to enforce a multisig requirement on top of data provider voting.
Cosigners run their [relay client](../Reference/Components/RelayClient.md) in cosigner mode and, unlike data providers, need not participate in other Flare protocols.

The event's `cosigners` field lists the eligible addresses; `cosignersThreshold` is the minimum number of cosigner signatures required to pass.
A weighted majority of malicious data providers could strip these fields and bypass proxy-side enforcement, so extensions that rely on cosigners must re-enforce them at the TEE-machine layer (see [Cosigner Enforcement](../Reference/Components/Machine.md#cosigner-enforcement)).

## Sending Instructions

1. A [user](../../Terminology/Roles.md#user) issues an instruction by calling an [_instructions sender_](../FCE/Concepts.md#extension-data-structure) contract.
2. The instructions sender calls the [`FlareTeeManager`](../Reference/Contracts/FlareTeeManager.md#sending-instructions), which emits a [`TeeInstructionsSent`](../Reference/Contracts/FlareTeeManagerEvents.md#teeinstructionssent) event listing one or more destination TEE machines.
3. Signers observe the event; each runs a relay client that submits a separately signed instruction to every destination machine's TEE proxy.
4. Once [voting](Voting.md#pass-conditions) collects enough signed copies, the proxy bundles the instruction with its signatures into an [action](Actions.md) for the destination TEE machine.

### Instructions Senders

There are two kinds:

- A _system instructions sender_: may send any op-type to any [extension](../FCE/README.md)'s TEE machines.
- An _extension's instructions sender_: may only send non-[system op-types](../FCE/Concepts.md#system-vs-custom-extensions) (`F_` prefix forbidden) and only to that extension's own TEE machines.

The [system extension](../FCE/System.md) (`extensionId == 0`) cannot have an instructions sender of its own; its TEE machines are reachable only via a system instructions sender.

## Augmentation

The instruction carries two fields the signer may populate per command:

1. `additionalFixedMessage`: Lies inside `TeeInstruction`, is part of [`instructionHash`](#hashes), and must be identical across all signers contributing to the same vote.
2. `additionalVariableMessage`: Lies alongside `TeeInstruction` in `data`, is hashed and signed separately, and may differ per signer.

Two system commands populate them via a per-command procedure run by the relay client:

- [`F_FDC2 PROVE`](../FDC2/Reference/Operations/Prove.md#augmentation-procedure)
- [`F_WALLET KEY_DATA_PROVIDER_RESTORE`](../Reference/Operations/F_WALLET.md#augmentation)

All other instructions — including every custom extension instruction — leave both fields empty.

## Hashes

`instructionId` is generated when the event is emitted and is identical for every signer relaying it.

$$
\mathrm{instructionId} = \mathrm{keccak256}(\mathrm{abi.encode}(\mathrm{extensionId},\ n,\ \mathrm{blockhash}(b - 1)))
$$

where $n$ is the number of previous instructions sent for the extension and $b$ is the emitting block number.

`instructionHash` is identical only across signers who agree on every field of `TeeInstruction`.

$$
\mathrm{instructionHash} = \mathrm{keccak256}(\mathrm{abi.encode}(\mathit{TeeInstruction}))
$$

`hashForSigning` is what the signer signs.

$$
\mathrm{hashForSigning} = \mathrm{keccak256}(\mathrm{instructionHash} \,\|\, \mathrm{keccak256}(\mathrm{additionalVariableMessage}))
$$
