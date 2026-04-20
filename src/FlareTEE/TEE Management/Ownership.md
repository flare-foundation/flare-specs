# TEE Machine Registration and Management
TEE ownership on Flare is decentralized: permitted operators of TEE machines can register their devices on the network to participate in Flare Confidential Compute's protocols. 
Owners are incentivized to participate in Flare Confidential Compute via a [rewarding mechanism](../../FSP/Rewarding.md).
This page documents the responsibilities of TEE owners on Flare, including registration, management, and upgrading.

## Owner Allowlist
Machine ownership and [wallet project ownership](../Operations/Projects%20and%20Ownership.md) are gated by the `TeeOwnerAllowlist` contract.
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
When a TEE is registered, it is registered to a specific TEE [extension](../Extensions/Extensions.md), and not the network as a whole.
To register a TEE, its owner submits a transaction:

```solidity
register(machineData, signature, teeProxyId, teeUrl)
```
to the `teeMachineRegistry` smart contract.
Here, `signature` is the signature over the `machineData` performed by the TEE's identity key pair and the `teeProxyId` the identity of the TEE's [proxy](Tee Proxies.md).
The `machineData` field is in the following format:

1. **extensionId**: The ID of the extension to which the TEE is registered.
2. **initialOwner**: The address of the initial owner of the TEE machine.
3. **codeHash**: The hash of the code deployed on the machine, identifying its code version.
4. **platform**: The attestation platform for the TEE (e.g. `GOOGLE_INTEL`, `GOOGLE_AMD`), which determines how an attestation of its state is encoded.
5. **publicKey**: The public key of the TEE, corresponding to its identity.

The registration transaction places the machine in an `INITIALIZED` status.
To complete registration and enter production, an [FDC2](../Extensions/FTDC.md) `teeAvailabilityCheck` attestation proof must be obtained and submitted via `toProduction(proof)`, confirming that the machine's state is correct.
Once the attestation proof is accepted, the status changes to `PRODUCTION`, indicating that the machine is active on its extension.

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
3. `SUSPENDED`: The machine has been suspended based on a non-availability proof ([`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md) attestation). Can transition to `PAUSED` via `pause()` or be banned.
4. `PAUSED`: The machine has been paused by the owne, an unsupported code version, a settings update, or an unban. Prevents receiving any instructions. Can be reverted to `PRODUCTION` by providing a new availability proof.
5. `BANNED`: The machine has been banned and cannot operate. This status can only be reveresed by `unban()`, which moves the status to `PAUSED`.

### Availability Deadline
When a machine enters `PRODUCTION` status via `toProduction(proof)`, it is considered in production only up to a certain timestamp (`availabilityCheckValidityEndTs`).
Before this deadline, a proof that the machine is still available must be submitted using `confirmAvailability(proof)` on the `teeVerification` contract, which extends the deadline.
This function can be called by anyone.
If the deadline passes without confirmation, the actions of the TEE machine no longer entitle its owner to rewards.

## Management
The Flare address of the TEE owner is responsible for managing the TEE's activities on the network.
Management functions are spread across two contracts: `teeMachineRegistry` and `teeVerification`.
The following set of management functions are available to the TEE owner:

### teeMachineRegistry Functions
1. `register(machineData, signature, teeProxyId, teeUrl)`: Registers the TEE machine as described above.
2. `toProduction(proof)`: Changes the status to `PRODUCTION` if the proof matches the TEE ID data, the status permits it, and the code version is still supported.  Can be called by the owner when the machine status is `INITIALIZED` or `PAUSED`; can be called by anyone when `SUSPENDED`.
3. `pause(teeId)`: Changes the status to `PAUSED`. Available when the machine status is `PRODUCTION` or `SUSPENDED`. Can be called by the owner, or by anyone if the current TEE code version is no longer supported.
4. `pauseWithProof(proof)`: Suspends the TEE machine (sets status to `SUSPENDED`) based on a non-availability proof using the [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md) attestation type. The timestamp of the proof must not be older than $10$ minutes. Can be called by anyone.
5. `proposeNewOwner(teeId, newOwner)`: Proposes a new owner for the TEE machine. Can only be called by the current owner.
6. `confirmOwnership(teeId)`: Called by the proposed new owner of the machine. When called after `proposeNewOwner(teeId, newOwner)`, the ownership of the TEE machine on Flare is changed to `newOwner`.
7. `updateTeeMachineSettings(teeId, teeProxyId, url)`: Updates the proxy ID and URL of the TEE machine. Available when the machine is in `PRODUCTION` or `SUSPENDED` status. Any change sets the status to `PAUSED`, and a new proof is needed to return it to `PRODUCTION`.
8. `ban(teeId)`: Bans a TEE machine, setting its status to `BANNED`. Can only be called by the extension owner.
9. `unban(teeId)`: Unbans a previously banned TEE machine, setting its status to `PAUSED`. Can only be called by the extension owner.

### teeVerification Functions

1. `confirmAvailability(proof)`: Given a valid [`TeeAvailabilityCheck`](../attestation-types/TeeAvailabilityCheck.md) proof, extends the availability deadline. Can be called by anyone.

When any function changes the machine status, the `lastStatusChangeTs` is updated to the current `block.timestamp`.
Note that once an owner registers a TEE ID and the proof has been provided, the machine belongs to that owner.
This prevents re-registration of the machine under other owners if it is temporarily unregistered.
A TEE ID can only be transferred to a new owner through the ownership change process while registered.