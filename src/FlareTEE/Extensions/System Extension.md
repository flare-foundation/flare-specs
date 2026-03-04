# System Extension
Each [extension](Extension.md) within Flare Confidential Compute is identified by a unique extensionID.
The *system extension* is the extension with extensionID $0$. This initial extension is implemented by Flare.
The system extension takes advantage of Flare's data providers to source additional compute and data provision resources. 
The system extension hosts two system applications, each with a variety of instructions: the Flare TEE Data Connector (FTDC) and the Protocol Managed Wallet (PMW) infrastructure.

Unlike FCE extensions, which are defined and managed by Flare's users, the system extension is implemented and maintained by Flare itself. 
Its code versions, instruction senders, and supported key types are managed at the system level via dedicated functions on the `TeeExtensionRegistry` contract. 
Custom extensions use the per-extension equivalents of these functions and operate independently of the system extension's applications.

## Flare TEE Data Connector
The FTDC is a TEE-based variant of the Flare Data Connector (FDC), Flare's enshrined oracle for validating and importing external data to Flare's EVM state. 
The FDC uses consensus among Flare's data providers to attest to external data.
In the FTDC, this attestation is performed by data providers then validated by TEEs in response to instruction by the providers.
More information on the FTDC can be found in its own [file](FTDC.md).

In the context of Flare Confidential Compute the FTDC serves two purposes: firstly, it is the system by which the state of a TEE machine is validated, ensuring that TEEs participating in operations on Flare are running the correctly specified code and state. 
Secondly, it offers latency advantages over the FDC, and thus may be preferable for some users who would otherwise want to use the FDC.

## Protocol Managed Wallets
Protocol managed wallets are a system application on Flare facilitating the programmable assembly, signing, and execution of transactions on external blockchains via user calls made to smart contracts on Flare.
Essentially, the PMW infrastructure allows Flare's users to manage wallets on external blockchains by sending instructions on Flare.
It is enabled by a combination of the TEE network, which stores keys for wallets on other chains and is responsible for signing transactions, and Flare's data providers, who monitor transactions instructions on Flare and relay information between Flare, the TEEs, and external chains.
The PMW infrastructure is described in detail in its [own section](PMW.md).