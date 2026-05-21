# State

Each TEE machine on Flare is identified by a unique $\mathrm{TEE}_\mathrm{ID}$ — the address derived from the machine's identity public key, generated inside the enclave at boot.
Around that identity, the machine carries a set of state that is not implied by its code alone (keys, signing policies, status, extension-defined state).
This page describes how the identity and state are organized.
For the procedure that surfaces this state to challengers, see [Attestation](Attestation.md).

## Identity Key and Initial Identity

The boot-time key pair $(\mathrm{TEE}_\mathrm{pk}, \mathrm{TEE}_\mathrm{sk})$ never leaves the enclave; $\mathrm{TEE}_\mathrm{ID}$ is the public key's Ethereum-style address.
On Flare, $\mathrm{TEE}_\mathrm{pk}$ is represented as a [`PublicKey`](../Types/Abi/Common.md#publickey) struct on the [`FlareTeeManager`](FlareTeeManager.md) contract.

Each machine also has an _initial identity_ $\mathrm{TEE}_\mathrm{ID}^*$.
For a fresh registration $\mathrm{TEE}_\mathrm{ID}^* = \mathrm{TEE}_\mathrm{ID}$; for a [replica](#tee-state) taking over from a TEE with identity $\mathrm{TEE}_\mathrm{ID}^{\prime}$, $\mathrm{TEE}_\mathrm{ID}^* = \mathrm{TEE}_\mathrm{ID}^{\prime}$.
Owners are recorded separately and updated via the [ownership transfer flow](Registration.md#management-calls).

## Signing Policy

A TEE machine cannot accept signed instructions unless it knows the current [signing policy](../../FSP/SigningPolicy.md).
The first signing policy is installed at registration time as part of the [initial attestation](Attestation.md); subsequent policies are pushed by the [TEE proxy](../Components/TeeProxy.md) via [`UPDATE_POLICY`](../Operations/Commands/F_POLICY/UpdatePolicy.md) at every reward-epoch boundary.

## TEE State

The TEE's state is the part of its content that a fresh replica running the same code would not share by default:

- The identity key pair $(\mathrm{TEE}_\mathrm{pk}, \mathrm{TEE}_\mathrm{sk})$.
- All [wallet keys](Keys.md) and key backups held for [PMW](../Extensions/PMW/README.md) (or any other key-custody [FCE](../Extensions/README.md)).
- System state variables: initial and current signing policies, the machine's status, the configuration nonce, the pausing nonce.
- Any [extension-defined state](../Extensions/Concepts.md) added by the FCE the machine is registered to.

On a [replication](../Operations/Commands/F_REG/) upgrade, the essential state — the identity key pair, and all wallet keys and backups — is transferred to the new machine that takes over the identity.
Machine-local nonces are not carried over.

### Encoding

State is serialized into the [`TeeState`](../Types/Abi/TeeMachine.md#teestate) struct used inside attestations.
It has two parts:

- **System state**: defined by Flare; covers FCC-framework state variables. Version-specific.
- **Extension state**: defined by the FCE the machine is registered to; surfaced through the FCE's `/state` endpoint. Version-specific.

Each version of `systemState` and `state` is keyed by a `bytes32` version hash (`systemStateVersion`, `stateVersion`).
Version `0` (32-byte zero) encodes both bodies as empty `bytes`.
