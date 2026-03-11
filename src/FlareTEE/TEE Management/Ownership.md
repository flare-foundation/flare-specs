# TEE Machine Registration and Management
TEE ownership on Flare is decentralized: permitted operators of TEE machines can register their devices on the network to participate in Flare Confidential Compute's protocols. 
Owners are incentivized to participate in Flare Confidential Compute via a [rewarding mechanism](Rewarding.md). 
This page documents the responsibilities of TEE owners on Flare, including registration, management, and upgrading.

## Registration
Registration is the process by which a TEE owner deploys their TEE machine for operation within Flare Confidential Compute.
When a TEE is registered, it is registered to a specific TEE [extension](Extension.md), and not the network as a whole.
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
To complete registration and enter production, an [FTDC](FTDC.md) `teeAvailabilityCheck` attestation proof must be obtained and submitted via `toProduction(proof)`, confirming that the machine's state is correct.
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
A registered TEE machine can have one of seven statuses:

1. `INITIALIZED`: Initial status after registration, indicating that the machine is not yet verified and operational. Allows either triggering `REPLICATE_FROM` or transitioning to `PRODUCTION` via `toProduction()`.
2. `PRODUCTION`: The machine is fully operational and accepts all instructions. Allows pausing and pausing for upgrade.
3. `SUSPENDED`: The machine has been paused based on a non-availability proof (`TeeAvailabilityCheck` attestation). Can be resumed by providing a new valid proof.
4. `PAUSED`: The machine has been paused by the owner or a pausing address. Prevents receiving any instructions. Can be reverted to `PRODUCTION` by providing a new availability proof.
5. `PAUSED_FOR_UPGRADE`: The machine is not operational but can be used as a replication source for a TEE machine with a newer code version. This status is triggered by the `TO_PAUSE_FOR_UPGRADE` [instruction](Instructions.md). Allows repeated calls to `toPauseForUpgrade(teeId)` and nothing else.
6. `REPLICATING`: The machine is currently being replicated to  another machine as part of an upgrade.
7. `BANNED`: The machine has been banned and cannot operate. This is a terminal status.

### Availability Deadline
When a machine enters `PRODUCTION` status via `toProduction(proof)`, it is considered in production only up to a certain timestamp (`availabilityCheckValidityEndTs`).
Before this deadline, a proof that the machine is still available must be submitted using `confirmAvailability(proof)` on the `teeVerification` contract, which extends the deadline.
This function can be called by anyone.
If the deadline passes without confirmation, the actions of the TEE machine no longer entitle its owner to rewards.

## Management
The Flare address of the TEE owner is responsible for managing the TEE's activities on the network.
Management functions are spread across three contracts: `teeMachineRegistry`, `teeVerification`, and `teeReplication`.

### `teeMachineRegistry` Functions

1. `register(machineData, signature, teeProxyId, teeUrl)`: Registers the TEE machine as described above.
2. `toProduction(proof)`: Changes the status to `PRODUCTION` if the proof matches the TEE ID data, the status permits it, and the code version is still supported. Can only be called by the owner.
3. `pause(teeId)`: Changes the status to `PAUSED`. Only available when the machine status is `PRODUCTION`. Can be called by the owner, or by anyone if the current TEE code version is no longer supported.
4. `pauseWithProof(proof)`: Pauses the TEE machine based on a non-availability proof using the `TeeAvailabilityCheck` attestation type. The timestamp of the proof must not be older than $10$ minutes. Can be called by anyone.
5. `proposeNewOwner(teeId, newOwner)`: Proposes a new owner for the TEE machine. Can only be called by the current owner.
6. `confirmOwnership(teeId)`: Called by the proposed new owner of the machine. When called after `proposeNewOwner(teeId, newOwner)`, the ownership of the TEE machine on Flare is changed to `newOwner`.
7. `updateTeeMachineSettings(teeId, teeProxyId, url)`: Updates the proxy ID and URL of the TEE machine. Any change puts the machine on pause and a proof is needed to return it to production.
8. `ban(teeId)`: Bans a TEE machine, setting its status to `BANNED`. Can only be called by governance.
9. `unban(teeId)`: Unbans a previously banned TEE machine. Can only be called by governance.

### `teeVerification` Functions

1. `confirmAvailability(proof)`: Given a valid `TeeAvailabilityCheck` proof, extends the availability deadline. Can be called by anyone.

### `teeReplication` Functions

1. `toPauseForUpgrade(teeId)`: Changes the status to `PAUSED_FOR_UPGRADE` and triggers the `TO_PAUSE_FOR_UPGRADE` command. Status must be `PAUSED` or `PAUSED_FOR_UPGRADE`. If the status is `PAUSED`, can only be called after $10$ minutes from the last status change. Can only be called by the owner.
2. `replicateFrom(oldTeeId, proof, signedUpgradePath)`: Triggers the `REPLICATE_FROM` command. The status of the new machine must be `INITIALIZED` or `REPLICATING`. The provided `proof` is the availability check proof for the new machine.
3. `confirmReplicate(newTeeId, proof)`: Confirms a successful replication. The proof must be for the new machine with the old TEE ID at the new machine's URL, and must be later than the timestamps for both machines.

When any function changes the machine status, the `lastStatusChangeTs` is updated to the current `block.timestamp`.
Note that once an owner registers a TEE ID and the proof has been provided, the machine belongs to that owner.
This prevents re-registration of the machine under other owners if it is temporarily unregistered.
A TEE ID can only be transferred to a new owner through the ownership change process while registered.