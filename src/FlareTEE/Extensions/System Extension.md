# System Extension
Each [extension](Extensions.md) within Flare Confidential Compute is identified by a unique extension ID.
The *system extension* is the extension with extension ID $0$. This initial extension is implemented by Flare.
The system extension takes advantage of Flare's data providers to source additional compute and data provision resources.
The system extension hosts two system applications, each with a variety of instructions: the Flare Data Connector v2 (FDC2) and the Protocol Managed Wallet (PMW) infrastructure.

## System vs. Custom Extension Management

Unlike custom extensions (FCE), which are defined and managed by Flare's users, the system extension is implemented and maintained by Flare governance itself.
Its code versions, instruction senders, and supported key types are managed at the system level via dedicated functions on the `TeeExtensionRegistry` contract:

- `addSystemSupportedPlatforms(platforms)` — registers new hardware platforms (e.g., `SEV`, `TDX`).
- `addSystemSupportedKeyTypesAndSigningAlgos(keyTypes, signingAlgos)` — registers supported key types (`EVM`, `XRP`) and signing algorithms (`keccak256-secp256k1-ecdsa`, `sha512half-secp256k1-ecdsa`, `keccak256-secp256k1-vrf`).
- `registerSystemInstructionsSenders(instructionsSenders)` — whitelists smart contracts that can send system instructions (e.g., `TeeWalletKeyManager`, `TeePayments`, `Fdc2Hub`).
- `unregisterSystemInstructionsSenders(instructionsSenders)` — removes instruction sender contracts.

Custom extensions use the per-extension equivalents of these functions (`addTeeVersion`, `addSupportedKeyTypes`, etc.) and operate independently of the system extension's applications.

## Operation Type Prefix

System operations are distinguished by the `F_` prefix in their operation type. The `TeeExtensionRegistry` contract enforces that `F_`-prefixed operations can only be sent from extension ID $0$. Custom extensions cannot use this prefix.

The system operation types are:

| Operation Type | Description |
|---|---|
| `F_REG` | TEE machine registration and attestation |
| `F_WALLET` | Wallet key management (generate, delete, restore, VRF) |
| `F_GET` | TEE queries (key info, TEE info, backup) |
| `F_POLICY` | Signing policy management (initialize, update) |
| `F_XRP` | XRP payment and reissue operations |
| `F_FDC2` | FDC2 attestation proof generation |

## TEE Node Routing

TEE machines running the system extension use the `PMWRouter`, which only registers dedicated processors for system operations. Unrecognized operations return an error.

TEE machines running custom extensions use the `ForwardRouter`, which registers the same system processors but additionally forwards unrecognized operations to the extension service via HTTP on a configured port.

## Flare Data Connector v2 (FDC2)
The FDC2 is a TEE-based variant of the Flare Data Connector (FDC), Flare's enshrined oracle for validating and importing external data to Flare's EVM state.
The FDC uses consensus among Flare's data providers to attest to external data.
In the FDC2, this attestation is performed by data providers and then validated by TEEs in response to instruction by the providers.
More information on the FDC2 can be found in its own [specification](FTDC.md).

In the context of Flare Confidential Compute, the FDC2 serves two purposes: firstly, it is the system by which the state of a TEE machine is validated, ensuring that TEEs participating in operations on Flare are running the correctly specified code and state.
Secondly, it offers latency advantages over the FDC, and thus may be preferable for some users who would otherwise want to use the FDC.

The FDC2 currently supports four attestation types:

1. **TeeAvailabilityCheck** — verifies that a TEE machine is available, running valid code, and has a fresh platform attestation.
2. **PMWPaymentStatus** — verifies the status of a payment transaction on an external chain.
3. **PMWMultisigAccountConfigured** — proves that a multisig account on an external chain is correctly configured.
4. **PMWFeeProof** — provides accurate fee accounting across a range of payment nonces.

For details, see the [attestation types](../attestation-types/) documentation.

## Protocol Managed Wallets
Protocol managed wallets are a system application on Flare facilitating the programmable assembly, signing, and execution of transactions on external blockchains via user calls made to smart contracts on Flare.
Essentially, the PMW infrastructure allows Flare's users to manage wallets on external blockchains by sending instructions on Flare.
It is enabled by a combination of the TEE network, which stores keys for wallets on other chains and is responsible for signing transactions, and Flare's data providers, who monitor transaction instructions on Flare and relay information between Flare, the TEEs, and external chains.
The PMW infrastructure is described in detail in its [own section](PMW/PMW.md).
