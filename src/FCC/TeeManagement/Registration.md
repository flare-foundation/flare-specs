# TEE Machine Registration and Management
TEE ownership on Flare is decentralized: permitted operators of TEE machines can register their devices on the network to participate in Flare Confidential Compute's protocols. 
Owners are incentivized to participate in Flare Confidential Compute via a [rewarding mechanism](../../FSP/Rewarding.md).
This page documents the responsibilities of TEE owners on Flare, including registration, management, and upgrading.

## Owner Allowlist
Machine ownership and [wallet project ownership](Wallets.md) are gated by the `TeeOwnerAllowlist` contract.
Each extension maintains its own allowlist, defining permitted machine owners and permitted wallet project owners on the extension.
The allowlist is checked as part of several functions:

- `TeeMachineRegistry.register()`: The registering owner must be allowlisted as a machine owner for the extension.
- `TeeMachineRegistry.proposeNewOwner()`: The proposed new owner must be allowlisted (or `address(0)` to cancel).
- `TeeMachineRegistry.confirmOwnership()`: The confirming owner must still be allowlisted at confirmation time.
- `TeeWalletProjectManager.createProject()`: The caller must be allowlisted as a wallet project owner for the extension.

The extension owner adds and removes entries from the allowlist via `addAllowedTeeMachineOwners`, `removeAllowedTeeMachineOwners`, `addAllowedTeeWalletProjectOwners`, and `removeAllowedTeeWalletProjectOwners`.
An extension can also enable open access (allow any address) by calling `allowAllTeeMachineOwners` or `allowAllTeeWalletProjectOwners`.

## Registration
Registration is the process by which a TEE owner deploys their TEE machine for operation within Flare Confidential Compute.
When a TEE is registered, it is registered to a specific TEE [extension](../Extensions/README.md), and not the network as a whole.
To register a TEE, its owner submits a transaction:

```solidity
register(machineData, signature, teeProxyId, teeUrl)
```
to the `teeMachineRegistry` smart contract.
Here, `signature` is the signature over the `machineData` performed by the TEE's identity key pair and the `teeProxyId` the identity of the TEE's [proxy](../Components/TeeProxy.md).
The `machineData` field is in the following format:

1. **extensionId**: The ID of the extension to which the TEE is registered.
2. **initialOwner**: The address of the initial owner of the TEE machine.
3. **codeHash**: The hash of the code deployed on the machine, identifying its code version.
4. **platform**: The attestation platform for the TEE (e.g. `GOOGLE_INTEL`, `GOOGLE_AMD`), which determines how an attestation of its state is encoded.
5. **publicKey**: The public key of the TEE, corresponding to its identity.

The registration transaction places the machine in an `INITIALIZED` status.
To complete registration and enter production, an [FDC2](../Extensions/FDC2/README.md) `teeAvailabilityCheck` attestation proof must be obtained and submitted via `toProduction(proof)`, confirming that the machine's state is correct.
Once the attestation proof is accepted, the status changes to `PRODUCTION`, indicating that the machine is active on its extension.

### TEE ID derivation

A TEE machine's identity is a public/private key pair generated inside the enclave at deployment.
The corresponding `teeId` is the Ethereum-style address of that public key — the last $20$ bytes of $\mathrm{keccak256}(\mathrm{publicKey})$, the same derivation Flare uses for ordinary addresses.

`teeId` is therefore _not_ the address of the caller of `register`.
The caller (constrained by `msg.sender == machineData.initialOwner`) is the [TEE operator](../../Terminology/Roles.md#tee-operator), recorded separately as the machine's owner.
The `signature` argument is a proof-of-possession of the TEE's identity private key over $\mathrm{keccak256}(\mathrm{ABI.encode}(\mathrm{machineData}))$, produced following the [Ethereum Signed Message](../../Utilities/Signing.md) procedure.
The contract recovers the signer address from this signature and requires it to equal `address(publicKey)`, then stores that address as `teeId`.
This binds `teeId` to a specific TEE without trusting the caller, and prevents anyone from registering a `teeId` whose private key they do not control.

### Machine Registry Contract
The `teeMachineRegistry` smart contract keeps a record of each registered TEE machine, consisting of:

1. **teeId**: The TEE's public identity.
2. **url**: The URL of the TEE machine.
3. **owner**: The Flare address of the TEE owner.
4. **codeHash**: The hash of the deployed code.
5. **platform**: The attestation platform.
6. **status**: The current machine status.
7. **lastStatusChangeTs**: The timestamp of the last status change.

## Statuses
A registered TEE machine can have one of the following statuses:

1. `INITIALIZED`: Initial status after registration, indicating that the machine is not yet verified and operational. Allows transitioning to `PRODUCTION` via `toProduction()`.
2. `PRODUCTION`: The machine is fully operational and accepts all instructions. Allows pausing and suspending.
3. `SUSPENDED`: The machine has been suspended, either by a non-availability proof submitted via `pauseWithProof()` (using the [`TeeAvailabilityCheck`](../Extensions/FDC2/AttestationTypes/TeeAvailabilityCheck.md) attestation) or by anyone calling `pause()` after the [availability deadline](#availability-deadline) expired. Can transition to `PAUSED` via owner-initiated `pause()`, back to `PRODUCTION` via `toProduction()` with a fresh availability proof, or be banned.
4. `PAUSED`: The machine has been paused by the owner, an unsupported code version, a settings update, or an unban. Prevents receiving any instructions. Can be reverted to `PRODUCTION` by providing a new availability proof.
5. `BANNED`: The machine has been banned and cannot operate. This status can only be reversed by `unban()`, which moves the status to `PAUSED`.

### Availability Deadline
When a machine enters `PRODUCTION` status via `toProduction(proof)`, it is considered in production only up to a certain timestamp (`availabilityCheckValidityEndTs`).
Before this deadline, anyone may submit a fresh availability proof via `confirmAvailability(proof)` on the `teeVerification` contract to extend the deadline.

If the deadline passes without confirmation, the machine remains in `PRODUCTION` but:

- its actions no longer entitle its owner to rewards;
- anyone may call `pause(teeId)`, transitioning the machine to `SUSPENDED` and removing it from its extension's active set.
  To return it to `PRODUCTION`, anyone may then call `toProduction(proof)` with a fresh availability proof.

Operators must therefore monitor the deadline and refresh it before expiry, or be prepared to recover promptly.

## Management
The Flare address of the TEE owner is responsible for managing the TEE's activities on the network.
Management functions are spread across two contracts: `teeMachineRegistry` and `teeVerification`.
The following set of management functions are available to the TEE owner:

### teeMachineRegistry Functions
1. `register(machineData, signature, teeProxyId, teeUrl)`: Registers the TEE machine as described above.
2. `toProduction(proof)`: Changes the status to `PRODUCTION` if the proof matches the TEE ID data, the status permits it, and the code version is still supported.  Can be called by the owner when the machine status is `INITIALIZED` or `PAUSED`; can be called by anyone when `SUSPENDED`.
3. `pause(teeId)`: Changes the status of a machine in `PRODUCTION` or `SUSPENDED` status. The owner can call it (or anyone if the current code version is disabled), transitioning the status to `PAUSED`. Anyone else can call it on a `PRODUCTION` machine after its [availability deadline](#availability-deadline) expires, transitioning the status to `SUSPENDED`.
4. `pauseWithProof(proof)`: Suspends the TEE machine (sets status to `SUSPENDED`) based on a non-availability proof using the [`TeeAvailabilityCheck`](../Extensions/FDC2/AttestationTypes/TeeAvailabilityCheck.md) attestation type. The timestamp of the proof must not be older than $10$ minutes. Can be called by anyone.
5. `proposeNewOwner(teeId, newOwner)`: Proposes a new owner for the TEE machine. Can only be called by the current owner.
6. `confirmOwnership(teeId)`: Called by the proposed new owner of the machine. When called after `proposeNewOwner(teeId, newOwner)`, the ownership of the TEE machine on Flare is changed to `newOwner`.
7. `updateTeeMachineSettings(teeId, teeProxyId, url)`: Updates the proxy ID and URL of the TEE machine. Available when the machine is in `PRODUCTION` or `SUSPENDED` status. Any change sets the status to `PAUSED`, and a new proof is needed to return it to `PRODUCTION`.
8. `ban(teeId)`: Bans a TEE machine, setting its status to `BANNED`. Can only be called by the extension owner.
9. `unban(teeId)`: Unbans a previously banned TEE machine, setting its status to `PAUSED`. Can only be called by the extension owner.

### teeVerification Functions

1. `confirmAvailability(proof)`: Given a valid [`TeeAvailabilityCheck`](../Extensions/FDC2/AttestationTypes/TeeAvailabilityCheck.md) proof, extends the availability deadline. Can be called by anyone.

When any function changes the machine status, the `lastStatusChangeTs` is updated to the current `block.timestamp`.
Note that once an owner registers a TEE ID and the proof has been provided, the machine belongs to that owner.
This prevents re-registration of the machine under other owners if it is temporarily unregistered.
A TEE ID can only be transferred to a new owner through the ownership change process while registered.