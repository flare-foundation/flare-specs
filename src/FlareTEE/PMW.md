# Protocol Managed Wallet
A Protocol Managed Wallet is an application running on Flare that can be used to manage a wallet on an external blockchain. In particular, a Flare user can submit transactions from the wallet on the external chain by issuing an instruction on FlareTEE. They are hosted on the system extension of FlareTEE, and use the TEE network to secure the wallet, handling the underlying keys that control the addresses. Additional support is given by Flare's data providers who are responsible for bridging information between Flare, the TEE network, and the external chain. This section documents the design and features of the PMW infrastructure.

## Overview 
The remainder of this file contains overviews of various aspects of the PMW infrastructure, more details of which can be found in their separate files.

### Wallet Owernship and Management

### Submitting Transactions
A transaction on a PMW is an example of an instruction, and thus follows a similar flow: a user who owns a PMW issues a transaction instruction on Flare, which is picked up by Flare's data providers. The data providers prepare the transaction, which is sent to the TEE to be signed. Once signed, the transaction can be fetched from the TEE proxy and submitted on the external chain. A transaction proceeds as follows:

1. A Flare user who owns a PMW $W_C$ on a blockchain $C$. submits an instruction on Flare instructing a transaction $T$ be issued on blockchain $C$ from account $W_C$. The instruction includes all information necessary for the data providers to assemble $T$, including a list of TEEs on which the appropriate keys are stored.
2.  Upon  picking  up  the  payment  instruction,  Flare?s  data  providers  each  independently assemble a TEE instruction corresponding to the transaction $T_{TEE}$. The  data  providers  then  sign  instruction and submit it to the appropriate TEE(s). 
3.  Once  a  TEE  has  received  sufficient  weight  of  signatures, the  TEE  signs the transaction $T$ using keys stored in its memory and return the signed transaction to the TEE proxy. 
4. The signed transaction $T$ is now available at the TEE proxy to be submitted on chain $C$.

### Key Management and Backups