# Payments
Payments in the PMW infrastructure are handled via a dedicated `TeePayments` smart contract.
This contract receives user payment requests, parsing and submitting them as an [instruction](../../Operations/Instructions.md) to the `TeeInstructions` smart contract.
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
3. The data providers and TEEs follow the usual process from an instruction to an [action](../../Operations/Actions.md), with the action result containing the data necessary to submit the signed payment transaction on chain $C$ made available at the relevant TEE proxies.
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

## Fee Scheduling

The payment system supports *progressive fee escalation*.
When a payment instruction is sent to a TEE machine, it includes a *fee schedule* — a list of fee entries, each specifying a fee factor and a time delay.
The TEE machine signs transactions for all fee entries upfront and posts the results to the proxy progressively according to the delay schedule.
If the first transaction is not confirmed on the external chain, higher-fee versions become available automatically.

### Fee Schedule Format

The fee schedule is a binary-encoded byte array.
Each entry is $4$ bytes:

| Bytes | Type | Description |
|---|---|---|
| $0$–$1$ | `int16` (big-endian) | Fee factor in BIPS ($-10000$ to $+10000$, non-zero). |
| $2$–$3$ | `uint16` (big-endian) | Delay in seconds from the start of processing. |

Entries must have strictly ascending delays.

### Fee Calculation

For each entry, the transaction fee is computed as:

$$\mathrm{fee} = \dfrac{|\mathrm{factorBIPS}| \times \mathrm{maxFee}}{10000}$$

where `maxFee` is the maximum fee specified in the payment instruction.

### Nullification

A negative `factorBIPS` value triggers a *nullification*: the TEE signs an `AccountSet` transaction instead of a `Payment` transaction.
This consumes the blockchain nonce without transferring funds.
Nullification is used to cancel a stuck payment.

### Default Fee Schedule

If no custom fee schedule is set for an account, the default schedule is used:

```
0x27100000
```

This decodes to a single entry: $10000$ BIPS ($100\%$ of `maxFee`) at $0$ seconds delay.

### Configuration

The wallet owner sets a persistent fee schedule per account via `TeePayments.setFeeSchedule()`:

**Parameters:**
- `account` (`PMWMultisigAccount`) — the multisig account.
- `factorsBIPS` (`int16[]`) — fee factors in BIPS for each schedule entry.
- `delaysSeconds` (`uint16[]`) — corresponding delays in seconds (strictly ascending).

The schedule is stored on-chain and applied to all subsequent payment batches for the account.

**Events emitted:** [`FeeScheduleSet`](../../Events.md#feescheduleset)

### TEE Processing

When the TEE machine receives a payment instruction with a fee schedule:

1. All fee entries are signed upfront — one XRPL transaction per entry.
2. A background process posts the signed transactions to the proxy progressively, each after its configured delay.
3. Intermediate results use status $3$, $4$, $5$, etc. (one per non-final entry).
The final result uses status $1$.
4. Each result is cumulative — it includes all transactions from the first entry up to and including the current one.

### Reissue Override

When reissuing a failed payment via `TeePayments.reissue()`, the caller can override the fee schedule per instruction using `ReissueFeeParams`:

- `maxFees` (`uint256[]`) — new maximum fees, one per instruction.
- `feeFactorScheduleBIPS` (`int16[][]`) — per-instruction fee factor schedules.
- `feeDelayScheduleSeconds` (`uint16[]`) — shared delay schedule across all instructions in the batch.

If `feeFactorScheduleBIPS` is empty, the account's stored fee schedule (or the default) is used.

## Reissuance and Nullification

Payments issued by PMW addresses can fail, for example when the offered fee is too low or due to issues on the external chain.
*Reissuance* re-submits the payment instruction with updated fee parameters.
*Nullification* submits a cheap transaction that consumes the blockchain nonce without transferring funds.

A reissue is triggered by calling `TeePayments.reissue()`.
For the full parameter list, see the [xrp-payment workflow](../../workflows/xrp-payment.md).

Nullification is achieved by setting a negative `factorBIPS` in the fee schedule (see [Fee Scheduling](#fee-scheduling) above).

### Checking Transaction Status

The [`PMWPaymentStatus`](../../attestation-types/PMWPaymentStatus.md) FDC2 attestation type verifies the status of a payment on the external chain.
The response includes the transaction status (success or reverted), the received amount, the transaction fee, and the revert reason if applicable.
