# FlareTeeManager

The `FlareTeeManager` contract is the Flare-side hub of FCC: a [diamond](https://eips.ethereum.org/EIPS/eip-2535) contract whose facets manage [extensions](../../FCE/README.md), [TEE machines](../../Concepts/Machines.md#registration), [instructions](../../Concepts/Instructions.md), wallets and keys, attestation verification, and governance.

## Facets

Each concern is implemented as an independent facet:

- `InstructionsFacet`: instruction submission and system-instructions-sender registration.
- `ExtensionManagerFacet`: extension registration, per-extension contract updates, system-supported platforms and key types.
- `ExtensionGovernanceFacet`: per-extension governance signers and pausing addresses.
- `MachineManagerFacet`: TEE machine registration, status transitions, ownership.
- `VerificationFacet`: on-chain verification of TEE attestations and FDC2 proofs.
- `OperationFeesFacet`: per-operation fee configuration.
- `UpgradeManagerFacet`: TEE upgrade flow.
- `WalletManagerFacet`, `WalletKeyManagerFacet`, `WalletBackupManagerFacet`, `WalletResumeFacet`, `WalletProjectManagerFacet`: protocol-managed-wallet lifecycle.
- `VrfFacet`, `SystemStateVerifierFacet`, `ReplicationFacet`: VRF, state verification, and replication.
- `DiamondGovernanceFacet`, `OwnerAllowlistFacet`, `ExternalAddressesFacet`: governance and external-address plumbing.

Event signatures are listed under [`Types/Abi/Events/`](../Types/Abi/Events).

## Sending Instructions

`InstructionsFacet` exposes two entry points that emit a [`TeeInstructionsSent`](../Types/Abi/Events/TeeExtensionRegistry.md#teeinstructionssent) event after caller validation, payload validation, and fee collection:

- `sendInstructions(teeIds, instructionParams)`.
- `sendSystemInstructions(instructionId, teeMachines | teeIds, instructionParams)`: lets a system instructions sender supply an explicit `instructionId`.

### Caller Validation

For `sendInstructions`, `msg.sender` must satisfy one of:

- registered as a _system instructions sender_ (`Instructions.isSystemInstructionsSender(msg.sender)`): any op-type, any extension.
- equal to the destination extension's registered instructions sender (`ExtensionManager.getExtensionInstructionsSender(extensionId)`): non-[system op-types](../../FCE/Concepts.md#system-vs-custom-extensions) only (`F_` prefix forbidden).

The destination extension is determined by the first destination TEE machine (`MachineManager.getExtensionId(teeMachines[0].teeId)`).
All other destination TEE machines must belong to the same extension.

The [system extension](../../FCE/System.md) (`extensionId == 0`) cannot have its own registered instructions sender: `extensionsCounter` is initialized to $1$, so `register` never assigns id $0$, and `setExtensionContracts` rejects `_extensionId == 0`.
Its TEE machines are reachable only via a system instructions sender.

`sendSystemInstructions` requires `msg.sender` to be a system instructions sender.
The set is managed by [governance](../../../Terminology/Roles.md#governance) via `registerSystemInstructionsSenders` and `unregisterSystemInstructionsSenders`.

### Payload Validation

The library further enforces:

- at least one destination TEE machine.
- non-empty `opType`, `opCommand`, and `message`.
- $\mathrm{cosignersThreshold} \leq \mathrm{cosigners.length}$.
- all destination TEE machines belong to the same extension.
- for non-system op-types, every destination TEE machine is in `PRODUCTION` status.
- `msg.value` is at least the operation's calculated fee; the fee is forwarded to the reward manager for the current reward epoch.

### Event Field Origins

Fields of the emitted [`TeeInstructionsSent`](../Types/Abi/Events/TeeExtensionRegistry.md#teeinstructionssent) event:

| Field | Origin |
|---|---|
| `extensionId` | `MachineManager.getExtensionId(teeMachines[0].teeId)` — the extension owning the destination TEE machines. |
| `instructionId` | Auto-generated as $\mathrm{keccak256}(\mathrm{abi.encode}(\mathrm{extensionId},\ n,\ \mathrm{blockhash}(b - 1)))$ where $n$ is the per-extension counter and $b$ the emitting block number; or caller-supplied (only via `sendSystemInstructions`). See [Hashes](../../Concepts/Instructions.md#hashes). |
| `rewardEpochId` | `FlareSystemsManager.getCurrentRewardEpochId()` narrowed to `uint32`. |
| `teeMachines` | Caller argument (passed directly, or resolved from `teeIds` via `MachineManager.getTeeMachine`). |
| `opType` | Caller argument (`instructionParams.opType`). |
| `opCommand` | Caller argument (`instructionParams.opCommand`). |
| `message` | Caller argument (`instructionParams.message`). |
| `cosigners` | Caller argument (`instructionParams.cosigners`). |
| `cosignersThreshold` | Caller argument (`instructionParams.cosignersThreshold`). |
| `claimBackAddress` | Caller argument (`instructionParams.claimBackAddress`). |
| `fee` | `msg.value`, forwarded to the reward manager. |

Each [instructions sender](../../Concepts/Instructions.md#instructions-senders) contract defines how it derives the caller-argument fields from the call its own users make.
