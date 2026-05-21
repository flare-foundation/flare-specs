# XRP Payment

## Overview

This workflow describes sending XRP payments from a TEE-managed Protocol Managed Wallet (PMW), including reissuance and nullification for failed payments.

## Prerequisites

- **Completed wallet-setup workflow** — the wallet must be in `PRODUCTION` status (see [WalletSetup.md](WalletSetup.md)).
- **Completed XRPL multisig configuration workflow** — a multisig account must be linked to the wallet via `TeePayments.addPMWMultisigAccount()` (see [XrplMultisigConfiguration.md](XrplMultisigConfiguration.md)).
- **Batch settings configured** — `TeePayments.setBatchSettings()` must have been called for the multisig account (see [Step 6 of XrplMultisigConfiguration.md](XrplMultisigConfiguration.md#step-6-set-batch-settings-optional)).
- **Fee schedule configured (optional)** — `TeePayments.setFeeSchedule()` can be called to set a custom fee escalation schedule. If not set, the default schedule (100% of `maxFee` at 0s delay) is used. See [Fee Scheduling](../Extensions/PMW/Transactions.md#fee-scheduling).
- **TEE machine(s) in PRODUCTION status** — at least one TEE machine holding the wallet's keys must be registered and operational.

---

## Steps

### Step 1: Submit Payment — `TeePayments.pay()`

**Who can call:** The project's authorized payment submission address.

**Parameters:**
- `account` (`PMWMultisigAccount`) — the multisig account, consisting of:
  - `sourceId` (`bytes32`) — source chain identifier (e.g., `bytes32("XRP")` or `bytes32("testXRP")` for testnet).
  - `accountAddress` (`string`) — the XRPL multisig account address.
- `paymentInstruction` (`PaymentInstruction`) — the payment details:
  - `recipientAddress` (`string`) — the recipient address on the XRP Ledger.
  - `tokenId` (`bytes`) — token identifier; zero-valued for native XRP.
  - `amount` (`uint256`) — amount in drops to transfer.
  - `maxFee` (`uint256`) — maximum transaction fee on the XRP Ledger, in drops.
  - `paymentReference` (`bytes32`) — a 32-byte payment reference.
- `claimBackAddress` (`address`) — address to claim back unused instruction fees.

**Requirements:**
- The wallet must be in `PRODUCTION` status.
- The multisig account must be linked to the wallet.
- The payment amount must be greater than $0$.
- The recipient address must differ from the sender address.
- The caller must be the authorized payment submission address for the account.
- Sufficient FLR must be sent with the transaction to cover the instruction fee.

**What happens:**

1. The `TeePayments` contract calls `receivingTeesAndKeys(walletId)` on [`FlareTeeManager`](../TeeManagement/FlareTeeManager.md) to retrieve the list of TEE machines and key IDs.
2. The contract forms a [`PAY`](../Extensions/PMW/Commands/Pay.md) instruction and submits it via `FlareTeeManager.sendInstructions()`.

**Events emitted:** [`TeeInstructionsSent`](../Types/Abi/Events/TeeExtensionRegistry.md#teeinstructionssent)

---

### Step 2: Batching

If batching is enabled for the multisig account, payments accumulate in a batch before being submitted as an instruction.

**Batch behavior:**

1. When a payment arrives and no batch is currently open, a new batch is opened.
2. Successive payments are added to the current batch.
3. The batch closes when any of the following conditions is met:
   - The batch reaches the configured `batchSize`.
   - The configured `batchDurationSeconds` have elapsed since the batch was opened.
   - A new reward epoch starts (to prevent ambiguity in signing policies).
4. Once the batch closes, all payments in the batch are submitted as a single instruction to the `TeeInstructions` contract, and the process proceeds as usual.

If `batchSize` is set to `1` and `batchDurationSeconds` is set to `0`, each payment is submitted immediately without batching.

---

### Step 3: TEE Processing

After the instruction is submitted, [data providers](../../Terminology/Roles.md#data-provider) vote on it and the action is processed by the TEE machine(s).

**What happens:**

1. Data providers observe the `TeeInstructionsSent` event and vote on the instruction.
2. Once sufficient votes are collected, the action is formed and sent to the TEE machine(s).
3. Each TEE machine signs the XRP Ledger multisig transaction using its stored private key for the wallet. The signed transaction is a standard XRPL multisig `Payment` (or `AccountSet` for nullification) with a filled `Signers` field.
4. The result is made available at the TEE proxy.

> **Note:** The `F_XRP PAY` command does not produce an immediate result. The action is processed asynchronously, and the result must be retrieved from the TEE proxy (see Step 4).

---

### Step 4: Retrieve Signed Transaction

Fetch the signed XRPL transaction from the TEE proxy.

**Who can call:** Anyone with access to the TEE proxy.

**Endpoint:** `GET /action/result/<actionId>`

**Input:**
- `actionId` (`bytes32`) — the `instructionId` from Step 1.

**What happens:**

1. The TEE proxy is polled for the action result using the `instructionId`.
2. Once available, the response contains:
   - `status` — indicates whether the action succeeded.
   - `data` — JSON of the signed XRPL transaction with a filled `Signers` field.
3. In a multi-TEE setup, each TEE proxy returns its own partial signature. All partial signatures must be collected and combined into a single transaction before submission.

---

### Step 5: Submit to XRPL

Submit the multisigned transaction to the XRP Ledger.

**Who can call:** Anyone.

**Input:**
- The signed XRPL transaction JSON from Step 4 (with all required signatures combined).

**What happens:**

1. The multisigned transaction is submitted to an XRPL node via the `submit_multisigned` method.
2. The XRP Ledger validates the transaction, checking that:
   - The number of valid signatures meets the `SignerQuorum`.
   - Each signature corresponds to a `SignerEntry` on the account's signer list.
   - The fee and other transaction fields are valid.
3. If accepted, the transaction is included in a validated ledger. The result includes:
   - `engine_result` — the transaction result code (e.g., `tesSUCCESS`).
   - `Sequence` — the transaction sequence number (used as the nonce for verification and reissuance).

---

### Step 6: Verify Payment (Optional) — [`PMWPaymentStatus`](../Extensions/FDC2/AttestationTypes/PMWPaymentStatus.md) FDC2 Attestation

Request a [`PMWPaymentStatus`](../Extensions/FDC2/AttestationTypes/PMWPaymentStatus.md) attestation to verify the on-chain status of the payment.

**Who can call:** Anyone.

**Parameters:**
- `opType` (`bytes32`) — wallet operation type (e.g., `bytes32("F_XRP")`).
- `senderAddress` (`string`) — the XRPL multisig account address.
- `nonce` (`uint64`) — the XRP `sequenceNumber` of the transaction.
- `subNonce` (`uint64`) — same as `nonce` for XRP.

**What happens:**

1. An FDC2 attestation request is submitted via `Fdc2Hub.requestAttestation()` with the [`PMWPaymentStatus`](../Extensions/FDC2/AttestationTypes/PMWPaymentStatus.md) attestation type.
2. TEE machines independently look up the transaction on the XRP Ledger using the `senderAddress` and `nonce`.
3. The attestation response includes:
   - `recipientAddress` — the recipient from the on-chain payment instruction.
   - `amount`, `fee`, `paymentReference` — from the on-chain payment instruction.
   - `transactionStatus` — `0` (success) or `1` (reverted).
   - `revertReason` — empty on success; the XRPL [transaction result code](https://xrpl.org/docs/references/protocol/transactions/transaction-results) on failure.
   - `receivedAmount` — the amount actually received.
   - `transactionFee` — the fee spent.
   - `transactionId` — the transaction hash on the XRP Ledger.
   - `blockNumber`, `blockTimestamp` — the ledger index and timestamp.
4. The attestation proof is retrieved from the TEE proxy and can be verified on-chain (e.g., via a `PMWPaymentStatusVerifier` contract).

See [PMWPaymentStatus](../Extensions/FDC2/AttestationTypes/PMWPaymentStatus.md) for the full attestation type specification.

---

### Step 7: Reissuance — `TeePayments.reissue()`

If a payment fails (e.g., due to a low fee or chain-level issues), the transaction can be reissued with updated parameters.

**Who can call:** The project's authorized payment submission address.

**Parameters:**
- `account` (`PMWMultisigAccount`) — the multisig account (same as Step 1).
- `nonce` (`uint64`) — the batch nonce of the original payment instruction.
- `firstSubNonce` (`uint64`) — the sub-nonce of the first transaction in the batch.
- `paymentInstructions` (`PaymentInstruction[]`) — the original payment instructions in the batch.
- `reissueFeeParams` (`ReissueFeeParams`) — the reissue fee parameters, containing:
  - `maxFees` (`uint256[]`) — the new maximum fees per instruction.
  - `feeFactorScheduleBIPS` (`int16[][]`) — fee factor schedules per instruction (in BIPS).
  - `feeDelayScheduleSeconds` (`uint16[]`) — time schedule for fee escalation (in seconds, ascending).
- `claimBackAddress` (`address`) — address to claim back unused instruction fees.

**Requirements:**
- The wallet must be in `PRODUCTION` status.
- The `paymentInstructions` array must be non-empty.
- The lengths of `paymentInstructions` and `reissueFeeParams.maxFees` must match.
- The batch hash must match the on-chain recorded hash for the nonce.
- The function is `payable` — sufficient value must be included to cover the instruction fee.

**What happens:**

1. The `TeePayments` contract forms a new instruction with the [`REISSUE`](../Extensions/PMW/Commands/Reissue.md) command.
2. Data providers vote and the TEE machine(s) sign the replacement transaction with the same nonce but updated fee.
3. The signed transaction is retrieved from the TEE proxy and submitted to the XRP Ledger, following the same flow as Steps 4 and 5.

**Nullification:** To nullify a payment, submit a reissue where the payment amount is $0$ and the sender address equals the recipient address.
The TEE machine signs an `AccountSet` transaction that consumes the blockchain nonce without transferring funds.

