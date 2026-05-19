# PMW Concepts

A Protocol Managed Wallet (PMW) is an application running on Flare that manages a wallet address on an external blockchain.
PMWs allow Flare users to submit transactions from the wallet on the external chain by issuing an instruction on Flare Confidential Compute.
They are hosted on the [system extension](../SystemExtension.md) of Confidential Compute, making use of the TEE network to secure the wallet and its underlying keys.
Additional support is given by Flare's [data providers](../../../Terminology/Roles.md#data-provider), who are responsible for bridging information between Flare, the TEE network, and the external chain.

## Wallet Ownership and Management

A PMW wallet corresponds to an address $W_C$ on an external blockchain $C$; its keys are held in TEE machines registered to the system extension, and the [project owner](../../../Terminology/Roles.md#project-owner) can order transactions on $C$ by issuing instructions on Flare.
For the on-chain data model behind PMW wallets — projects, wallets, admins, cosigners, multisig thresholds, and the wallet lifecycle — see [Wallets](../../TeeManagement/Wallets.md).

## Submitting Transactions

A transaction on a PMW is an example of an [instruction](../../Operations/Instructions.md), and thus follows a similar flow: a user who owns a PMW issues a transaction instruction on Flare, which is picked up by Flare's data providers.
The data providers prepare the transaction, which is sent to the TEE machine to be signed.
Once signed, the transaction can be fetched from the TEE proxy and submitted on the external chain.
A transaction proceeds as follows:

1. A Flare user owns a PMW managing an account $W_C$ on blockchain $C$. They submit an instruction on Flare instructing a transaction $T$ be issued on blockchain $C$ from account $W_C$. The instruction includes all information necessary for the data providers to assemble $T$, including a list of TEEs on which the appropriate keys are stored.
2. Upon picking up the payment instruction, Flare's data providers each independently assemble an instruction corresponding to the transaction $T_{\mathrm{TEE}}$. The data providers then sign the instruction and submit it to the appropriate TEE(s).
3. Once a TEE has received a sufficient weight of signatures, the TEE signs the transaction $T$ using key(s) stored in its memory and returns the signed transaction to the TEE proxy.
4. The transaction $T$, signed by address $W_C$, is now available at the TEE proxy to be fetched and submitted on chain $C$.

## Key Management and Backups

Since transactions are sent to the TEEs to be signed, keys stored on TEEs participating in the PMW protocol do not leave the TEEs' secure memory.
Thus, PMW transactions issued as instructions on Flare are secured by the combination of the TEE machines and the voting process on the system extension.
In order to ensure keys are not inaccessible or lost in instances where TEEs are either temporarily or permanently disabled, keys are securely [backed up](../../TeeManagement/Keys.md) using a secret sharing scheme.
The key shares are distributed to other participating TEEs and cosigners in a manner that ensures that secrets can only be recovered in appropriate circumstances.
Additionally, TEEs provide `TEEKeyExistence` proofs to confirm the existence of keys corresponding to appropriate wallets.

## Functionality

PMW handles these functions by implementing the following specific functionalities:

1. **Multisig account operations**: The PMW infrastructure leverages native multisig capabilities of external blockchains (XRPL). A wallet represents a set of multiple keys on different TEE machines, which are signers on $k$-of-$n$ native multisig accounts on external blockchains.
2. **Nonce (transaction sequence) management**: Careful management guarantees that each payment instruction can be issued with a particular nonce only.
3. **Reissuance or nullification**: A stuck transaction with a specific nonce can be reissued with the same data on a different (higher) fee, or nullified by a trivial transaction that consumes the nonce at minimal cost.
4. **Proving transaction execution status**: A proof of execution status through an FDC attestation can be obtained once the nonce is consumed, allowing protocols to verify payment outcomes and handle errors automatically.

> **Note:** BTC support is planned but not yet implemented.
