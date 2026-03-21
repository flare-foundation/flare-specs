# XRPL Multisig Configuration

## Overview

This workflow describes how to bind an XRPL multisig account to a TEE-managed Protocol Managed Wallet (PMW). The process involves two phases: first, configuring a multisig account on the XRP Ledger off-chain using the wallet's public keys, then linking that account on-chain through an FDC2 attestation that proves the XRPL account is correctly configured.

Once complete, the wallet can issue payment transactions on the XRP Ledger through the TEE infrastructure.

## Prerequisites

- A PMW wallet in `PRODUCTION` status with keys already added (see [wallet-setup.md](wallet-setup.md)).
- Access to an XRPL node (e.g., `wss://s.altnet.rippletest.net:51233` for testnet).
- The wallet's public keys retrieved from the TEE proxy.
- The wallet's multisig threshold configured.
- Sufficient FLR to cover instruction fees on Flare.

---

## Steps

### Phase 1: Off-Chain XRPL Setup

### Step 1: Derive XRP Addresses

Convert each TEE wallet public key into an XRPL account address.

**Who can call:** Anyone with access to the wallet's public keys (typically the project owner).

**Parameters:**
- `publicKey` (`bytes`) -- The wallet key's public key in uncompressed format (`pubkey.X | pubkey.Y`, 64 bytes).

**What happens:**

1. The uncompressed public key is converted to compressed format (33 bytes). The prefix byte is `0x02` if the Y coordinate is even, or `0x03` if odd.
2. The compressed public key is hashed using SHA-256 followed by RIPEMD-160 to produce a 20-byte account ID.
3. The account ID is encoded into an XRPL r-address using Base58Check encoding.

Each wallet key produces one XRP address that will be used as a signer on the multisig account.

---

### Step 2: Create XRPL Multisig Account

Set up a multisig account on the XRP Ledger with the derived signer addresses.

**Who can call:** Anyone with an XRPL account and sufficient XRP for reserve requirements.

**Parameters:**
- `signerAddresses` (`string[]`) -- XRP addresses derived in Step 1, one per wallet key.
- `threshold` (`int`) -- The multisig threshold, matching the wallet's configured threshold.

**Requirements:**
- The XRPL account must be funded with enough XRP to meet the owner reserve for the signer list.
- The account configuration must satisfy all verification rules described in the XRPL Account Flag Requirements below.

**What happens:**

1. A signer list is set on the XRPL account via a `SignerListSet` transaction:
   - Each wallet key's derived XRP address is added as a `SignerEntry`.
   - Each `SignerWeight` is set to `1`.
   - `SignerQuorum` is set to the wallet's multisig `threshold`.
2. The master key is disabled via an `AccountSet` transaction with the `asfDisableMaster` flag.
3. The account must not have a regular key set. If one exists, it must be removed.
4. Deposit authorization and other prohibited flags must not be enabled.

After this step, the XRPL account can only authorize transactions through multisig signing by the TEE-held keys.

#### XRPL Account Configuration Requirements

The `PMWMultisigAccountConfigured` attestation verifier checks the XRPL account's signer list, quorum, account flags, and regular key status. All checks must pass for the attestation to return `status = ok`. In summary, the account must have:

- A signer list matching the wallet's public keys, each with `SignerWeight = 1`
- `SignerQuorum` matching the wallet's multisig threshold
- Master key disabled, no deposit authorization, no destination tag requirement, no incoming XRP disallowed
- No regular key set

On success, the account's `Sequence` number is returned as the initial nonce for payment transactions.

For the complete verification rules and example `account_info` responses, see [PMWMultisigAccountConfigured](../attestation-types/PMWMultisigAccountConfigured.md).

---

### Phase 2: On-Chain Attestation and Linking

### Step 3: Request `PMWMultisigAccountConfigured` Attestation

Submit an FDC2 attestation request to verify that the XRPL multisig account is correctly configured.

**Who can call:** Anyone (typically the wallet owner).

**Parameters:**
- `walletId` (`bytes32`) -- The wallet ID.
- `sourceId` (`bytes32`) -- Source chain identifier (e.g., `bytes32("XRP")` or `bytes32("testXRP")` for testnet).
- `accountAddress` (`string`) -- The XRPL multisig account address (e.g., `"rUzM4ovjNkjSZ2jVJfZQ9321ikeNM6ASzh"`).
- `testOnTeeId` (`address`) -- Optional TEE machine ID for testing (set to zero address in production).

**Requirements:**
- Wallet must be in `PRODUCTION` or `PAUSED` status.
- Must send sufficient FLR to cover the attestation instruction fee (e.g., `1000000` wei).

**What happens:**

1. `TeeVerification.requestPMWMultisigAccountConfiguredAttestation()` is called on the Flare C-chain.
2. The contract collects the wallet's public keys and multisig threshold from the `TeeWalletManager`.
3. An FDC2 attestation request is formed and sent to TEE machines as an instruction.
4. A `TeeInstructionsSent` event is emitted containing the `instructionId`.
5. Off-chain, each TEE machine independently queries its own XRP node and verifies the account configuration (see [PMWMultisigAccountConfigured](../attestation-types/PMWMultisigAccountConfigured.md) for the full verification procedure).
6. TEE machines return signed attestation responses to the TEE proxy.

**Events emitted:** `TeeInstructionsSent` with `instructionId`.

---

### Step 4: Retrieve and Verify Attestation Proof

Fetch the attestation proof from the TEE proxy and verify it on-chain.

**Who can call:** Anyone (typically the wallet owner).

**Parameters:**
- `walletId` (`bytes32`) -- The wallet ID.
- `instructionId` (`bytes32`) -- The instruction ID from Step 3.
- `proxyURL` (`string`) -- URL of the TEE proxy.

**Requirements:**
- Sufficient time must have passed for TEE machines to process the attestation (typically a few seconds).

**What happens:**

1. The attestation proof is fetched from the TEE proxy using the `instructionId`.
2. The proof is an `IPMWMultisigAccountConfiguredProof` containing:
   - `Header` -- FDC2 response header.
   - `RequestBody` -- The original request (`accountAddress`, `publicKeys`, `threshold`).
   - `ResponseBody` -- The attestation result (`status`, `sequence`).
   - `Signatures` -- Signing policy signatures, TEE signatures, and cosigner signatures.
3. The proof is verified on-chain via `TeeVerification.verifyPMWMultisigAccountConfiguredProof(walletId, proof)`:
   - Verifies signing policy signatures.
   - Verifies TEE and cosigner signatures.
   - Checks that the wallet's public keys match the proof's public keys.
   - Checks that the multisig threshold matches.
   - Verifies `ResponseBody.status` is `ok`.
4. If verification succeeds, the `sequence` number (XRPL account sequence) is extracted from the response body for use as the initial nonce.

**Events emitted:** None (read-only verification call).

---

### Step 5: Add PMW Multisig Account

Link the verified XRPL multisig account to the wallet on-chain.

**Who can call:** Wallet owner (project owner) only.

**Parameters:**
- `walletId` (`bytes32`) -- The wallet ID.
- `proof` (`IPMWMultisigAccountConfiguredProof`) -- The verified attestation proof from Step 4.

**Requirements:**
- Wallet must be in `PRODUCTION` or `PAUSED` status.
- The proof must be valid (passes all signature and configuration checks).

**What happens:**

1. `TeePayments.addPMWMultisigAccount(walletId, proof)` is called.
2. The contract validates the proof:
   - Verifies proof signatures (signing policy + cosigners).
   - Checks that the wallet's public keys match the proof's public keys.
   - Checks that the multisig threshold matches.
   - Verifies the response status is `ok`.
3. The XRP account address is linked to the `walletId` and stored in the wallet's account list.
4. The account's initial nonce is set from the proof's `sequence` value.

**Events emitted:** `PMWMultisigAccountAdded` with wallet ID and account details.

---

### Step 6: Set Batch Settings (Optional)

Configure batching parameters for the multisig account to group multiple payments into single XRPL transactions.

**Who can call:** Wallet owner only.

**Parameters:**
- `account` (`ITeePayments.PMWMultisigAccount`) -- The multisig account, consisting of:
  - `sourceId` (`bytes32`) -- Source chain identifier.
  - `accountAddress` (`string`) -- The XRPL multisig account address.
- `batchSize` (`uint256`) -- Maximum number of payments per batch. Set to `1` for single-payment transactions.
- `batchDurationSeconds` (`uint256`) -- Maximum duration in seconds for a batch to remain open. Set to `0` for immediate execution.

**Requirements:**
- The account must have been added via Step 5.
- Caller must be the wallet owner.

**What happens:**

1. `TeePayments.setBatchSettings(account, batchSize, batchDurationSeconds)` is called.
2. The account's batch settings are updated.
3. Batch behavior:
   - A new batch opens when a payment arrives and no batch is currently open.
   - The batch closes when `batchSize` is reached, OR `batchDurationSeconds` have elapsed since the batch opened, OR a new reward epoch starts.
   - All payments in a closed batch share the same nonce and are included in a single XRPL transaction.

**Events emitted:** `BatchSettingsSet` with the account and new settings.


