# Command Reference

This page provides an index of all implemented TEE commands. Each command is identified by an operation type and command name pair, and is processed either as a *direct* command (initiated by the proxy) or an *instruction* command (initiated by data providers through the voting process).

## Implemented Commands

| Type | Command | Processor | Immediate Result | Description |
|------|---------|-----------|-----------------|-------------|
| `F_REG` | [`TEE_ATTESTATION`](F_REG--TEE_ATTESTATION.md) | Instruction | Yes | Calculates the TEE attestation for a given challenge. |
| `F_WALLET` | [`KEY_GENERATE`](F_WALLET--KEY_GENERATE.md) | Instruction | Yes | Triggers key generation on the TEE machine. |
| `F_WALLET` | [`KEY_DELETE`](F_WALLET--KEY_DELETE.md) | Instruction | Yes | Deletes a key from the TEE machine. |
| `F_WALLET` | [`KEY_DATA_PROVIDER_RESTORE`](F_WALLET--KEY_DATA_PROVIDER_RESTORE.md) | Instruction | Yes | Initializes key restoration from a backup. |
| `F_WALLET` | [`VRF`](F_WALLET--VRF.md) | Instruction | Yes | Generates a verifiable randomness proof. |
| `F_GET` | [`KEY_INFO`](F_GET--KEY_INFO.md) | Direct | — | Returns information about all keys on the TEE machine. |
| `F_GET` | [`TEE_BACKUP`](F_GET--TEE_BACKUP.md) | Direct | — | Returns the latest backup package. |
| `F_GET` | [`TEE_INFO`](F_GET--TEE_INFO.md) | Direct | — | Calculates TEE attestation for a given challenge. |
| `F_POLICY` | [`INITIALIZE_POLICY`](F_POLICY--INITIALIZE_POLICY.md) | Direct | — | Initializes the signing policy on the TEE. |
| `F_POLICY` | [`UPDATE_POLICY`](F_POLICY--UPDATE_POLICY.md) | Direct | — | Updates the signing policy on the TEE. |
| `F_XRP` | [`PAY`](F_XRP--PAY.md) | Instruction | No | Issues an XRP multisig payment transaction. |
| `F_XRP` | [`REISSUE`](F_XRP--REISSUE.md) | Instruction | No | Reissues an XRP transaction. |
| `F_FDC2` | [`PROVE`](F_FDC2--PROVE.md) | Instruction | Yes | Collects signatures for an attestation response. |

## Command Processing

Commands are routed based on their operation type:

- **Direct commands** (`F_GET`, `F_POLICY`) are created internally by the TEE proxy and placed in the direct processing queue. They do not go through the voting process.
- **Instruction commands** (`F_REG`, `F_WALLET`, `F_XRP`, `F_FDC2`) are submitted by data providers, go through the [voting process](../Operations/Voting.md), and are queued as actions once the signing threshold is reached.

Commands with *immediate result* set to Yes return their result synchronously as part of the action response. Commands with immediate result set to No (such as XRP payment operations) initiate an asynchronous process whose result must be checked separately.

