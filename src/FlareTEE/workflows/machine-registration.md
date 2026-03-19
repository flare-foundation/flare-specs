# TEE Machine Registration — From Boot to PRODUCTION

## Overview

This workflow describes the full process of deploying a TEE machine onto the Flare network, from the moment the Confidential VM boots through to reaching `PRODUCTION` status. The process involves local configuration of the TEE node, on-chain registration via the `TeeMachineRegistry` contract, attestation verification through the FTDC system, and ongoing availability confirmation.

## Prerequisites

- **Extension registered** on-chain with a valid extension ID (see [extension-configuration.md](extension-configuration.md))
- **TEE node running** inside a Google Cloud Confidential VM (MODE=0 for production, MODE=1 for local development)
- **TEE proxy running** and reachable by the TEE node (requires `PRIVATE_KEY` env var)
- **Smart contracts deployed** — `TeeMachineRegistry`, `TeeExtensionRegistry`, `TeeVerification`, and `FtdcHub` must be available on the target network
- **Funded owner account** — the Flare address that will own the TEE machine must have sufficient funds for transaction fees

---

## Phase 1: Local Configuration

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
- Once the machine is registered and verified via a `TeeAvailabilityCheck` proof, the extension ID becomes **fixed and cannot be changed**

**What happens:**

1. The owner sends a POST request to `<TEE_MACHINE_IP>:5500/extension-id` with the extension ID.
2. The TEE node stores the extension ID. The machine will be registered to this specific [extension](../Extensions.md), not the network as a whole.

**Example:**

```shell
curl --location '<TEE_MACHINE_IP>:5500/extension-id' \
  --header 'Content-Type: application/json' \
  --data '{"extensionId":"0xabcd..."}'
```

> Alternatively, set the `EXTENSION_ID` environment variable before the TEE node starts.

**Events emitted:** None (off-chain operation)

---

## Phase 2: Retrieve Machine Info

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

## Phase 3: On-Chain Registration

### Step 6: Register TEE Code Version (if new) — `TeeExtensionRegistry.addTeeVersion()`

**Who can call:** Extension governance address

**Parameters:**
- `extensionId` (uint256) — the extension ID
- `version` (string) — human-readable version string
- `codeHash` (bytes32) — hash of the TEE code image
- `platforms` (bytes32[]) — array of supported attestation platforms (e.g., `[GOOGLE_INTEL]`)
- `governanceHash` (bytes32) — TEE governance set hash

**Requirements:**
- Caller must have governance authority over the extension
- The code hash must not already be registered for this extension (unless adding new platforms)

**What happens:**

1. The governance address calls `TeeExtensionRegistry.addTeeVersion()` with the code hash, platforms, governance hash, and version string.
2. The registry stores the code version, making it a recognized version for the extension.
3. TEE machines running this code version can now be registered.

**Events emitted:** Version registration event (extension-specific)

---

### Step 7: Register TEE Machine — `TeeMachineRegistry.register()`

**Who can call:** Machine owner (the `initialOwner` address configured in Step 3)

**Parameters:**
- `machineData` (struct `ITeeMachineRegistryTeeMachineData`):
  - `extensionId` (uint256) — the extension ID
  - `initialOwner` (address) — the initial owner address
  - `codeHash` (bytes32) — hash of the deployed code
  - `platform` (bytes32) — attestation platform (e.g., `GOOGLE_INTEL`, `GOOGLE_AMD`)
  - `publicKey` (PublicKey: `{x: bytes32, y: bytes32}`) — the TEE's public key
- `signature` (Signature: `{v: uint8, r: bytes32, s: bytes32}`) — signature over `machineData` by the TEE machine's private key, proving consent to registration
- `teeProxyId` (address) — identity of the proxy server relaying information to/from the TEE
- `teeUrl` (string) — URL at which the TEE machine is reachable via the proxy

**Requirements:**
- The transaction sender must match the `initialOwner` in `machineData`
- The signature must be valid over the machine data, signed by the TEE's private key
- The code hash and platform must correspond to a supported code version on the extension
- The teeId must not already be registered

**What happens:**

1. The contract verifies the signature proves the TEE machine consents to registration.
2. A machine record is created in the `TeeMachineRegistry` with the provided data.
3. The machine status is set to `INITIALIZED`.
4. `lastStatusChangeTs` is set to `block.timestamp`.
5. A TEE attestation request is automatically triggered as part of registration.

`Status: --> INITIALIZED`

**Events emitted:** Machine registered event, `TeeInstructionsSent` (attestation request)

---

### Step 8: Request TEE Attestation — `TeeVerification.requestTeeAttestation()`

**Who can call:** Machine owner

**Parameters:**
- `teeId` (address) — the TEE machine's identity

**Requirements:**
- The TEE machine must be registered (status `INITIALIZED` or later)

**What happens:**

1. The contract generates a random challenge (32-byte string).
2. A `TEE_ATTESTATION` instruction is sent to the TEE machine via the instruction system.
3. The TEE machine generates a challenge hash by ABI-encoding and hashing an `Attestation` struct containing: the challenge, public key, signing policy information, TEE state, and timestamp.
4. The platform provider (e.g., Google Cloud) signs the challenge hash and returns the attestation response.
5. The attestation result becomes available at the proxy.

> **Note:** In practice, this step is typically combined with registration (Step 7) — calling `register()` automatically triggers the attestation request. The standalone `requestTeeAttestation()` is available for cases where attestation must be re-requested separately.

**Events emitted:** `TeeInstructionsSent` (attestation instruction)

---

### Step 9: FTDC Availability Check — `TeeVerification.requestAvailabilityCheckAttestation()`

**Who can call:** Machine owner

**Parameters:**
- `teeId` (address) — the TEE machine to check
- `teeAttestInstructionID` (bytes32) — instruction ID from the attestation request in Step 8
- `externalTeeId` (address) — identity of the FTDC TEE that will perform the verification

**Requirements:**
- The TEE attestation from Step 8 must have completed
- An FTDC-capable TEE must be available to perform the availability check

**What happens:**

1. The contract sends a `TeeAvailabilityCheck` attestation request through the FTDC system.
2. The FTDC verifier TEE challenges the target machine and verifies:
   - The machine is reachable at the registered URL
   - The attestation response is valid and fresh
   - The code hash matches the registered version
   - The platform matches
   - The signing policies are correct
3. The verifier produces a proof (signed by data providers) that the machine is available and correctly configured.
4. The proof result can be retrieved from the proxy via `GET /action/result/<instructionId>`.

For more details on the FTDC attestation process, see [ftdc-attestation.md](ftdc-attestation.md).

**Events emitted:** `TeeInstructionsSent` (FTDC instruction)

---

### Step 10: Move to Production — `TeeMachineRegistry.toProduction()`

**Who can call:** Machine owner

**Parameters:**
- `proof` (struct `ITeeAvailabilityCheckProof`):
  - `signatures` — FTDC signing policy signatures
  - `header` — FTDC response header
  - `requestBody` — the availability check request (contains `teeId`, `url`, `challenge`)
  - `responseBody` — the availability check response (contains `status`, `teeTimestamp`, `codeHash`, `platform`, signing policy IDs, `state`)

**Requirements:**
- The machine must be in `INITIALIZED` status (or `PAUSED` / `PAUSED_WITH_PROOF` for re-activation)
- The proof must be a valid `TeeAvailabilityCheck` proof matching the TEE's identity and data
- The code version referenced in the proof must still be supported on the extension

**What happens:**

1. The contract validates the FTDC `TeeAvailabilityCheck` proof — verifies signatures, checks that the proof data matches the registered machine.
2. The machine status changes from `INITIALIZED` to `PRODUCTION`.
3. `lastStatusChangeTs` is updated to `block.timestamp`.
4. An `availabilityCheckValidityEndTs` deadline is set, defining how long the machine is considered available.
5. The machine is now fully operational and can accept instructions on its extension.

`Status: INITIALIZED --> PRODUCTION`

**Events emitted:** Status change event

---

## Phase 4: Ongoing Operations

### Step 11: Periodic Availability Confirmation — `TeeMachineRegistry.confirmAvailability()`

**Who can call:** Anyone

**Parameters:**
- `proof` (struct `ITeeAvailabilityCheckProof`) — a fresh `TeeAvailabilityCheck` attestation proof

**Requirements:**
- The machine must be in `PRODUCTION` status
- The proof must be valid and match the machine's current data

**What happens:**

1. Given a valid `TeeAvailabilityCheck` proof, the contract extends the availability deadline (`availabilityCheckValidityEndTs`).
2. This must be called periodically before the current deadline expires.
3. If the deadline passes without confirmation, the machine becomes ineligible for reward shares.

For more details on the machine lifecycle after production, see [machine-lifecycle.md](machine-lifecycle.md).

**Events emitted:** Availability confirmed event

---

## Further Resources

| Step | Reference Implementation |
|------|------------------------|
| Steps 7-10 (register → production) | `e2e/pkg/utils/setup.go` (`RegisterNode`) |
| Steps 8-9 (attestation + FTDC) | `e2e/pkg/utils/registration.go` |

