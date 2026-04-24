# Tee Machines
TEE machines on Flare are each identified by a unique identity $\mathrm{TEE}_\mathrm{ID}$.
This public identity corresponds to a public key for a digital signature scheme, allowing the TEE to authenticate itself on the network.
Alongside this key, TEEs have a variety of state features when deployed on the Flare network, such as keys for PMWs and different versions of code for their extension.
This page describes how the TEE machines are identified, how their verifiable states are organized, and how attestations are structured for TEE machines within the Flare Confidential Compute infrastructure. 

## Identity Key and Initial Identity
When a TEE machine is first booted, a public-private key pair $(\mathrm{TEE}_\mathrm{pk}, \mathrm{TEE}_\mathrm{sk})$ is generated inside the machine.
The address that corresponds to the public key is defined to be the machine's identity $\mathrm{TEE}_\mathrm{ID}$.
This key is stored securely inside the memory of the machine and represented on-chain as a `PublicKey` struct.

Each TEE also has an initial identity $\mathrm{TEE}_\mathrm{ID}^*$, which is equal to $\mathrm{TEE}_\mathrm{ID}$ unless the machine is a replica of some other TEE with identity ${\mathrm{TEE}_\mathrm{ID}}'$, in which case its initial ID is a copy of the original TEE's identity, $\mathrm{TEE}_\mathrm{ID}^* = {\mathrm{TEE}_\mathrm{ID}}'$. 
Additionally, each booted TEE has an [owner address](Registration.md).

## Signing Policy
In order to be able to receive instructions from Flare's [data providers](../../Terminology/Roles.md#data-provider), each participating TEE must have access to the current signing policy. 
Otherwise, they will not be able to follow instructions that have been signed by a weighted majority of Flare's providers. 

On registering, the TEE is equipped with the current signing policy, and is only registered if the signing policy included in its initial attestation (see below) is correct. 
This signing policy must be updated at the end of each reward epoch by the owner, and is done so by the [proxy](TeeProxy.md).

## TEE State
 The state of a TEE refers to properties of the machine and its memory that would not immediately be shared by a replicated copy of the TEE running the same code.
For example, keys stored in the memory of the TEE are part of its state.
The state of a TEE machine includes:

- The key pair $(\mathrm{TEE}_\mathrm{pk}, \mathrm{TEE}_\mathrm{sk})$ corresponding to $\mathrm{TEE}_\mathrm{ID}$.
- All keys (and key backups) stored in the TEE as part of its participation in any [PMWs](../Extensions/PMW/PMW.md).
- State variables:
	- The current and initial signing policies.
	- The machine's status.
	- The configuration nonce.
	- The pausing nonce.
- Any custom state added by the extension to which the TEE is registered.

Note that when a TEE machine is replicated as part of an upgrade, the essential parts of its state are fully replicated into the new machine that takes over the identity.
This includes the identity key pair and all keys and backups stored in the TEE as part of the PMW protocol, but excludes machine-specific variables such as nonces.

### TEE State Encoding
The machine state is encoded into a `teeState` struct for use in [attestations](#attestations). The state consists of two parts:

1. **System state**: Defined by Flare. Intended for state variables managed by the FCC framework as functionality is extended.
2. **Custom compute extension state**: Defined by the FCE to which the TEE is registered extension.

This encoding is formatted as the [`TeeState`](../Types/Abi/TeeMachine.md#teestate) struct.

The `systemState` and `state` fields are ABI encodings of version-specific structs.
Each code version is aware of the state encoding version for both the system and compute extension state.
The initial version (version `0`, indicated by 32-byte zero sequences for `systemStateVersion` and `stateVersion`) has empty bytes for both `systemState` and `state`.
Future versions may contain more information.
In a compute extension setup, values of `stateVersion` and `state` are provided by the compute extension through the `/state` API route.

## Attestations
On registration, and periodically during their operation, TEE platform operators will be required to attest to certain aspects of the machine's state. 
The ability to securely perform this attestation is a crucial property of a TEE machine. 
The exact response format depends on the TEE platform, as the signed attestation is performed by the operator (e.g. Google for Intel TDX and AMD-SEV). 

### Challenge and Response
A TEE machine operator provides an attestation response to a *challenge*, a $32$-byte string provided by a challenger.
The challenger can be any entity who wants to confirm the state of the TEE machine.
Upon receiving the challenge, the TEE machine generates a challenge hash specific to the machine.
To generate the challenge hash, the [`Attestation`](../Types/Abi/TeeMachine.md#attestation) struct is ABI encoded and then hashed.
The `publicKey` is the key that corresponds to $\mathrm{TEE}_\mathrm{ID}$.
The initial and last signing policies refer to the first and most recent signing policy available to the TEE respectively.
The `state` field is encoded as the [`TeeState`](../Types/Abi/TeeMachine.md#teestate) struct.
The `teeTimestamp` refers to the local timestamp at the TEE machine at time of attestation.
Thus, the TEE-specific challenge is $\mathrm{hash}(\mathrm{Attestation})$.

Once the TEE specific challenge is created, the platform provider signs the challenge and returns the response.