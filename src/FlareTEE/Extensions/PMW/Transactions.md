# Payments
Payments in the PMW infrastructure are handled via a dedicated `TeePayments` smart contract.
This contract receives user payment requests, parsing and submitting them as an [instruction](Instructions.md) to the `TeeInstructions` smart contract.
This page details the features and options of the payments system for PMWs.

## Payment Instructions
[diagram: life of payment instruction]
### User Experience
Payment instructions are sent by Flare users to the `TeePayments` contract using the `pay(account, paymentInstruction)` function.
The `account` argument describes the account on the external blockchain as:

- `sourceId`: Identifier of the external chain.
- `accountAddress`: String denoting the account address from which the transaction is made.

The `paymentInstruction` argument describes the payment itself:

- `recipientAddress`: The address on chain $C$ to which the payment will be made.
- `tokenId`: Token identifier (`bytes32`). Currently unused, reserved for future token support.
- `amount`: The amount of units to be transferred.
- `fee`: The transaction fee offered on chain $C$.
- `paymentReference`: The $32$-byte payment reference.

From a user perspective, this contract call is all that is required to send a transaction from their wallet.
The payments contract and Flare's data providers handle the required interaction with the Flare Confidential Compute infrastructure.
Note that if batching is enabled (see below), the user experience allows for multiple payments to be issued in a single transaction on $C$, with the user sending the payment instructions in quick succession on Flare.

### Underlying Machinery
Upon receiving a payment instruction `pay(account, paymentInstruction)`, the `TeePayments` contract and data providers perform the following tasks:

1. The payments contract calls the `receivingTeesAndKeys(walletId)` function on the `TeeWalletManager` contract for the default project's wallet from which the payment is to be sent. This returns a list of TEE machines to which instructions should be sent.
2. The payments contract then forms and submits the instruction `paymentInstruction` that sends the payment to the `TeeInstructions` contract. The format of this instruction is listed below.
3. The data providers and TEEs follow the usual process from an instruction to an [action](Actions.md), with the action result containing the data necessary to submit the signed payment transaction on chain $C$ made available at the relevant TEE proxies.
4. The signed payment instruction can now be submitted on $C$ by any entity.

In step 2, the `paymentInstruction` is a binary encoded message.
The message is an encoding containing the following information, which can be read from the payment instruction and wallet settings:

- `walletId`: The ID of the wallet from which the transaction originates.
- `teeIdKeyIdPairs`: The ID of the keys used to sign the transaction and the ID of the TEEs that hold the keys.
- `senderAddress`: The address on $C$ from which the transaction will be sent.
- `recipientAddress`: The recipient address for the transaction on $C$.
- `amount`: The amount of funds to be sent.
- `fee`: The fee offered on chain $C$.
- `paymentReference`: The payment reference on $C$.
- `nonce`: The batch nonce, maintained per wallet.
- `subNonce`: The global sequence number of payments.
- `batchEndTs`: The batch end time, used if batch size is not reached.

##  Batching and Transaction Settings
Certain blockchains support issuing multiple payments in a single transaction.
For PMWs issuing transactions on these blockchains, this is supported by the `TeePayments` contract.
The process is known as *batching*.
Batching is configured on a per-wallet basis by the wallet owner, alongside other relevant transaction settings.
The following settings can be set:

- `batchSize`: Sets the maximum amount of payments that can be issued in a single batched transaction.
- `batchDurationSeconds`: Sets the maximum length of time, measured in seconds, for which transactions can be added to an open batch until no more transactions are included and the batched transactions are submitted.
-  `minFee`: Sets the minimal transaction fee required for payments from the wallet.
- `senderAddress`: Sets the address from which payments will be made on the external chain.
- `initialNonce`: Sets the starting nonce for wallet transactions.

When batching is enabled, each time a user submits a payment and there is no batch open, a new batch is opened.
All successive payment transactions are placed in the current batch until the batch size is reached or until the maximum batch duration has passed since the first transaction, whichever happens first.
At this point, the batch is closed and the batched payments are issued by the `TeePayments` contract as an instruction and the process proceeds as usual.

> **Note on Batches and Reward Epochs:** To prevent ambiguity in the use of signing policies, a batch started in one reward epoch that would otherwise extend into the next reward epoch is prematurely closed at the end of the current reward epoch.
### Batching Example
- A transaction $T_0$ arrives at time $t$ seconds while there is no open batch. The wallet settings are such that the maximum batch size is $S$ and batches are open for a maximum of $d$ seconds.
- A batch $B = (\mathrm{T}_\mathrm{list}, t)$ is initialized, with the initial set of transactions set to $\mathrm{T}_\mathrm{list} = (T_0)$.
- Until time $t + d$, each time a transaction $T_i$ arrives the set of transactions in $B$ is updated to $\mathrm{T}_\mathrm{list} = (T_0, \dots, T_i)$. Then, if the amount of transactions has reached the maximum batch size, $\vert \mathrm{T}_\mathrm{list} \vert =S$, the batch is closed and the batch of payment instructions is issued as an action instruction.
- This process continues until time $t +d$, at which point the transactions $(T_0, \dots, T_i)$ in the batch are issued even if 
$\vert \mathrm{T}_\mathrm{list} \vert  < S$.

## Reissuance and Nullification
Although unlikely, payments issued by PMW addresses can fail.
For example, payments may fail when the offered fee is too low or due to issues on the external chain.
*Reissuance* and *nullification* processes are in place to handle these situations.
Nullification refers to a cheap transaction that is always processed and consumes the blockchain nonce.

A reissue transaction is issued by calling the function `reissue(data)` at the `teePayments` contract, with the input argument `data` consisting of:

- `walletId`: The wallet ID of the original transaction.
- `nonce`: The batch nonce of the payment instruction that is to be reissued.
- `firstSubNonce`: The sub nonce of the first transaction in the batch.
- The list of payment instructions in the batch identified by:
	- `recipientAddress`  
	- `amount`    
	- `paymentReference`    
	- `fee`.
- `fees`: The new fee offer(s), typically larger than before.
- `nullify`: A flag indicating whether a regular reissue transaction should be sent or a nullification transaction instead.

### Checking Transaction Status
To help determine the possibility of unsuccessful payments, an FDC attestation type is available to to determine the status of a transaction.
Such an attestation request takes as input:

- `walletID`
- `nonce`

while the response of the attestation request includes:

- The input to the request.
- The data for the payment instruction.
- The amount spent, including the fee and the payment itself.
- The status of the transaction. This value can be successful or nullified, or some other status specific to the underlying chain.

The purpose of such a request is to prove that a payment was either nullified or reverted.[more detail tbd]