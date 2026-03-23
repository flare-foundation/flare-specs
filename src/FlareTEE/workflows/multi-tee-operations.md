# Distributed Multi-TEE Workflows

## Overview

The Flare TEE system supports operating with multiple TEE machines working together for a single wallet. In a multi-TEE configuration, keys are distributed across separate TEE machines, each running on its own Confidential VM with its own proxy. Signatures are collected independently from each TEE and aggregated into a single multisig transaction. This distributed trust model eliminates single points of failure and provides threshold-based fault tolerance -- for example, a 2-of-3 configuration allows the system to continue operating even if one TEE machine goes offline.

The multi-TEE approach applies to all key operations: key generation, XRPL multisig configuration, payment signing, and attestation verification. Each TEE independently generates its own key, independently signs transactions, and independently participates in attestation flows. The coordination happens at the proxy level and on-chain.

## Prerequisites

- Multiple TEE nodes running, each on its own Confidential VM with its own TEE proxy (e.g., 3 nodes with proxies on ports 6662, 6664, 6666).
- Each TEE node must be registered and moved to `PRODUCTION` status independently.
- An extension must be registered and each TEE machine must be associated with the same extension.
- For XRPL operations: access to an XRP testnet or mainnet node.

---

## Steps

### Step 1: Register N Machines Independently -- `TeeMachineRegistry.register()` + `toProduction()`

**Who can call:** TEE operator (machine owner).

**Parameters:** Same as single-machine registration (see [machine-registration.md](machine-registration.md)).

**Requirements:**
- Each TEE node runs on its own Confidential VM.
- Each node has its own proxy instance (e.g., on separate ports).
- All machines must belong to the same extension.

**What happens:**
1. For each of the N TEE machines (e.g., 3 machines with proxies at `http://localhost:6662`, `http://localhost:6664`, `http://localhost:6666`):
   - Retrieve TEE info from the proxy via `/info` endpoint.
   - Extract the `teeId` and `proxyId` from the signed TEE info response.
   - Call `GET <proxy_url>/info` to retrieve the `SignedTeeInfoResponse`. Extract the `teeId`, `publicKey`, `codeHash`, `platform`, `extensionId`, `proxyId`, and `dataSignature`.
   - Call `TeeMachineRegistry.register(machineData, signature, teeProxyId, teeUrl)` where `machineData` is constructed from the `/info` response fields and `signature` is the `dataSignature` from the response.
   - Request a `TeeAvailabilityCheck` attestation via the FDC2 flow.
   - Retrieve the availability proof and call `TeeMachineRegistry.toProduction(proof)` to move the machine to `PRODUCTION` status.
2. Each registration is fully independent -- machines do not need to know about each other at this stage.

**Events emitted:** `TeeMachineRegistered`, `TeeMachineToProduction` (per machine).

---

### Step 2: Create Wallet Across Multiple TEEs -- `TeeWalletManager.createWallet()` + `TeeWalletKeyManager.addKey()`

**Who can call:** Project owner.

**Parameters:**
- Standard wallet creation parameters (project ID, admin keys, threshold).
- One `addKey()` call per TEE machine.

**Requirements:**
- All TEE machines must be in `PRODUCTION` status.
- All machines must belong to the same extension as the project.

**What happens:**
1. **Create one project and one wallet** -- a single on-chain operation, same as the single-TEE flow:
   - `TeeWalletProjectManager.createProject(extensionId, keyType, signingAlgo, authorizationAddress)`
   - `TeeWalletManager.createWallet(projectId)`
   - `TeeWalletManager.setAdmins(walletId, adminsPublicKeys, adminsThreshold)` followed by `confirmAdmin()` for each admin.
   - `TeeWalletManager.closeWalletInitialization(walletId)`
2. **Set multisig threshold** -- `TeeWalletKeyManager.setMultisigThreshold(walletId, threshold)` (e.g., `threshold=2` for 2-of-3 signing).
3. **Add one key per TEE** -- for each proxy URL:
   - Get the `teeId` from the proxy.
   - Call `TeeWalletKeyManager.addKey(teeId, walletId)` -- this sends a `KEY_GENERATE` instruction to that specific TEE.
   - Each TEE independently generates its own private key.
   - Retrieve the `KeyExistence` proof from each proxy.
   - Call `TeeWalletKeyManager.confirmKey(proof, teeSignature)` for each key individually.
4. **Enable wallet** -- `TeeWalletManager.enableWallet(walletId)` once the number of confirmed keys meets the multisig threshold.

**Events emitted:** `WalletCreated`, `WalletAdminsSet`, `WalletAdminConfirmed`, `WalletInitialized`, `WalletMultisigThresholdSet`, `WalletKeyAdded` (per TEE), `TeeInstructionsSent` (per TEE), `WalletKeyConfirmed` (per TEE), `WalletEnabled`.

See [wallet-setup.md](wallet-setup.md) for the full single-TEE wallet flow.

---

### Step 3: Set Up Shared XRPL Multisig Account

**Who can call:** Project owner.

**Requirements:**
- Wallet must be in `PRODUCTION` status with all keys confirmed.
- Each key's public key must be retrievable from its respective proxy.

**What happens:**
1. **Collect public keys from all TEEs:**
   - For each proxy, call `GET <proxy_url>/wallet/<walletId>/<keyId>` to retrieve the key info JSON, which includes the `publicKey` field (uncompressed secp256k1 format, 64 bytes: `pubkey.X | pubkey.Y`).
   - Derive each XRP address from the public key: compress the key to 33 bytes (prefix `0x02` if Y is even, `0x03` if odd) → SHA-256 → RIPEMD-160 → Base58Check encode to an XRP r-address.
2. **Create XRPL multisig account:**
   - Fund a new XRPL account with sufficient XRP for reserve requirements.
   - Submit a `SignerListSet` transaction on the XRPL account with each derived XRP address as a `SignerEntry` (weight `1`) and `SignerQuorum` set to the threshold.
   - Submit an `AccountSet` transaction with the `asfDisableMaster` flag to disable the master key.
   - The resulting multisig account is configured with:
     - Each signer has `SignerWeight = 1`.
     - `SignerQuorum` is set to the specified threshold.
     - `disableMasterKey = true` (master key disabled).
     - No regular key set.
   - See [xrpl-multisig-configuration.md](xrpl-multisig-configuration.md) Step 2 for full details on XRPL account setup.
3. **Request and verify PMWMultisigAccountConfigured attestation for each proxy:**
   - For each proxy independently:
     - Call `TeeVerification.RequestPMWMultisigAccountConfiguredAttestation(walletId, sourceId, multisigAddress, teeId)` on the C-chain.
     - Parse the `TeeInstructionsSent` event to get the `instructionId`.
     - Poll the proxy's `/action/result/<instructionId>` endpoint until the proof is available.
     - Verify the proof on-chain via `TeeVerification.verifyPMWMultisigAccountConfiguredProof(walletId, proof)`.
   - The last verified proof is used for the next step.
4. **Add PMW multisig account** -- a single on-chain operation:
   - Call `TeePayment.AddPMWMultisigAccount(walletId, proof)` to register the multisig account.
5. **Set batch settings:**
   - Call `TeePayment.SetBatchSettings(pmwMultisigAccount, batchSize, batchIndex)` to configure payment batching.

**Events emitted:** `TeeInstructionsSent` (per attestation request), plus payment contract events for `AddPMWMultisigAccount` and `SetBatchSettings`.

See [xrpl-multisig-configuration.md](xrpl-multisig-configuration.md) for the single-TEE flow and [fdc2-attestation.md](fdc2-attestation.md) for the PMWMultisigAccountConfigured attestation details.

---

### Step 4: Execute Distributed XRP Payment -- `TeePayments.pay()`

**Who can call:** Project owner or authorized address.

**Parameters:**
- `pmwMultisigAccount` (`ITeePaymentsPMWMultisigAccount`) -- contains `sourceId` and `accountAddress` (the multisig address).
- `paymentInstruction` (`ITeePaymentsPaymentInstruction`) -- contains `recipientAddress`, `amount`, `fee`, and `paymentReference`.

**Requirements:**
- Multisig account must be registered via `AddPMWMultisigAccount`.
- Batch settings must be configured.
- Sufficient TEE machines must be available to meet the signing threshold.

**What happens:**
1. **Send payment instruction** -- a single on-chain transaction:
   - Call `TeePayment.Pay(pmwMultisigAccount, paymentInstruction)` on the C-chain.
   - This emits a `TeeInstructionsSent` event with the `instructionId`.
   - The instruction is picked up by all TEE relay clients monitoring the chain.
2. **Each TEE independently signs the transaction (automatic):**
   - Each TEE node receives the payment instruction via its relay client and proxy.
   - Each TEE constructs the XRPL payment transaction and signs it with its own private key.
   - The signed transaction is available via the proxy's action result endpoint.
3. **Collect partial signatures from each proxy:**
   - For each proxy URL, call `GET <proxy_url>/action/result/<instructionId>` to retrieve the `ActionResponse` JSON.
   - Extract the XRP transaction with that TEE's partial signature from the response `data` field.
4. **Aggregate signatures into a final multisig transaction:**
   - Collect the `Signers` arrays from each proxy's response and merge them into a single XRPL `Payment` transaction object.
5. **Submit aggregated transaction to XRPL:**
   - Serialize the aggregated multisig transaction and submit it to the XRPL node via WebSocket: `{"command": "submit", "tx_blob": "<serialized_tx>"}`.
   - If the initial submission fails (engine result is not `tesSUCCESS`), a reissue can be attempted via `TeePayment.Reissue()` with an updated fee and the failed transaction's sequence number.
6. **Verify payment via PMWPaymentStatus attestation:**
   - Wait for the XRP indexer to catch up (typically a few seconds).
   - Submit an attestation request via `Fdc2Hub.requestAttestation(0, numberOfTees, teeIds, cosigners, cosignersThreshold, attestationType, sourceId, requestBody)` where `attestationType = bytes32("PMWPaymentStatus")` and `requestBody` is the ABI-encoded struct `(opType, senderAddress, nonce, subNonce)`.
   - Retrieve and verify the `PMWPaymentStatusProof` from each proxy via `GET <proxy_url>/action/result/<instructionId>`.
   - Verify the proof on-chain via `PMWPaymentStatusVerifier.verify(teePaymentsAddress, proof)`.

**Events emitted:** `TeeInstructionsSent` (for payment and for PMWPaymentStatus attestation).

See [xrp-payment.md](xrp-payment.md) for the single-TEE payment flow and [fdc2-attestation.md](fdc2-attestation.md) for PMWPaymentStatus attestation details.

---

## Notes

- **Comparison — single-TEE vs multi-TEE operations:**

  | Aspect | Single TEE | Multi-TEE |
  |--------|-----------|-----------|
  | Trust model | Single machine | Distributed across N machines |
  | Key generation | All keys on one TEE | One key per TEE |
  | Key storage | Single point of storage | Keys distributed across machines |
  | Signing | Single TEE signs all keys | Each TEE signs with its own key |
  | Transaction assembly | Direct from one proxy | Aggregate partial signatures from all proxies |
  | Multisig threshold | Can be 1-of-N (all keys local) | Typically k-of-N across machines (e.g., 2-of-3) |
  | Fault tolerance | Single point of failure | Threshold-based (e.g., 2-of-3 tolerates 1 failure) |
  | Attestation verification | One TEE verifies | Each TEE verifies independently |
  | Setup complexity | Simple -- single proxy | Requires coordination across N proxies |
  | Payment flow | Sign and submit from one proxy | Collect signatures from each proxy, aggregate, then submit |

- **Related workflows:** For single-TEE equivalents of each step, see: [machine-registration.md](machine-registration.md) for registration, [wallet-setup.md](wallet-setup.md) for wallet creation and key generation, [xrpl-multisig-configuration.md](xrpl-multisig-configuration.md) for XRPL multisig setup, and [xrp-payment.md](xrp-payment.md) for XRP payments. For attestation details, see [fdc2-attestation.md](fdc2-attestation.md). For key operations, see [key-add.md](key-add.md), [key-delete.md](key-delete.md), and [key-restore.md](key-restore.md).

