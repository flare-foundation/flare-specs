# System Extension

The _system extension_ is the [FCE](Concepts.md) with `extensionId = 0`.
It is implemented and maintained by Flare itself, and hosts two applications: the [Flare TEE Data Connector v2 (FDC2)](../FDC2/README.md) and the [Protocol Managed Wallet (PMW)](../PMW/README.md) infrastructure.
Both leverage Flare's [data providers](../../Terminology/Roles.md#data-provider) for additional compute and data provision.

Its code versions, instructions sender, and supported key types are managed at the system level via the [governance-only calls](Concepts.md#governance-system-extension-only) on `FlareTeeManager`.
Custom extensions use the per-extension equivalents and operate independently.

## Operation Types

System operations are distinguished by the `F_` prefix in their `opType`.
The `FlareTeeManager` contract enforces that `F_`-prefixed operations can only be sent by the system extension's instructions sender or by a [system instructions sender](Concepts.md#instructions-senders); custom extensions cannot use this prefix.

| Operation Type | Description |
|---|---|
| `F_REG`    | TEE machine [registration and attestation](../Concepts/Machines.md). |
| `F_WALLET` | Wallet [key management](../Concepts/Keys.md) (generate, delete, restore, VRF). |
| `F_GET`    | TEE proxy queries (key info, key proof, TEE info, backup). |
| `F_POLICY` | [Signing policy](../../FSP/SigningPolicy.md) initialization and updates. |
| `F_XRP`    | XRP payment and reissue operations. |
| `F_FDC2`   | FDC2 attestation proof generation. |

Command references live under [Operations/System](../Reference/Operations/README.md) (infrastructure operations) and the application-specific directories under [PMW/Commands](../PMW/Reference/Operations/README.md) and [FDC2/Commands](../FDC2/Reference/Operations/README.md).

## FDC2

The FDC2 is a TEE-based variant of the [Flare Data Connector](../../FDC/Introduction.md), Flare's enshrined oracle for validating external data on-chain.
Where the FDC uses on-chain bit voting between data providers, FDC2 has providers vote by signing attestation responses and submitting them to participating TEE machines; once the vote threshold is reached, the TEE signs the response with its identity key and the proof is served by the [TEE proxy](../Reference/Components/Proxy.md).

In FCC, FDC2 serves two purposes:

- Validates TEE machine state (code hash, signing policies) on registration and continued operation.
- Offers lower latency than the FDC for users who would otherwise use it.

See the [FDC2 spec](../FDC2/README.md) for the full protocol.

## PMW

The PMW infrastructure lets Flare users issue transactions on external blockchains (currently XRPL; BTC and EVM chains planned) via instructions on Flare.
TEE machines registered to the system extension custody the wallet keys and sign transactions; data providers bridge data between Flare, the TEE network, and the external chain.

See the [PMW spec](../PMW/README.md) for the full protocol.
