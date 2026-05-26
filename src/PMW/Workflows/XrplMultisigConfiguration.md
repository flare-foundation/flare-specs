# XrplMultisigConfiguration

State machine for binding an XRPL multisig account to a PMW wallet so the wallet can issue XRP payments.
Three layers cooperate: the XRP Ledger holds the actual signer list and quorum; an [FDC2 attestation](../../FDC2/Reference/AttestationTypes/PMWMultisigAccountConfigured.md) certifies that the XRPL configuration matches the wallet; the [`Payments`](../Reference/Contracts/Payments.md) contract records the binding and unlocks `pay` / `reissue`.

## Preconditions

- The wallet is in `PRODUCTION` (or `PAUSED`) with at least `multisigThreshold` confirmed keys ([WalletSetup](../../FCC/Workflows/WalletSetup.md)).
- The wallet's `extensionId = 0` (system extension); the project's `keyType` is supported by the source chain (`XRP` / `testXRP`).
- The submitter holds access to an XRPL node and enough XRP to cover the XRPL owner reserve and transaction fees on the new multisig account.

## States

- `KeysOnly` — wallet keys exist on chain; no XRPL account has been bound yet.
- `XrplProvisioned` — an XRPL account has been created and configured as multisig over the TEE-derived addresses (`SignerList` set, master key disabled, no regular key, no prohibited flags).
- `Attested` — an FDC2 [`PMWMultisigAccountConfigured`](../../FDC2/Reference/AttestationTypes/PMWMultisigAccountConfigured.md) proof has been produced by the TEE network certifying the XRPL configuration.
- `Bound` — [`Payments.addPMWMultisigAccount`](../Reference/Contracts/Payments.md#multisig-accounts) has accepted the proof; the `(walletId, sourceId, accountAddress)` is on chain with an `initialNonce` from the XRPL `Sequence`.
- `BatchConfigured` — optional: `setBatchSettings` has set the account's batching parameters (a `BatchConfigured ⇄ Bound` re-entry is allowed).

## Initial State

`KeysOnly`.

## Transitions

### deriveAndConfigureXrpl: KeysOnly → XrplProvisioned

- **Action**: off-chain XRPL transactions:
  1. For each wallet key, convert the uncompressed `(X, Y)` pubkey to compressed form (33 bytes, prefix `0x02`/`0x03` by `Y` parity), hash via `SHA-256` then `RIPEMD-160` to a 20-byte account ID, and Base58Check-encode to an XRPL `r`-address.
  2. Submit a `SignerListSet` transaction on the chosen XRPL account: one `SignerEntry` per derived address with `SignerWeight = 1` and `SignerQuorum = multisigThreshold`.
  3. Submit `AccountSet` with `asfDisableMaster` to disable the master key. Ensure no regular key is set, and that deposit-auth and other prohibited flags are not enabled.
- **Caller**: anyone with an XRPL account and sufficient XRP.
- **Guards** (enforced by XRPL):
  - The XRPL account funds the owner reserve required for the signer list.
  - `SignerQuorum = wallet.multisigThreshold`.
- **Effects**: the XRPL account is irrevocably under multisig control of the TEE-held keys. The account flags satisfy the [`PMWMultisigAccountConfigured` checks](../../FDC2/Reference/AttestationTypes/PMWMultisigAccountConfigured.md).

### attest: XrplProvisioned → Attested

- **Action**: invoke the [Fdc2Attestation](../../FDC2/Workflows/Fdc2Attestation.md) sub-workflow with `attestationType = PMWMultisigAccountConfigured`, supplying `(walletId, sourceId, accountAddress)` in the request. Each participating TEE machine queries its own XRP node, runs the [verification rules](../../FDC2/Reference/AttestationTypes/PMWMultisigAccountConfigured.md), and signs the response.
- **Caller**: any user (typically the wallet owner).
- **Guards**: the XRPL account's signer list, quorum, and flags satisfy every check in the [`PMWMultisigAccountConfigured` spec](../../FDC2/Reference/AttestationTypes/PMWMultisigAccountConfigured.md); the response carries `status = ok` and the current XRPL `Sequence` as `sequence`.
- **Effects**: the resulting [`ProveResponse`](../../FDC2/Reference/Types/Wire/Fdc2.md#proveresponse) is retrievable from the TEE proxy.

### bind: Attested → Bound

- **Action**: [`Payments.addPMWMultisigAccount(walletId, proof, authorizationAddress)`](../Reference/Contracts/Payments.md#multisig-accounts) — non-payable. (The first proof step is `verifyPMWMultisigAccountConfiguredProof` on `FlareTeeManager`, invoked internally.)
- **Caller**: project owner.
- **Guards**:
  - `wallet.status ∈ {PRODUCTION, PAUSED}`.
  - proof passes signature and configuration checks (signing policy, cosigners, TEE signatures, key set match, threshold match, response status = `ok`).
  - `wallet.extensionId = 0` (system extension); `proof.keyType = project.keyType`.
  - `accountAddress` non-empty; `sourceId` is registered; the account is not already linked.
  - `authorizationAddress ≠ 0`.
- **Effects**:
  - Records `(walletId, sourceId, accountAddress, initialNonce = proof.sequence, authorizationAddress)`.
  - Emits [`PMWMultisigAccountAdded`](../Reference/Contracts/Payments.md#pmwmultisigaccountadded).
  - From this point, the `authorizationAddress` can call [`Payments.pay`](../Reference/Contracts/Payments.md#payments) (see [XrpPayment](XrpPayment.md)).

### setBatchSettings: Bound ⇄ BatchConfigured

- **Action**: [`Payments.setBatchSettings(account, batchSize, batchDurationSeconds)`](../Reference/Contracts/Payments.md#multisig-accounts) — non-payable. Re-callable to change parameters.
- **Caller**: project owner.
- **Guards**: `0 < batchSize ≤ maxBatchSize`, `batchDurationSeconds ≤ maxBatchDurationSeconds`.
- **Effects**: updates the account's batching parameters; emits [`BatchSettingsSet`](../Reference/Contracts/Payments.md#batchsettingsset). `batchSize = 1` and `batchDurationSeconds = 0` together disable batching.

## Invariants

- The XRPL `SignerList` size and the wallet's confirmed-key count remain in correspondence: any change to the wallet's key set requires re-running [`attest`](#attest-xrplprovisioned--attested) and [`bind`](#bind-attested--bound) before payments resume.
- `Payments.addPMWMultisigAccount` is callable at most once per `(sourceId, accountAddress)` — re-binding requires off-chain XRPL changes and a fresh proof.
- The account's `nonce` on chain starts at `proof.sequence` (the XRPL `Sequence` at attestation time) and advances monotonically with each closed batch.

## Terminal States

`Bound` (or `BatchConfigured`). From here [XrpPayment](XrpPayment.md) takes over.

## Notes

- For multi-TEE deployments, ensure the derived XRPL `SignerList` reflects every participating TEE's wallet-key address — see [MultiTeeOperations § CP-5](../../FCC/Workflows/MultiTeeOperations.md#cp-5-external-multisig-binding-once).
- The XRPL configuration is irrevocable once the master key is disabled and no regular key is set; signer-list changes must be authorised by the multisig itself (i.e., a TEE-signed transaction).
- For the exhaustive XRPL configuration checks and example `account_info` responses, see [`PMWMultisigAccountConfigured`](../../FDC2/Reference/AttestationTypes/PMWMultisigAccountConfigured.md).
