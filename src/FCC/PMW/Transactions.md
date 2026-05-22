# Payments

PMW payments are submitted on Flare and executed on an external chain by the [TEE machines](../Reference/Components/Machine.md) holding the wallet's keys.
The `TeePayments` contract receives requests, expands them into [`PaymentInstructionMessage`](Reference/Types/Payment.md#paymentinstructionmessage) payloads, and submits them as [`F_XRP PAY`](Reference/Operations/Pay.md) (or [`F_XRP REISSUE`](Reference/Operations/Reissue.md)) [instructions](../Concepts/Instructions.md) via [`FlareTeeManager.sendInstructions`](../Reference/Contracts/FlareTeeManager.md).
This page covers the payment surface (`pay`, `reissue`) and the [fee schedule](#fee-schedules) and [batching](#batching) mechanisms that drive them.

## Submitting a Payment

A user with an authorization on a PMW account calls:

```solidity
TeePayments.pay(PMWMultisigAccount account, PaymentInstruction paymentInstruction, address claimBackAddress)
```

`account` identifies the external account:

- `sourceId`: external chain identifier (e.g. XRPL).
- `accountAddress`: account address on that chain (string).

`paymentInstruction` carries the payment data:

- `recipientAddress`: destination address on the external chain.
- `tokenId`: token identifier (`bytes`); currently unused, reserved for future token support.
- `amount`: amount to transfer.
- `maxFee`: maximum fee the user is willing to pay; the per-entry fee schedule scales this down.
- `paymentReference`: $32$-byte payment reference attached to the transaction.

`claimBackAddress` may reclaim the prepaid TEE fee if the instructions are not executed.
The call is payable; the message value funds the TEE-side execution.

`pay` returns the assigned `(nonce, subNonce)`: `nonce` indexes the wallet's batches, `subNonce` the sequence of payments within (and across) batches.

## Reissuing a Payment

A stuck batch can be reissued with the same payment data but a different fee schedule:

```solidity
TeePayments.reissue(PMWMultisigAccount account, uint64 nonce, uint64 firstSubNonce,
                    PaymentInstruction[] paymentInstructions,
                    ReissueFeeParams reissueFeeParams,
                    address claimBackAddress)
```

The caller passes the original batch's `(nonce, firstSubNonce)` and the same set of payment instructions; `reissueFeeParams` provides a fresh fee schedule:

- `maxFeePerPayment`: replacement `maxFee` for each payment.
- `factorsBIPSPerPayment`: per-payment fee-factor list in BIPS.
- `delaysSeconds`: shared delay schedule (strictly ascending, in seconds from start).

If `factorsBIPSPerPayment` is empty, the account's stored [fee schedule](#fee-schedules) (or the default) is used.

A negative factor value triggers [nullification](#nullification).

## How Payment Instructions Reach TEE Machines

For each `pay` (or `reissue`) call, `TeePayments`:

1. Resolves the `walletId` from `(sourceId, accountAddress)`, calls `FlareTeeManager.receivingTeesAndKeys(walletId)` to obtain the `(teeId, keyId)` pairs that should sign the transaction, and resolves the effective fee schedule via the `TeePaymentsFeeScheduleManager`.
2. Builds a [`PaymentInstructionMessage`](Reference/Types/Payment.md#paymentinstructionmessage), which encodes:
   - `walletId`, `teeIdKeyIdPairs`.
   - `sourceId`, `senderAddress`, `recipientAddress`, `tokenId`, `amount`, `maxFee`, `paymentReference`.
   - `feeSchedule` (encoded; see [Fee Schedules](#fee-schedules)).
   - `nonce`, `subNonce`, `batchEndTs`.
3. Submits it as an [`F_XRP PAY`](Reference/Operations/Pay.md) (or [`F_XRP REISSUE`](Reference/Operations/Reissue.md)) instruction.
4. Once the instruction is voted through, each target TEE machine signs the corresponding transaction(s) with its share of the wallet's key set; the signed transactions are then available from the [TEE proxy](../Reference/Components/Proxy.md).

## Batching

Some chains (e.g. XRPL) allow several payments inside a single transaction.
For these chains, `TeePayments` opens a batch on the first payment to a previously inactive wallet and accumulates further payments until either:

- the batch reaches `batchSize` payments, or
- `batchDurationSeconds` have elapsed since the first payment in the batch.

Whichever happens first closes the batch and submits it as a single instruction.

Batch settings are per `(walletId, account)`:

```solidity
TeePayments.setBatchSettings(PMWMultisigAccount account, uint64 batchSize, uint64 batchDurationSeconds)
```

emitting [`BatchSettingsSet`](../Reference/Types/Abi/Events/TeePayments.md#batchsettingsset).

> **Reward epochs:** a batch that would otherwise extend past the current reward epoch is closed at the epoch boundary to keep all payments under a single [signing policy](../../FSP/SigningPolicy.md).

### Example

A wallet has `batchSize = S`, `batchDurationSeconds = d`, and no open batch.

1. Payment $T_0$ arrives at time $t$. A batch is opened with $\mathrm{T}_\mathrm{list} = (T_0)$, `batchEndTs = t + d`.
2. Each subsequent payment $T_i$ arriving before $t + d$ appends to $\mathrm{T}_\mathrm{list}$; once $|\mathrm{T}_\mathrm{list}| = S$, the batch closes and is submitted.
3. If $|\mathrm{T}_\mathrm{list}| < S$ at $t + d$, the batch closes with whatever payments it has.

## Fee Schedules

When a payment instruction reaches a TEE machine it carries a _fee schedule_ — an ordered list of `(factor, delay)` entries.
The TEE machine signs one transaction per entry up front and posts them to the [TEE proxy](../Reference/Components/Proxy.md) on the delay schedule, so higher-fee versions become available automatically if earlier ones do not confirm.

### Encoded Format

The on-chain fee schedule is a `bytes` array with $4$ bytes per entry:

| Bytes | Type | Description |
|---|---|---|
| $0$–$1$ | `int16` (big-endian) | Fee factor in BIPS ($-10000$ to $+10000$, non-zero). |
| $2$–$3$ | `uint16` (big-endian) | Delay in seconds from the start of processing. |

Entries must have strictly ascending `delaySeconds`.

### Fee Calculation

For each entry the effective fee is:

$$\mathrm{fee} = \dfrac{|f| * \mathrm{maxFee}}{10000}$$

where `maxFee` is the maximum fee from the payment instruction.

### Nullification

A negative `factor` flips the entry to a nullification: the TEE signs an `AccountSet` transaction (consuming the chain nonce without transferring funds) instead of a `Payment`.
Used to cancel a stuck payment.

### Default Schedule

If no project- or account-level schedule is configured, the default is a single $10000$ BIPS ($100\%$ of `maxFee`) entry at $0$ s delay, encoded as `0x27100000`.

### Configuration

Schedules are managed on the `TeePaymentsFeeScheduleManager` contract, with precedence `account override > project default > built-in default`:

- `setProjectFeeSchedule(projectId, sourceId, schedule)` / `clearProjectFeeSchedule(projectId, sourceId)`: project-wide default for a source. Callable by the [project owner](../../Terminology/Roles.md#project-owner). Emits [`ProjectFeeScheduleSet`](../Reference/Types/Abi/Events/TeePaymentsFeeScheduleManager.md#projectfeescheduleset) / [`ProjectFeeScheduleCleared`](../Reference/Types/Abi/Events/TeePaymentsFeeScheduleManager.md#projectfeeschedulecleared).
- `setAccountFeeSchedule(account, schedule)` / `clearAccountFeeSchedule(account)`: per-account override. Callable by the account owner; the contract resolves the project from the account. Emits [`AccountFeeScheduleSet`](../Reference/Types/Abi/Events/TeePaymentsFeeScheduleManager.md#accountfeescheduleset) / [`AccountFeeScheduleCleared`](../Reference/Types/Abi/Events/TeePaymentsFeeScheduleManager.md#accountfeeschedulecleared).

Per-source limits (max schedule length, max delay) are configured by governance via `setFeeScheduleConfigs`; sources with no configuration accept only the trivial single-entry schedule.

`reissue` overrides the stored schedule via `ReissueFeeParams`; see [Reissuing a Payment](#reissuing-a-payment).
