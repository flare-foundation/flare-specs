# TeePayments

The `TeePayments` contract is the PMW-side on-chain hub.
It receives payment requests from users on behalf of external-chain wallets managed by the [system extension](../../../FCE/System.md), routes them to the TEE machines that hold the wallet's keys via [`FlareTeeManager.sendInstructions`](../../../Reference/Contracts/FlareTeeManager.md#sending-instructions), and bundles them as [`F_XRP PAY`](../Operations/Pay.md) / [`F_XRP REISSUE`](../Operations/Reissue.md) instructions.
Alongside the payment surface it manages multisig-account bookkeeping, fee schedules, payment limits, and the set of supported external chains.

For the user-facing semantics — payment submission, batching, fee scheduling, reissue/nullification — see [PMW Transactions](../../Transactions.md). The PMW concepts (wallets, key set, multisig) live in [PMW Concepts](../../Concepts.md) and [Concepts/Wallets](../../../Concepts/Wallets.md).

## Multisig Accounts

A _multisig account_ associates a PMW [wallet](../../../Concepts/Wallets.md#wallets) (on-chain `walletId`) with an external-chain account identified by `(sourceId, accountAddress)`. The record holds the initial chain nonce, the authorization address (the only address allowed to submit payments against the account), and the per-account [batching](../../Transactions.md#batching) parameters.

- `addPMWMultisigAccount(walletId, sourceId, accountAddress, initialNonce, authorizationAddress, batchSize, batchDurationSeconds)` — register a multisig account. Callable by the wallet's [project owner](../../../../Terminology/Roles.md#project-owner).
- `setBatchSettings(account, batchSize, batchDurationSeconds)` — update batching parameters for an existing account. Callable by the project owner.

### Events

#### PMWMultisigAccountAdded

Emitted by: `addPMWMultisigAccount()`

```solidity
event PMWMultisigAccountAdded(
    bytes32 indexed walletId,
    bytes32 sourceId,
    string accountAddress,
    uint64 initialNonce,
    address authorizationAddress,
    uint64 batchSize,
    uint64 batchDurationSeconds
);
```

#### BatchSettingsSet

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

Two user-facing entry points; both payable, both routed onward via `FlareTeeManager.sendInstructions` (which emits the [`TeeInstructionsSent`](../../../Reference/Contracts/FlareTeeManagerEvents.md#teeinstructionssent) event):

- `pay(account, paymentInstruction, claimBackAddress)` — submit a single payment; opens a new batch or appends to an existing one. Returns the assigned `(nonce, subNonce)`. See [Submitting a Payment](../../Transactions.md#submitting-a-payment).
- `reissue(account, nonce, firstSubNonce, paymentInstructions, reissueFeeParams, claimBackAddress)` — re-sign a stuck batch with a fresh fee schedule, or [nullify](../../Transactions.md#nullification) it. See [Reissuing a Payment](../../Transactions.md#reissuing-a-payment).

`msg.value` funds TEE-side execution; `claimBackAddress` reclaims the fee if the instruction does not execute. Caller must be the multisig account's `authorizationAddress`.

## Fee Schedules

A _fee schedule_ is an ordered list of `(factor, delay)` entries that scales the user's `maxFee` per TEE-signed transaction; see [Fee Schedules](../../Transactions.md#fee-schedules) for the wire encoding and semantics. Three layers of configuration apply with precedence `account override > project default > built-in default`:

- `setFeeScheduleConfigs(configs)` / `clearFeeScheduleConfigs(sourceIds)` — [governance](../../../../Terminology/Roles.md#governance). Per-source constraints (max entries, max delay). Sources with no configuration accept only the trivial single-entry schedule.
- `setProjectFeeSchedule(projectId, sourceId, schedule)` / `clearProjectFeeSchedule(projectId, sourceId)` — project owner. Per-`(project, source)` default schedule.
- `setAccountFeeSchedule(account, schedule)` / `clearAccountFeeSchedule(account)` — account owner. Per-account override.

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

- `setPaymentLimits(walletId, sourceId, accountAddress, transactionLimit, dailyLimit)` — [governance](../../../../Terminology/Roles.md#governance).

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

- `registerSources(registrations)` — add new sources.
- `unregisterSources(sourceIds)` — remove sources.

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
