# Payments

The PMW on-chain surface is a family of contracts on Flare:

- `TeePayments`: the user-facing hub, receives payment requests and routes them to the TEE machines holding the wallet's keys via [`FlareTeeManager.sendInstructions`](../../../FCC/Reference/Contracts/FlareTeeManager.md#sending-instructions) as [`F_XRP PAY`](../Operations/Pay.md) / [`F_XRP REISSUE`](../Operations/Reissue.md) instructions. Owns multisig-account bookkeeping.
- `TeePaymentsUtxo`: Copy of user-facing hub for payment requests for UTXO chains. Controls the batching process.
- `TeePaymentsFeeScheduleManager`: fee-schedule configuration.
- `TeePaymentsRegistry`: registers the external chains the system supports.
- `AddressValidator`: validates recipient addresses on external chains.

This page documents all five together, grouped by concern.
For the user-facing semantics, such as payment submission, batching, fee scheduling, reissuing and nullification, see [PMW Transactions](../../Transactions.md).
The PMW concepts (wallets, key set, multisig) are found in [PMW Concepts](../../Concepts.md) and [Concepts/Wallets](../../../FCC/Concepts/Wallets.md).

## Multisig Accounts

A _multisig account_ associates a PMW [wallet](../../../FCC/Concepts/Wallets.md#wallets) (on-chain `walletId`) with an external-chain account identified by `(sourceId, accountAddress)`.
The record holds the initial chain nonce and the authorization address (the only address allowed to submit payments against the account).
For wallets targeting UTXO chains, the record also holds per-account [batching](../../Transactions.md#batching) parameters.

### Account-based Chains

- `addPMWMultisigAccount(walletId, proof, authorizationAddress)`: reads `sourceId`, `accountAddress`, and `initialNonce` from `proof`, a `PMWMultisigAccountConfigured` [proof](../../../FDC2/Reference/AttestationTypes/PMWMultisigAccountConfigured.md), then registers a multisig account. Callable by the wallet's [project owner](../../../Terminology/Roles.md#project-owner) on `TeePayments`.

### UTXO-based Chains
- `addPMWMultisigAccount(walletId, proof, authorizationAddress)`: reads `sourceId`, `accountIndex`, and `anchorCount` from `proof`, a `PMWMultisigUtxoConfigured` [proof](../../../FDC2/Reference/AttestationTypes/PMWMultisigUtxoConfigured.md), then registers a multisig account. Callable by the wallet's [project owner](../../../Terminology/Roles.md#project-owner) on `TeePaymentsUtxo`.
- `setBatchSettings(account, batchSize, batchDurationSeconds)`: updates batching parameters for an existing account. Callable by the project owner on `TeePaymentsUtxo`.

### Events

#### PMWMultisigAccountAdded

Emitted by: `addPMWMultisigAccount()` on `TeePayments`

```solidity
event PMWMultisigAccountAdded(
    bytes32 indexed walletId,
    bytes32 sourceId,
    string accountAddress,
    address authorizationAddress,
      uint64 initialNonce
);
```

#### PMWMultisigUtxoAccountAdded

Emitted by: `addPMWMultisigAccount()` on `TeePaymentsUtxo`

```solidity
event PMWMultisigUtxoAccountAdded(
    bytes32 indexed walletId,
    bytes32 sourceId,
    string accountAddress,
    uint 32 accountIndex
    uint 256 anchorCount
    address authorizationAddress
);
```

#### UtxoBatchSettingsSet

Emitted by: `setBatchSettings()`

```solidity
event BatchSettingsSet(
    bytes32 indexed walletId,
    bytes32 sourceId,
    string accountAddress,
    uint64 batchSize,
    uint64 batchDurationSeconds
);
```

## Payments

Two user-facing entry points; both payable, both routed onward via `FlareTeeManager.sendInstructions` (which emits the [`TeeInstructionsSent`](../../../FCC/Reference/Contracts/FlareTeeManagerEvents.md#teeinstructionssent) event) and found on both `TeePayments` and `TeePaymentsUtxo`:

- `pay(account, paymentInstruction, claimBackAddress)`: submit a single payment; opens a new batch or appends to an existing one for UTXO accounts. Returns the assigned `paymentId`. See [Submitting a Payment](../../Transactions.md#submitting-a-payment).
- `reissue(account, paymentId, paymentInstructions, reissueFeeParams, claimBackAddress)`: re-sign a stuck payment or batch with a fresh fee schedule, or [nullify](../../Transactions.md#nullification) it. See [Reissuing a Payment](../../Transactions.md#reissuing-a-payment).

`msg.value` funds TEE-side execution; `claimBackAddress` reclaims the fee if the instruction does not execute.
Caller must be the multisig account's `authorizationAddress`.

## Fee Schedules

A _fee schedule_ is an ordered list of `(factor, delay)` entries that scales the user's `maxFee` per TEE-signed transaction; see [Fee Schedules](../../Transactions.md#fee-schedules) for encoding and semantics.
Three layers of configuration apply with precedence `account override > project default > built-in default`:

- `setFeeScheduleConfigs(configs)` / `clearFeeScheduleConfigs(sourceIds)`: [governance](../../../Terminology/Roles.md#governance). Per-source constraints (max entries, max delay). Sources with no configuration accept only the trivial single-entry schedule.
- `setProjectFeeSchedule(projectId, sourceId, schedule)` / `clearProjectFeeSchedule(projectId, sourceId)`: project owner. Per-`(project, source)` default schedule.
- `setAccountFeeSchedule(account, schedule)` / `clearAccountFeeSchedule(account)`: account owner. Per-account override.

### Events

#### FeeScheduleConfigsSet

Emitted by: `setFeeScheduleConfigs()`

```solidity
event FeeScheduleConfigsSet(
    FeeScheduleConfigInput[] configs
);
```

#### FeeScheduleConfigsCleared

Emitted by: `clearFeeScheduleConfigs()`

```solidity
event FeeScheduleConfigsCleared(
    bytes32[] sourceIds
);
```

#### ProjectFeeScheduleSet

Emitted by: `setProjectFeeSchedule()`

```solidity
event ProjectFeeScheduleSet(
    bytes32 indexed projectId,
    bytes32 indexed sourceId,
    FeeSchedule[] schedule
);
```

#### ProjectFeeScheduleCleared

Emitted by: `clearProjectFeeSchedule()`

```solidity
event ProjectFeeScheduleCleared(
    bytes32 indexed projectId,
    bytes32 indexed sourceId
);
```

#### AccountFeeScheduleSet

Emitted by: `setAccountFeeSchedule()`

```solidity
event AccountFeeScheduleSet(
    bytes32 indexed projectId,
    bytes32 indexed sourceId,
    string accountAddress,
    bytes32 indexed accountHash,
    FeeSchedule[] schedule
);
```

#### AccountFeeScheduleCleared

Emitted by: `clearAccountFeeSchedule()`

```solidity
event AccountFeeScheduleCleared(
    bytes32 indexed projectId,
    bytes32 indexed sourceId,
    string accountAddress,
    bytes32 indexed accountHash
);
```

## Payment Limits

Governance caps per-transaction and daily volumes for an account:

- `setPaymentLimits(walletId, sourceId, accountAddress, transactionLimit, dailyLimit)`: [governance](../../../Terminology/Roles.md#governance).

### Events

#### PaymentLimitsSet

Emitted by: `setPaymentLimits()`

```solidity
event PaymentLimitsSet(
    bytes32 indexed walletId,
    bytes32 sourceId,
    string accountAddress,
    uint256 transactionLimit,
    uint256 dailyLimit
);
```

## Source Registry

Governance manages the set of external chains the contract supports (e.g. `XRP`, `testXRP`); see [PMW PAY](../Operations/Pay.md):

- `registerSources(registrations)`: add new sources.
- `unregisterSources(sourceIds)`: remove sources.

### Events

#### SourcesRegistered

Emitted by: `registerSources()`

```solidity
event SourcesRegistered(
    SourceRegistration[] registrations
);
```

#### SourcesUnregistered

Emitted by: `unregisterSources()`

```solidity
event SourcesUnregistered(
    bytes32[] sourceIds
);
```