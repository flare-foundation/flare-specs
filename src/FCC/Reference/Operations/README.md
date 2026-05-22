# System Operations

This directory documents the _system operations_: those carrying the `F_` op-type prefix that every TEE machine processes regardless of which [FCE](../../FCE/README.md) it is registered to.
They cover TEE-machine infrastructure (registration, attestation, key custody, policy updates) and are available to any extension.

Each operation is processed either as a [_direct action_](../../Concepts/Actions.md#direct-actions) (issued by the [TEE proxy](../Components/Proxy.md) without voting) or an [_instruction action_](../../Concepts/Actions.md#instruction-actions) (issued by [signers](../../Concepts/Instructions.md#signers) and gated by [voting](../../Concepts/Voting.md)).

| opType | Action kind | Operations |
|---|---|---|
| [`F_REG`](F_REG.md)       | Instruction | [`TEE_ATTESTATION`](F_REG.md#tee_attestation) |
| [`F_GET`](F_GET.md)       | Direct      | [`TEE_INFO`](F_GET.md#tee_info), [`KEY_INFO`](F_GET.md#key_info), [`KEY_PROOF`](F_GET.md#key_proof), [`TEE_BACKUP`](F_GET.md#tee_backup) |
| [`F_POLICY`](F_POLICY.md) | Direct      | [`INITIALIZE_POLICY`](F_POLICY.md#initialize_policy), [`UPDATE_POLICY`](F_POLICY.md#update_policy) |
| [`F_WALLET`](F_WALLET.md) | Instruction | [`KEY_GENERATE`](F_WALLET.md#key_generate), [`KEY_DELETE`](F_WALLET.md#key_delete), [`KEY_DATA_PROVIDER_RESTORE`](F_WALLET.md#key_data_provider_restore), [`VRF`](F_WALLET.md#vrf) |

Each operation entry documents its event message (instruction operations) or action message (direct operations), its action result, and — for instruction operations — the validation rules the TEE machine enforces before executing.

## Application Operations

The [system extension](../../FCE/System.md) registers additional `F_`-prefixed operations for its own applications.
These are application operations rather than infrastructure, so they live alongside the application's spec:

- [PMW operations](../../PMW/Reference/Operations/README.md) — `F_XRP PAY`, `F_XRP REISSUE`.
- [FDC2 operations](../../FDC2/Reference/Operations/README.md) — `F_FDC2 PROVE`.

Custom [FCEs](../../FCE/README.md) register their own operations under non-`F_` op-type prefixes; those are defined and documented by each FCE and are out of scope for this directory.
