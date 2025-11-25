# Payments
Payments in the PMW infrastructure are handled via a dedicated `TeePayments` smart contract.
This contract receives user payment requests and submits them as an instruction to the `TeeInstructions` smart contract.
This page details the features and options of the payments system for PMWs.

## Payment Instructions
[diagram: life of payment instruction]
### User Experience
Payment instructions are sent by Flare users to the `TeePayments` contract using the `pay(payments)` function.
The argument `payment` has a preset structure for a PMW hosted on Flare but sending payments on an external chain $C$:

- `projectID`: The ID of the project the PMW is on.
- `walletID`: The ID of the wallet itself.
- `recipientAddress`: The address on chain $C$ to which the payment will be made.
- `amount`: The amount of units to be transferred. 
- `paymentReference`: The $32$-byte payment reference.
- `fee`: The transaction fee offered on chain $C$.

From a user perspective, this contract call is all that is required to send a transaction from their wallet, as the payments contract and Flare's data providers handle the required interaction with the FlareTEE infrastructure.
Note that if batching is enabled [reference], the user experience allows for multiple payments to be issued in a single transaction on $C$, with the user sending the payment instruction in quick succession on Flare.

### Underlying Machinery
Upon receiving a payment instruction, the `TeePayments` contract and data providers perform the following tasks:

1. The payments contract calls the `receivingTeesAndKeys(walletId)` function on the `TeeWalletManager` contract for the `walletID` from which the payment is to be sent. The wallet manager contract returns a list of TEE machines to which instructions should be sent.
2. The payments contract then forms and submits the instruction that will trigger the payment to the `TeeInstructions` contract. Included in the instruction is the list of TEE IDs to which the instruction should be sent and a binary encoded message (see below).
3. The data providers follow the process taking an instruction to a TEE action, with the action result containing the data needed to submit the signed payment transaction on chain $C$ made available at the TEE proxies.
4. The data providers [?] submit the signed payment on $C$.

In step 2, the instruction includes a binary encoded message.
The message is an encoding of the following information:

- `walletId`: The ID of the wallet from which the transaction is made.
- `teeIdKeyIdPairs`: The ID of the keys used to issue the transaction on $C$.
- `senderAddress`: The address on $C$ which the transaction is made from, read from the wallet.
- `recipientAddress`: The address on $C$ which the transaction is made to, read from the payment instruction.
- `amount`: The amount of funds to be said, read from the payment instruction.
- `fee`: The fee offered on chain $C$, read from the payment instruction.
- `paymentReference`: The payment reference on $C$, read from the payment instruction
- `nonce`: The batch nonce [ref batching], maintained per wallet.
- `subNonce`: The global sequence number of payments.
- `batchEndTs`: The batch end time, used if batch size is not reached.

## Batching
For transactions on underlying blockchains that support issuing multiple payments in a single transaction, this is also supported by the `TeePayments` contract.
This process is known as *batching*.
Batching is configured on a per-wallet basis, with two relevant settings:

- `batchSize`: Sets the maximum amount of payments that can be issued in a single batched transaction.
- `batchDurationSeconds`: Sets the maximum length of time for which transactions can be added to an open batch until no more transactions are included and the batched transactions are submitted.

When batching is enabled, each time a user submits a payment and there is no batch open, a new batch is opened.
All successive payment transactions are placed in the current batch until the batch size is reached or until the maximum batch duration has passed since the first transaction, whichever happens first.
At this point, the batch is closed and the batched payments are issued by the `TeePayments` contract as an instruction and the process proceeds as usual.

## Reissuance and Nullification
Although unlikely, payments issued by PMW addresses can fail.
This can occur when the offered fee is too low, or due to issues on the external chain.
Reissuance and nullification processes are in place to handle these situations.
Nullification refers to a cheap transaction that is always processed and consumes the blockchain nonce.

A reissue transaction is done by calling the function `reissue(data)`, with the input argument `data` consisting of:

- `walletId`: The wallet ID of the original transaction.
- `nonce`: The batch nonce of the payment instruction that is to be reissued.
- `firstSubNonce`: The sub nonce of the first transaction in the batch.
- The list of payment instructions in the batch identified by:
	- `recipientAddress`  
	- `amount`    
	- `paymentReference`    
	- `fee`.
- `fees`: The new fee offers, typically larger than before.
- `nullify`: Indicating whether the nullification transaction should be issued of a reissue.

### Checking Transaction Status
To help determine the possibility of unsuccessful payments, an FDC attestation request can be made to determine the status of a transaction.
Such an attestation request takes as input:

- `walletID`
- `nonce`

while the response of the attestation request includes:

- The input to the request.
- The data for the payment instruction.
- The amount spent, including the fee and the payment itself.
- The status of the transaction. This value can be successful or nullified, or some other status specific to the underlying chain.

The purpose of such a request is to prove that a payment was either nullified or reverted.