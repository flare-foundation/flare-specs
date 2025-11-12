# TEE Ownership
TEE ownership on Flare is decentralized: operators of TEE machines can register their devices on the network to participate in FlareTEE's protocols. 
Owners are incentivized to participate in FlareTEE via a rewarding mechanism described in [cite]. 
This page documents the responsibilities of TEE owners on Flare, including registration, management, and upgrading.

## Registration
Registration is the process by which a TEE owner deploys their TEE machine for operation within the Flare network.
When a TEE is registered, it is registered to a specific TEE extension [cite], and not the network as a whole. To register a TEE, its owner submits a transaction `register(extensionID, publicKey, teeProxyId, teeURL,codeHash,platform)` to the `TEEMachineRegistry` smart contract with the following information:

1. **extensionID**: The ID of the extension [ref extension] to which the TEE is registered.
2. **publicKey**: The public key of the TEE, corresponding to its identity.
3. **teeProxyId**: The public identity of the proxy server from which the TEE can be reached. For more information on proxy servers, see [cite].
4. **teeURL**: The URL of the TEE.
5. **codeHash**: The state of the TEE, identified by the hash of the code deployed on the machine.
6. **platform**: The attestation platform for the TEE, which determines how an attestation of its state should be encoded.


Additionally, to complete registration the TEE needs to provide the `TeeAvailabilityCheck` attestation proof `toProduction(proof)`, confirming that its state is correct, as described in the FTDC section [cite].
If a TEE has attempted to register but has not provided a valid attestation proof, it has the status *pre-registered* on the network; once the attestation proof is received, the status is set to *production*.

The `TEEMachineRegistry` smart contract keeps a record of each registered TEE, containing the (possibly updated) information in its registration as well as additional data:

1. **TEE Owner**: The Flare address of the TEE owner.
2. **Machine Status**: The operating status of the TEE. The possible status of TEE machines are listed in [somewhere suitable].
3. **Last Time Stamp**: The time stamp of the last status change of the TEE.

## Management

The Flare address of the TEE owner is responsible for managing the TEE on the network.
The following set of functions are available to the TEE owner, to be sent to the `TEEMachineRegistry` smart contract:

1. `register(extensionID, publicKey, teeProxyId, teeURL,codeHash,platform)`: As described above.
2. `toProduction(proof)`: An FTDC proof that the TEE is running correctly. Upon submitting this transaction, the status of the TEE machine changes from pre-registered to production.
3. `pause(TEEId)`: Changes the status of the TEE machine to *paused*. A paused TEE machine may not participate on an extension. This function may be called by any user in cases where the TEE machine is running a version that is no longer supported.
4. `pauseWithProof(proof)`: Changes the status of the TEE machine to paused. This function may be called by any user, but must contain an argument *proof*, the result of a valid non-availability proof from a `TEEAvailabilityCheck` [cite] whose timestamp is no older than 10 minutes.
5. `proposeNewOwner(TEEID, newOwner)`: Called by the current owner of the TEE machine to propose a change of ownership of the TEE machine to the address `newOwner`.
6. `confirmOwnership(newOwner)`: Called by the proposed new ownership of the machine. Confirms a proposed change of ownership of the TEE to the address `newOwner`.
7. `updateTeeMachineSettings(teeId, teeProxyId, url)`: Updates the proxyID and the URL of the TEE machine. 
