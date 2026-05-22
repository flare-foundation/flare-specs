# Commands

This directory documents the _system commands_: commands carrying the `F_` op-type prefix that every TEE machine processes regardless of which [FCE](../../Extensions/README.md) it is registered to.
They cover TEE-machine infrastructure (registration, attestation, key custody, policy updates) and are available to any extension.

Each command is processed either as a [_direct action_](../Actions.md#direct-actions) (issued by the [TEE proxy](../../Components/TeeProxy.md) without voting) or an [_instruction action_](../Actions.md#instruction-actions) (issued by [signers](../Instructions.md#signers) and gated by [voting](../Voting.md)).

Each leaf page documents one `(opType, opCommand)` pair with its `Event message` (instruction actions) or `Action message` (direct actions), `Action result`, and — for instruction actions — `Validation` rules the TEE machine enforces before executing.

| `opType` | Subdirectory | Commands |
|---|---|---|
| `F_REG` | [`F_REG/`](F_REG/) | [`TEE_ATTESTATION`](F_REG/TeeAttestation.md) |
| `F_GET` | [`F_GET/`](F_GET/) | [`KEY_INFO`](F_GET/KeyInfo.md), [`KEY_PROOF`](F_GET/KeyProof.md), [`TEE_BACKUP`](F_GET/TeeBackup.md), [`TEE_INFO`](F_GET/TeeInfo.md) |
| `F_POLICY` | [`F_POLICY/`](F_POLICY/) | [`INITIALIZE_POLICY`](F_POLICY/InitializePolicy.md), [`UPDATE_POLICY`](F_POLICY/UpdatePolicy.md) |
| `F_WALLET` | [`F_WALLET/`](F_WALLET/) | [`KEY_GENERATE`](F_WALLET/KeyGenerate.md), [`KEY_DELETE`](F_WALLET/KeyDelete.md), [`KEY_DATA_PROVIDER_RESTORE`](F_WALLET/KeyDataProviderRestore.md), [`VRF`](F_WALLET/Vrf.md) |

## Extension-Specific Commands

The [system extension](../../Extensions/SystemExtension.md) registers additional commands for its own applications.
These are not part of the infrastructure set above; they live alongside the application's spec:

- [PMW commands](../../Extensions/PMW/Commands/README.md) — `F_XRP PAY`, `F_XRP REISSUE`.
- [FDC2 commands](../../Extensions/FDC2/Commands/README.md) — `F_FDC2 PROVE`.

A custom [FCE](../../Extensions/README.md) may register its own commands under any non-`F_` op-type prefix.
Documenting them in this directory is reserved for the system extension and infrastructure commands; per-FCE commands belong with that FCE's spec.
