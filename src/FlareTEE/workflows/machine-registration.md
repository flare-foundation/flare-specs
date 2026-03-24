# TEE Machine Registration — From Boot to PRODUCTION

## Overview

This workflow describes deploying a TEE machine onto the Flare network, from Confidential VM boot through to `PRODUCTION` status.

## Prerequisites

- **Extension registered** on-chain with a valid extension ID (see [extension-configuration.md](extension-configuration.md))
- **TEE node running** inside a Google Cloud Confidential VM (MODE=0 for production, MODE=1 for local development)
- **TEE proxy running** and reachable by the TEE node (requires `PRIVATE_KEY` env var)
- **Smart contracts deployed** — `TeeMachineRegistry`, `TeeExtensionRegistry`, `TeeVerification`, and `Fdc2Hub` must be available on the target network
- **Funded owner account** — the Flare address that will own the TEE machine must have sufficient funds for transaction fees

---

## Steps

*Phase 1: Local Configuration*

### Step 1: Boot Confidential VM — Identity Key Generation

**Who can call:** Infrastructure operator

**What happens:**

1. The Confidential VM starts and the TEE node process launches.
2. The TEE generates an identity key pair (TEE_pk, TEE_sk) inside the secure enclave.
3. The machine's identity `teeId` is derived as the Ethereum address corresponding to TEE_pk.
4. The public key is represented on-chain as a `PublicKey` struct with `x` and `y` (bytes32) components.
5. The identity key is stored securely in the memory of the machine and never leaves the TEE boundary.

**Events emitted:** None (off-chain operation)

---

### Step 2: Configure Proxy URL — `POST /proxy`

**Who can call:** Machine owner (via Config API, port 5500)

**Parameters:**
- `url` (string) — URL of the TEE proxy to connect to (e.g., `http://<TEE_PROXY_INTERNAL_IP>:6661`)

**Requirements:**
- TEE node must be running and Config API accessible on port 5500
- The URL must be well-formed

**What happens:**

1. The owner sends a POST request to `<TEE_MACHINE_IP>:5500/proxy` with the proxy URL.
2. The TEE node stores the proxy URL and begins connecting to the specified proxy.

**Example:**

```shell
curl --location '<TEE_MACHINE_IP>:5500/proxy' \
  --header 'Content-Type: application/json' \
  --data '{"url":"http://<TEE_PROXY_INTERNAL_IP>:6661"}'
```

> Alternatively, set the `PROXY_URL` environment variable before the TEE node starts.

**Events emitted:** None (off-chain operation)

---

### Step 3: Set Initial Owner — `POST /initial-owner`

**Who can call:** Machine owner (via Config API, port 5500)

**Parameters:**
- `owner` (address) — Ethereum address of the initial owner

**Requirements:**
- Must be called before on-chain registration
- Once set, the initial owner is permanently recorded and **immutable**

**What happens:**

1. The owner sends a POST request to `<TEE_MACHINE_IP>:5500/initial-owner` with the owner address.
2. The TEE node stores this as the initial owner. The smart contract will validate during registration that the transaction sender matches this value.

**Example:**

```shell
curl --location '<TEE_MACHINE_IP>:5500/initial-owner' \
  --header 'Content-Type: application/json' \
  --data '{"owner":"0x1234..."}'
```

> Alternatively, set the `INITIAL_OWNER` environment variable before the TEE node starts.

**Events emitted:** None (off-chain operation)

---

### Step 4: Set Extension ID — `POST /extension-id`

**Who can call:** Machine owner (via Config API, port 5500)

**Parameters:**
- `extensionId` (bytes32) — The extension ID to register the machine against

**Requirements:**
- Must be called before on-chain registration
- Once the machine is registered and verified via a [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md) proof, the extension ID becomes **fixed and cannot be changed**

**What happens:**

1. The owner sends a POST request to `<TEE_MACHINE_IP>:5500/extension-id` with the extension ID.
2. The TEE node stores the extension ID. The machine will be registered to this specific [extension](../Extensions/Extensions.md), not the network as a whole.

**Example:**

```shell
curl --location '<TEE_MACHINE_IP>:5500/extension-id' \
  --header 'Content-Type: application/json' \
  --data '{"extensionId":"0xabcd..."}'
```

> Alternatively, set the `EXTENSION_ID` environment variable before the TEE node starts.

**Events emitted:** None (off-chain operation)

---

*Phase 2: Retrieve Machine Info*

### Step 5: Get Machine Data from Proxy — `GET /info`

**Who can call:** Anyone (public endpoint on external proxy port 6662)

**Requirements:**
- TEE node must be connected to the proxy
- Proxy must be running and reachable

**What happens:**

1. A GET request is made to the proxy's external endpoint: `<PROXY_URL>/info`.
2. The proxy returns a `SignedTeeInfoResponse` containing:
   - `teeId` — the machine's identity address (derived from TEE_pk)
   - `publicKey` — the TEE's public key (x, y components)
   - `codeHash` — hash of the deployed code image
   - `platform` — attestation platform identifier (e.g., `GOOGLE_INTEL`, `GOOGLE_AMD`)
   - `extensionId` — the configured extension ID
   - `initialOwner` — the configured initial owner address
   - `attestation` — the current attestation token
   - `dataSignature` — signature over the machine data by the TEE's private key
   - `proxySignature` — signature by the proxy, identifying the proxy ID
3. The code hash and platform can be independently verified from the attestation token to ensure consistency.

**Events emitted:** None (off-chain operation)

---

*Phase 3: On-Chain Registration*

### Step 6: Register TEE Code Version (if new) — `TeeExtensionRegistry.addTeeVersion()`

**Who can call:** Extension owner only.

**Parameters:**
- `extensionId` (uint256) — the extension ID
- `version` (string) — human-readable version string
- `codeHash` (bytes32) — hash of the TEE code image
- `platforms` (bytes32[]) — array of supported attestation platforms (e.g., `[GOOGLE_INTEL]`)
- `governanceHash` (bytes32) — TEE governance set hash

**Requirements:**
- `version` must be non-empty.
- `codeHash` must be non-zero.
- `platforms` array must be non-empty.
- All platforms must be system-supported.
- `governanceHash` must be `bytes32(0)` or match the latest governance hash for the extension.
- The code hash must not already be registered for this extension.

**What happens:**

1. The governance address calls `TeeExtensionRegistry.addTeeVersion()` with the code hash, platforms, governance hash, and version string.
2. The registry stores the code version, making it a recognized version for the extension.
3. TEE machines running this code version can now be registered.

**Events emitted:** [`TeeVersionAdded`](../Events.md#teeversionadded)

---

### Step 7: Register TEE Machine — `TeeMachineRegistry.register()`

**Who can call:** Machine owner (the `initialOwner` address configured in Step 3)

**Parameters:**
- `machineData` (struct `TeeMachineData`) — contains `extensionId`, `initialOwner`, `codeHash`, `platform`, and `publicKey`. These values come from the `/info` endpoint (Step 5). For the full struct definition, see the [Ownership specification](../TEE%20Management/Ownership.md#registration).
- `signature` (Signature: `{v: uint8, r: bytes32, s: bytes32}`) — signature over `machineData` by the TEE machine's private key, proving consent to registration
- `teeProxyId` (address) — identity of the proxy server relaying information to/from the TEE
- `url` (string) — URL at which the TEE machine is reachable via the proxy
- `claimBackAddress` (address) — address to claim back unused instruction fees

**Requirements:**
- The transaction sender must match the `initialOwner` in `machineData`.
- The owner must be allowlisted for the extension.
- The public key must be valid.
- The signature must be valid over the machine data, signed by the TEE's private key.
- The code hash and platform must correspond to a supported code version on the extension.
- `teeProxyId` must not be zero address.
- `url` must not be empty.
- The `teeId` must not already be registered.
- The function is `payable` — sufficient value must be included to cover the instruction fee.

**What happens:**

1. The contract verifies the signature proves the TEE machine consents to registration.
2. A machine record is created in the `TeeMachineRegistry` with the provided data.
3. The machine status is set to `INITIALIZED`.
4. `lastStatusChangeTs` is set to `block.timestamp`.
5. A TEE attestation request is automatically triggered as part of registration.

`Status: --> INITIALIZED`

**Events emitted:** [`TeeMachineRegistered`](../Events.md#teemachineregistered), [`TeeAttestationRequested`](../Events.md#teeattestationrequested), [`TeeInstructionsSent`](../Events.md#teeinstructionssent)

---

### Step 8: Request TEE Attestation — `TeeVerification.requestTeeAttestation()`

**Who can call:** Anyone.

**Parameters:**
- `teeId` (address) — the TEE machine's identity.
- `claimBackAddress` (address) — address to claim back unused instruction fees.

**Requirements:**
- The TEE machine must be registered.
- The function is `payable` — sufficient value must be included to cover the instruction fee.

**What happens:**

1. The contract checks if the previous challenge is still valid (within `challengeValidityDurationSeconds`). If so, it reuses the existing challenge. Otherwise, it generates a new random challenge via the Relay contract.
2. A [`TEE_ATTESTATION`](../commands/F_REG--TEE_ATTESTATION.md) instruction is sent to the TEE machine.
3. The TEE machine generates a challenge hash by ABI-encoding and hashing an `Attestation` struct containing: the challenge, public key, signing policy information, TEE state, and timestamp.
4. The platform provider (e.g., Google Cloud) signs the challenge hash and returns the attestation response.
5. The attestation result becomes available at the proxy.

> **Note:** In practice, this step is typically combined with registration (Step 7) — calling `register()` automatically triggers the attestation request. The standalone `requestTeeAttestation()` is available for cases where attestation must be re-requested separately.

**Events emitted:** [`TeeAttestationRequested`](../Events.md#teeattestationrequested), [`TeeInstructionsSent`](../Events.md#teeinstructionssent)

---

### Step 9: FDC2 Availability Check — `TeeVerification.requestAvailabilityCheckAttestation()`

**Who can call:** Anyone.

**Parameters:**
- `teeId` (address) — the TEE machine to check.
- `instructionId` (bytes32) — instruction ID from the attestation request in Step 8.
- `testOnTeeId` (address) — identity of the FDC2 TEE that will perform the verification (zero address in production).
- `proofOwner` (address) — address that will own the resulting proof (zero address for public proofs).
- `claimBackAddress` (address) — address to claim back unused instruction fees.

**Requirements:**
- The challenge from Step 8 must still be fresh (within `challengeValidityDurationSeconds`).
- The function is `payable` — sufficient value must be included to cover the instruction fee.

**What happens:**

1. The contract sends a [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md) attestation request through the FDC2 system.
2. The FDC2 verifier TEE challenges the target machine and verifies:
   - The machine is reachable at the registered URL
   - The attestation response is valid and fresh
   - The code hash matches the registered version
   - The platform matches
   - The signing policies are correct
3. The verifier produces a proof (signed by data providers) that the machine is available and correctly configured.
4. The proof result can be retrieved from the proxy via `GET /action/result/<instructionId>`.

For more details on the FDC2 attestation process, see [fdc2-attestation.md](fdc2-attestation.md).

**Events emitted:** [`TeeInstructionsSent`](../Events.md#teeinstructionssent) (FDC2 instruction)

---

### Step 10: Move to Production — `TeeMachineRegistry.toProduction()`

**Who can call:** Machine owner (when `INITIALIZED` or `PAUSED`). Anyone (when `SUSPENDED`).

**Parameters:**
- `proof` (struct `ITeeAvailabilityCheck.Proof`):
  - `signatures` — FDC2 signing policy signatures
  - `header` — FDC2 response header
  - `requestBody` — the availability check request (contains `teeId`, `teeProxyId`, `url`, `challenge`, `instructionId`)
  - `responseBody` — the availability check response (contains `status`, `teeTimestamp`, `codeHash`, `platform`, signing policy IDs, `state`)

**Requirements:**
- The machine must be in `INITIALIZED`, `PAUSED`, or `SUSPENDED` status.
- The proof's `responseBody.status` must be `OK`.
- The proof's `header.timestamp` must be $\geq$ `lastStatusChangeTs`.
- The proof must be a valid [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md) proof matching the TEE's identity and data.
- The code version referenced in the proof must still be supported on the extension.

**What happens:**

1. The contract validates the FDC2 [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md) proof — verifies signatures, checks that the proof data matches the registered machine.
2. If transitioning from `INITIALIZED`, the contract records `initialSigningPolicyId` from the proof's response body.
3. The machine status changes to `PRODUCTION`.
4. `lastStatusChangeTs` is updated to `block.timestamp`.
5. An `availabilityCheckValidityEndTs` deadline is set, defining how long the machine is considered available.
6. The machine is now fully operational and can accept instructions on its extension.

`Status: INITIALIZED/PAUSED/SUSPENDED --> PRODUCTION`

**Events emitted:** [`TeeMachineStatusChanged`](../Events.md#teemachinestatuschanged), [`AvailabilityCheckValidityExtended`](../Events.md#availabilitycheckvalidityextended)

---

*Phase 4: Ongoing Operations*

### Step 11: Periodic Availability Confirmation — `TeeVerification.confirmAvailability()`

**Who can call:** Anyone

**Parameters:**
- `proof` (struct `ITeeAvailabilityCheckProof`) — a fresh [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md) attestation proof

**Requirements:**
- The machine must be in `PRODUCTION` status.
- The proof's `responseBody.status` must be `OK`.
- The machine's `codeHash` and `platform` must still be supported by the extension.
- The proof must be valid and match the machine's current data.

**What happens:**

1. Given a valid [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md) proof, the contract extends the availability deadline (`availabilityCheckValidityEndTs`).
2. The contract updates `lastSigningPolicyId` from the proof's response body.
3. This must be called periodically before the current deadline expires.
4. If the deadline passes without confirmation, the machine becomes ineligible for reward shares.

For more details on the machine lifecycle after production, see [machine-lifecycle.md](machine-lifecycle.md).

**Events emitted:** [`AvailabilityCheckValidityExtended`](../Events.md#availabilitycheckvalidityextended)

