# States and Keys
TEEs on Flare are each identified by a unique identity $\mathrm{TEE}_\mathrm{ID}. 
This public identity corresponds to a public key for a digital signature scheme, allowing the TEE to authenticate itself on the network. 
Alongside this key, TEEs have a variety of state features when deployed on the Flare network, such as keys for PMWs and different versions of code for their extension. 
This page describes the state and key management procedures of the FlareTEE infrastructure. 

## Identity Key and Initial Identity
When a TEE machine is first booted, a public-private key pair $(\mathrm{TEE}_\mathrm{pk}, \mathrm{TEE}_\mathrm{sk})$ is generated inside the machine. 
The address that corresponds to the public key is defined to be the machines identity $\mathrm{TEE}_\mathrm{ID}$. This key is stored securely inside the memory of the machine.

Each TEE also has an initial identity $\mathrm{TEE}_\mathrm{ID}^*$, which is equal to $\mathrm{TEE}_\mathrm{ID}$ unless the machine is a replica of some other TEE with identity ${\mathrm{TEE}_\mathrm{ID}}'$, in which case its initial ID is a copy of the original TEE's identity, $\mathrm{TEE}_\mathrm{ID}^* = {\mathrm{TEE}_\mathrm{ID}}'$. 
Additionally, each booted TEE has an [owner address](TEEOwnership.md).

## Signing Policy
In order to be able to receive instructions from Flare's data providers, each participating TEE must have access to the current signing policy [ref outwards]. 
Otherwise, they will not be able to follow instructions that have been signed by a weight majority of Flare's providers. 

On registering, the TEE is equipped with the current signing policy, and is only registered if the signing policy included in its initial attestation (see below) is correct. 
This signing policy must be updated at the end of each reward epoch by the owner, and is done so by the [proxy](TEEProxy.md).

## TEE Status
The status of a TEE dictates whether or not it is currently in use on the network.
The possible statuses are

1. **Operational**: The TEE is correctly following instructions on the extension; this is the default status for a TEE.
2. **Paused**: The TEE has not been powered down, but is not actively receiving or following instructions. The TEE can be unpaused (returned to operational) following a message signed by a threshold of governance signers.
3. **Paused for Upgrade**: The final status for a non-powered down TEE. The TEE is not operational, but can be used for replication purposes. This status is triggered by a specific pause for upgrade instruction.

## TEE State
 The state of a TEE refers to properties of the machine and its memory that would not immediately be shared by a replicated copy of the TEE running the same code.
For example, keys stored in the memory of its TEE are part of its state.
The state of a TEE machine includes:

- The key pair $(\mathrm{TEE}_\mathrm{pk}, \mathrm{TEE}_\mathrm{sk})$ corresponding to $\mathrm{TEE}_\mathrm{ID}$.
- All keys (and key backups) stored in the TEE as part of its participation in any [PMWs](PMW.md).
- Variables known to the TEE, including the current Flare signing policy, the machine's status, its configuration nonce, and its pausing nonce. [what are these nonces]
- Any custom state added by the extension to which the TEE is registered.
