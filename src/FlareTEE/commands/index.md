# Command Reference

This page provides an index of all implemented TEE commands. Each command is identified by an operation type and command name pair, and is processed either as a *direct* command (initiated by the proxy) or an *instruction* command (initiated by data providers through the voting process).

## Implemented Commands

| Type | Command | Processor | Description |
|------|---------|-----------|-------------|
| `F_REG` | [`TEE_ATTESTATION`](F_REG--TEE_ATTESTATION.md) | Instruction | Calculates the TEE attestation for a given challenge. |
| `F_WALLET` | [`KEY_GENERATE`](F_WALLET--KEY_GENERATE.md) | Instruction | Triggers key generation on the TEE machine. |
| `F_WALLET` | [`KEY_DELETE`](F_WALLET--KEY_DELETE.md) | Instruction | Deletes a key from the TEE machine. |
| `F_WALLET` | [`KEY_DATA_PROVIDER_RESTORE`](F_WALLET--KEY_DATA_PROVIDER_RESTORE.md) | Instruction | Restores a previously backed-up key onto a target TEE machine. |
| `F_WALLET` | [`VRF`](F_WALLET--VRF.md) | Instruction | Generates a verifiable randomness proof. |
| `F_GET` | [`KEY_INFO`](F_GET--KEY_INFO.md) | Direct | Returns signed `KeyExistence` proofs for all keys on the TEE machine. |
| `F_GET` | [`TEE_BACKUP`](F_GET--TEE_BACKUP.md) | Direct | Returns the latest backup package for a specific key. |
| `F_GET` | [`TEE_INFO`](F_GET--TEE_INFO.md) | Direct | Returns TEE attestation and machine data for a proxy-provided challenge. |
| `F_POLICY` | [`INITIALIZE_POLICY`](F_POLICY--INITIALIZE_POLICY.md) | Direct | Initializes the signing policy on the TEE. |
| `F_POLICY` | [`UPDATE_POLICY`](F_POLICY--UPDATE_POLICY.md) | Direct | Updates the signing policy on the TEE. |
| `F_XRP` | [`PAY`](F_XRP--PAY.md) | Instruction | Signs an XRP Ledger multisig payment transaction using TEE-managed keys. |
| `F_XRP` | [`REISSUE`](F_XRP--REISSUE.md) | Instruction | Re-signs a previously issued XRP payment for resubmission. |
| `F_FDC2` | [`PROVE`](F_FDC2--PROVE.md) | Instruction | Processes an FDC2 attestation request, collecting data-provider signatures and producing a signed proof. |

