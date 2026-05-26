# XrpPayment

State machine for one XRP payment (or batched group) from a [PMW](../README.md) wallet through to on-chain settlement, with reissuance and nullification as alternate paths.

Canonical user-facing semantics live in [PMW Transactions](../Transactions.md); contract surface in [`Payments`](../Reference/Contracts/Payments.md); on-machine signing in [`F_XRP PAY`](../Reference/Operations/Pay.md) / [`F_XRP REISSUE`](../Reference/Operations/Reissue.md).

## Preconditions

- The wallet is in `PRODUCTION` ([WalletSetup](../../FCC/Workflows/WalletSetup.md)).
- A multisig account is linked via [`Payments.addPMWMultisigAccount`](../Reference/Contracts/Payments.md#multisig-accounts) ([XrplMultisigConfiguration](XrplMultisigConfiguration.md)).
- Batch settings and fee schedule are configured (or the defaults are acceptable; see [Concepts](../Transactions.md#batching) and [Fee Schedules](../Transactions.md#fee-schedules)).
- At least `multisigThreshold` TEE machines holding a wallet key are in `PRODUCTION`.

## States

- `Idle` — no in-flight payment for the next `subNonce` of this account.
- `Pending` — `pay` has registered the payment but the batch has not yet been submitted on chain (batch open, batch size and duration not yet exhausted).
- `Submitted` — the batch closed and [`TeeInstructionsSent`](../../FCC/Reference/Contracts/FlareTeeManagerEvents.md#teeinstructionssent) carries the [`F_XRP PAY`](../Reference/Operations/Pay.md) instruction; voting is in progress.
- `Signed` — voting reached threshold; each participating TEE machine produced its partial signature and posted the JSON XRPL transaction to its proxy. The TEE machine continues to post one transaction per fee-schedule entry on its delay schedule.
- `OnLedger` — a combined `multisigThreshold`-of-$n$ XRPL transaction has been submitted to XRPL and included in a validated ledger.
- `StatusVerified` — an optional [`PMWPaymentStatus`](../../FDC2/Reference/AttestationTypes/PMWPaymentStatus.md) attestation has been verified on chain, certifying the outcome.

## Initial State

`Idle` for the next `(account, subNonce)`.

## Transitions

### pay: Idle → Pending

- **Action**: [`Payments.pay(account, paymentInstruction, claimBackAddress)`](../Reference/Contracts/Payments.md#payments) — payable.
- **Caller**: the multisig account's `authorizationAddress`.
- **Guards**:
  - `wallet.status = PRODUCTION`
  - account linked via `addPMWMultisigAccount`
  - `paymentInstruction.amount > 0` (the zero-amount [nullification](#reissue-nullify-pending--submitted) path goes through `reissue`)
  - `paymentInstruction.recipientAddress ≠ account.accountAddress` (same condition)
  - `msg.value ≥ fee(F_XRP, PAY)`
- **Effects**:
  - The contract calls `FlareTeeManager.receivingTeesAndKeys(walletId)` to obtain the `(teeId, keyId)` pairs and the effective fee schedule.
  - The payment is added to the account's current batch, or opens a new batch if none is active. The assigned `(nonce, subNonce)` is returned to the caller.
  - No on-chain instruction is emitted yet — that happens at batch close.

### batchClose: Pending → Submitted

- **Action**: implicit on-chain step inside `Payments`. Fires when the current batch reaches `batchSize`, when `batchDurationSeconds` elapses, or when the active reward epoch boundary is reached (to keep all payments under one [signing policy](../../FSP/SigningPolicy.md)).
- **Caller**: the same `Payments.pay` (or `Payments.reissue`) call that overflows the batch.
- **Guards**: at least one payment in the batch.
- **Effects**:
  - Builds a [`PaymentInstructionMessage`](../Reference/Types/Payment.md#paymentinstructionmessage) covering every entry in the batch.
  - Calls [`FlareTeeManager.sendInstructions`](../../FCC/Reference/Contracts/FlareTeeManager.md#sending-instructions), emitting [`TeeInstructionsSent`](../../FCC/Reference/Contracts/FlareTeeManagerEvents.md#teeinstructionssent).

### vote: Submitted → Signed

- **Action**: standard [voting](../../FCC/Concepts/Voting.md) on each target TEE proxy. Each TEE machine signs one XRPL transaction per fee-schedule entry on its delay schedule.
- **Caller**: [data providers](../../Terminology/Roles.md#data-provider).
- **Guards**: data-provider weight $\geq$ signing-policy threshold; cosigner threshold met if the wallet configured one.
- **Effects**:
  - The `threshold`-tagged [action result](../../FCC/Concepts/Actions.md#action-results) carries the first signed transaction (or a placeholder for asynchronous fee-schedule delivery).
  - Subsequent fee-schedule entries arrive as later [`ActionResult`](../../FCC/Reference/Types/Wire/Action.md#actionresult) updates with monotonically-increasing `status`; the final entry carries the `end` submission tag.
  - Each signed transaction is a JSON XRPL transaction with a populated `Signers` field (or an `AccountSet` for [nullification](#reissue-nullify-pending--submitted)).

### submit: Signed → OnLedger

- **Action**: off-chain — submitter reads partial signatures from each participating proxy (`GET /action/result/<actionId>`), aggregates them into a single XRPL transaction reaching `SignerQuorum`, and submits via the XRPL `submit_multisigned` RPC.
- **Caller**: anyone.
- **Guards**: aggregated partial signatures satisfy the XRPL `SignerList` quorum.
- **Effects**: XRPL validates and includes the transaction; `tesSUCCESS` or a fail code is returned in `engine_result`.

### verifyStatus: OnLedger → StatusVerified (optional)

- **Action**: invoke the [Fdc2Attestation](../../FDC2/Workflows/Fdc2Attestation.md) sub-workflow with `attestationType = PMWPaymentStatus`. Final on-chain verification is via the [verifier entry](../../FCC/Reference/Contracts/FlareTeeManager.md#facets) on `FlareTeeManager`.
- **Caller**: anyone.
- **Effects**: an FDC2 proof certifies the XRPL `(sender, nonce)`'s outcome — recipient, amount, fee, payment reference, on-ledger transaction hash, and `transactionStatus` ($0$ = success, $1$ = reverted). See [`PMWPaymentStatus`](../../FDC2/Reference/AttestationTypes/PMWPaymentStatus.md).

### reissue / nullify: Pending → Submitted (alternate path)

- **Action**: [`Payments.reissue(account, nonce, firstSubNonce, paymentInstructions, reissueFeeParams, claimBackAddress)`](../Reference/Contracts/Payments.md#payments) — payable.
- **Caller**: the multisig account's `authorizationAddress`.
- **Guards**:
  - `wallet.status = PRODUCTION`
  - `paymentInstructions` is non-empty
  - `|paymentInstructions| = |reissueFeeParams.maxFeePerPayment|`
  - The batch hash for `(nonce, firstSubNonce)` matches the on-chain record.
  - `msg.value ≥ fee(F_XRP, REISSUE)`
- **Effects**:
  - Builds a `F_XRP REISSUE` instruction with the new fee schedule and emits it via `FlareTeeManager.sendInstructions`.
  - **Nullification** is the degenerate case where the per-payment amount is $0$ and the recipient equals the sender; the TEE machine then signs an `AccountSet` transaction (consuming the chain nonce without transferring funds). See [Nullification](../Transactions.md#nullification).

## Invariants

- `(walletId, nonce, subNonce)` uniquely identifies a payment within a batch; reissuance replaces the signed transaction at the same `(nonce, subNonce)` but does not double-spend on XRPL because the XRPL `Sequence` is unchanged.
- The XRPL `SignerQuorum` equals the wallet's `multisigThreshold` (enforced at [XrplMultisigConfiguration](XrplMultisigConfiguration.md)).
- The TEE machine signs one transaction per fee-schedule entry; higher-fee entries land later under the delay schedule but only one ever clears on chain because they share `Sequence`.

## Terminal States

`OnLedger` (or `StatusVerified` if proof verification is run). The payment is settled; the `(nonce, subNonce)` is consumed and subsequent payments draw a fresh sub-nonce within the same batch or open a new one.

## Notes

- The `F_XRP PAY` operation is asynchronous (`immediateResult = false`): the `threshold` action carries a placeholder, then one signed transaction per fee entry arrives with monotonically-increasing status, and the last is tagged `end` (`status = 1`). See [`F_XRP PAY` action result](../Reference/Operations/Pay.md#action-result).
- For multi-TEE deployments, partial signatures must be collected from each participating proxy before submission; see [MultiTeeOperations § CP-6](../../FCC/Workflows/MultiTeeOperations.md#cp-6-payments-parallel-sign-single-submit).
- The XRPL transaction-result code is documented at [xrpl.org transaction results](https://xrpl.org/docs/references/protocol/transactions/transaction-results).
