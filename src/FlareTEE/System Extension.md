# System Extension
Each extension [ref extension] within FlareTEE is identified by a unique extensionID.
The *system extension* is the extension with extensionID $0$. This initial extension is implemented by Flare, and thus can take advantage of Flare's data providers to source additional compute and data provision resources. 
The system extension hosts two instructions [fact check: FTSO?], the Flare TEE Data Connector (FTDC) and the Protocol Managed Wallet (PMW) infrastructure.

## Flare TEE Data Connector
The FTDC is a TEE-based variant of the Flare Data Connector (FDC), Flare's enshrined oracle for validating and importing external data to Flare's EVM state. 
The FDC uses consensus among Flare's data providers to attest to external data; in the FTDC, this attestation is performed by one or more TEEs in response to instruction by the providers. More information on the FTDC can be found in [cite specific file].

In the context of FlareTEE, the FTDC serves two purposes: firstly, it is the system by which the state of a TEE is validated, ensuring that TEEs participating in operations on Flare are running the correctly specified code. 
Secondly, it offers latency advantages over the FDC, and thus may be preferable for some users seeking to use external data on the network.

## Protocol Managed Wallets
The PMWs are a system application on Flare facilitating the programmable assembly, signing, and execution of transactions on external blockchains via user calls made to smart contracts on Flare.
It is enabled by a combination of Flare's data providers, who monitor smart contract calls on Flare are assemble transaction instructions, and the TEE infrastructure, who store keys for wallets on other chains and thus are responsible for signing transactions.
The PMW infrastructure is described in detail here [ref own section].
