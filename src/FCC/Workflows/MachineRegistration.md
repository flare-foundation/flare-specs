# MachineRegistration

State machine for one TEE machine from a freshly-booted Confidential VM to on-chain `PRODUCTION` status.
For ongoing operations on a registered machine, see [MachineLifecycle](MachineLifecycle.md); for the underlying concepts, [Concepts/Machines](../Concepts/Machines.md).

## Preconditions

- An [extension is configured](../FCE/Workflows/Configuration.md) on chain with the desired `(codeHash, platform)` registered (`addTeeVersion`).
- The machine's intended owner address is on the extension's [machine-owner allowlist](../Concepts/Machines.md#owner-allowlist) and holds enough Flare to cover instruction fees.
- A [TEE proxy](../Reference/Components/Proxy.md) is reachable from the machine.
- The [Fdc2Hub](../FDC2/Reference/Contracts/Fdc2Hub.md) is deployed on the target network (used by the availability-check proof flow).

## States

- `Booted` — the Confidential VM is running; the TEE machine has generated its identity key pair and `teeId` is the derived address. No proxy URL, no initial owner, no extension ID is configured locally yet.
- `LocallyConfigured` — proxy URL, initial owner, and extension ID are set on the machine (via the Configuration API on port `5500` or environment variables) and the machine is paired with its proxy.
- `Initialized` — `register(...)` has run; `wallet.status = INITIALIZED`; the contract has auto-enqueued a [`TEE_ATTESTATION`](../Reference/Operations/F_REG.md#tee_attestation) instruction.
- `Attested` — the [`TeeAvailabilityCheck`](../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md) FDC2 sub-workflow has produced a valid `OK` proof for the machine.
- `Production` — `toProduction(proof)` has accepted the proof; the machine is in the active set and may serve instructions. `availabilityCheckValidityEndTs` is set.

## Initial State

`Booted` (immediately after VM startup).

## Transitions

### configureLocally: Booted → LocallyConfigured

- **Action**: three TEE-machine Configuration API calls (or environment variables):
  1. `POST /proxy` with the proxy URL.
  2. `POST /initial-owner` with the future `msg.sender` of `register()`.
  3. `POST /extension-id` with the target `extensionId`.
- **Caller**: machine operator (with network access to the machine's port `5500`).
- **Guards**:
  - `initialOwner` is immutable once set.
  - `extensionId` becomes immutable after the first successful [`TeeAvailabilityCheck`](../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md) proof.
- **Effects**:
  - The machine connects to the proxy and starts polling for actions.
  - The proxy's `GET /info` endpoint now serves a `SignedTeeInfoResponse` carrying `(teeId, publicKey, codeHash, platform, extensionId, initialOwner, attestation, dataSignature, proxySignature)` — the inputs to `register` come from here.

### register: LocallyConfigured → Initialized

- **Action**: [`FlareTeeManager.register(machineData, signature, teeProxyId, url, claimBackAddress)`](../Reference/Contracts/FlareTeeManager.md#registration) — payable.
- **Caller**: the `initialOwner` configured in `configureLocally`.
- **Guards**:
  - `msg.sender = machineData.initialOwner` and the owner is on the [machine-owner allowlist](../Concepts/Machines.md#owner-allowlist).
  - `signature` recovers to `address(machineData.publicKey)` (proof of possession of the TEE secret key).
  - `(machineData.codeHash, machineData.platform)` is supported by the extension ([Configuration § addTeeVersion](../FCE/Workflows/Configuration.md#addteeversion-registered--codeadded-repeatable) must already have run).
  - `teeProxyId ≠ 0`, `url` non-empty.
  - `teeId` (the address of `machineData.publicKey`) is not already registered.
  - `msg.value` covers the auto-enqueued attestation request.
- **Effects**:
  - Creates the machine record with `status = INITIALIZED`.
  - Auto-emits a [`TEE_ATTESTATION`](../Reference/Operations/F_REG.md#tee_attestation) request via [`requestTeeAttestation`](#requestteeattestation-initialized--initialized-fresh-challenge); the corresponding [`TeeInstructionsSent`](../Reference/Contracts/FlareTeeManagerEvents.md#teeinstructionssent) and [`TeeAttestationRequested`](../Reference/Contracts/FlareTeeManagerEvents.md#teeattestationrequested) events fire.
  - Emits [`TeeMachineRegistered`](../Reference/Contracts/FlareTeeManagerEvents.md#teemachineregistered).

### requestTeeAttestation: Initialized → Initialized (fresh challenge)

- **Action**: `FlareTeeManager.requestTeeAttestation(teeId, claimBackAddress)` — payable. Auto-fires inside `register`; only invoked standalone when the existing challenge has expired or needs refreshing.
- **Caller**: anyone.
- **Guards**: the machine is registered; `msg.value` covers the instruction fee.
- **Effects**:
  - Reuses the existing challenge if still within `challengeValidityDurationSeconds`; otherwise generates a fresh random challenge via the FSP `Relay` contract.
  - Sends a [`TEE_ATTESTATION`](../Reference/Operations/F_REG.md#tee_attestation) instruction to the machine; the TEE machine builds the [`Attestation`](../Reference/Types/Abi/TeeMachine.md#attestation) struct, hashes it, and obtains a platform-signed response (Google for Intel TDX / AMD SEV).
  - The signed attestation lands at the proxy as a [`TeeInfoResponse`](../Reference/Types/Wire/TeeMachine.md#teeinforesponse).

### attest: Initialized → Attested

- **Action**: run the [Fdc2Attestation](../FDC2/Workflows/Fdc2Attestation.md) sub-workflow with `attestationType = TeeAvailabilityCheck`, sourcing the machine's attestation from the previous step. In practice this is `requestAvailabilityCheckAttestation(teeId, instructionId, …)` followed by the standard FDC2 voting and proof-retrieval flow.
- **Caller**: anyone.
- **Guards**: the `TEE_ATTESTATION` challenge is still fresh; FDC2 thresholds are met; the verifier confirms the machine is reachable at `url`, its `codeHash`/`platform` match the registered version, and its `state`/signing policies are correct.
- **Effects**: a valid [`TeeAvailabilityCheck`](../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md) proof with `responseBody.status = OK` is available at the proxy.

### toProduction: Attested → Production

- **Action**: [`FlareTeeManager.toProduction(proof)`](../Reference/Contracts/FlareTeeManager.md#management-calls) — non-payable.
- **Caller**: machine owner.
- **Guards**:
  - `status = INITIALIZED` (also accepted from `PAUSED`/`SUSPENDED` for re-entry, see [MachineLifecycle](MachineLifecycle.md)).
  - `proof.status = OK` and the underlying machine `codeHash`/`platform` are still supported.
- **Effects**:
  - First time only: records `initialSigningPolicyId` from `proof.responseBody`.
  - Status → `PRODUCTION`; sets `availabilityCheckValidityEndTs`.
  - Emits [`TeeMachineStatusChanged`](../Reference/Contracts/FlareTeeManagerEvents.md#teemachinestatuschanged) and [`AvailabilityCheckValidityExtended`](../Reference/Contracts/FlareTeeManagerEvents.md#availabilitycheckvalidityextended).

## Invariants

- The on-chain `teeId` is bit-equal to the address derived from the TEE-generated `publicKey`; the registration `signature` is the only proof that the off-chain operator controls the corresponding private key.
- `initialOwner` is immutable from `LocallyConfigured` onward; `extensionId` is immutable from `Attested` onward.
- Reaching `Production` requires a `TeeAvailabilityCheck` proof from the FDC2 sub-workflow; no other path exists.

## Terminal States

`Production`. From here [MachineLifecycle](MachineLifecycle.md) takes over — periodic [`confirmAvailability`](MachineLifecycle.md#confirmavailability-production--production-deadline-refresh) keeps the machine reward-eligible; `pause`/`pauseWithProof`/`ban` may move it through the other lifecycle states.

## Notes

- The Configuration API and the three setters can be replaced by the `PROXY_URL`, `INITIAL_OWNER`, and `EXTENSION_ID` environment variables at machine boot.
- `register` is `payable` because it auto-enqueues the first attestation request. Operators typically fund a margin above the minimum so the machine can also handle the FDC2 availability check immediately.
- The `claimBackAddress` parameter on `register` reclaims the prepaid TEE fee if attestation fails before the machine reaches `Production`.
