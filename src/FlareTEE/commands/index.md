# Command Reference

This page provides an index of all implemented TEE commands. Each command is identified by an operation type and command name pair, and is processed either as a *direct* command (initiated by the proxy) or an *instruction* command (initiated by data providers through the voting process).

## Implemented Commands

| Type | Command | Processor | Immediate Result | Description |
|------|---------|-----------|-----------------|-------------|
| `F_REG` | `TEE_ATTESTATION` | Instruction | Yes | Calculates the TEE attestation for a given challenge. |
| `F_WALLET` | `KEY_GENERATE` | Instruction | Yes | Triggers key generation on the TEE machine. |
| `F_WALLET` | `KEY_DELETE` | Instruction | Yes | Deletes a key from the TEE machine. |
| `F_WALLET` | `KEY_DATA_PROVIDER_RESTORE` | Instruction | Yes | Initializes key restoration from a backup. |
| `F_WALLET` | `VRF` | Instruction | Yes | Generates a verifiable randomness proof. |
| `F_GET` | `KEY_INFO` | Direct | — | Returns information about all keys on the TEE machine. |
| `F_GET` | `TEE_BACKUP` | Direct | — | Returns the latest backup package. |
| `F_GET` | `TEE_INFO` | Direct | — | Calculates TEE attestation for a given challenge. |
| `F_POLICY` | `INITIALIZE_POLICY` | Direct | — | Initializes the signing policy on the TEE. |
| `F_POLICY` | `UPDATE_POLICY` | Direct | — | Updates the signing policy on the TEE. |
| `F_XRP` | `PAY` | Instruction | No | Issues an XRP multisig payment transaction. |
| `F_XRP` | `REISSUE` | Instruction | No | Reissues an XRP transaction. |
| `F_FDC2` | `PROVE` | Instruction | Yes | Collects signatures for an attestation response. |

## Command Processing

Commands are routed based on their operation type:

- **Direct commands** (`F_GET`, `F_POLICY`) are created internally by the TEE proxy and placed in the direct processing queue. They do not go through the voting process.
- **Instruction commands** (`F_REG`, `F_WALLET`, `F_XRP`, `F_FDC2`) are submitted by data providers, go through the [voting process](../Operations/Voting.md), and are queued as actions once the signing threshold is reached.

Commands with *immediate result* set to Yes return their result synchronously as part of the action response. Commands with immediate result set to No (such as XRP payment operations) initiate an asynchronous process whose result must be checked separately.

