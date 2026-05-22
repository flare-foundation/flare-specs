# Roles

This page defines the roles and actors that appear across the Flare protocol specifications.

## Data Provider

A *data provider* (also referred to as a *voter*, *validator*, *infrastructure provider*, or *entity*) is an off-chain participant registered as an [entity](../FSP/Voters.md#entity-definition) on Flare.
Data providers accrue vote power from the Flare community via delegations of wrapped FLR tokens (WFLR) or stakes.
They participate in all Flare protocols: operating a Flare validator node, submitting and finalizing voting round data in the [Flare Systems Protocol](../FSP/Introduction.md), providing price feeds in [FTSO](../FTSO/Introduction.md), confirming attestations in [FDC](../FDC/Introduction.md), and running [relay clients](../FCC/Reference/Components/RelayClient.md) to relay instructions to TEE machines in [FCC](../FCC/README.md).
Data providers must complete [voter registration](../FSP/Voters.md#voter-registration) every reward epoch.

Each protocol rewards data providers for correct participation and penalizes non-compliance:
- [FSP Rewarding](../FSP/Rewarding.md)
- [FTSO Rewarding](../FTSO/Rewarding.md)
- [FDC Rewarding](../FDC/Rewarding.md)
- FCC rewarding is planned but not yet specified.

## Delegator

A *delegator* is a WFLR token holder who delegates vote power to a data provider's [delegation address](../FSP/Voters.md#entity-definition).
Delegators share in the [rewards](../FSP/Rewarding.md) earned by the data provider they delegate to.

## TEE Operator

A *TEE operator* is the party that deploys and maintains one or more TEE machines and their associated [TEE proxies](../FCC/Reference/Components/Proxy.md).
A TEE operator need not be a data provider.
TEE operators register their machines on-chain through the [registration](../FCC/Concepts/Machines.md) process; registration requires being on the extension's [owner allowlist](../FCC/Concepts/Machines.md#owner-allowlist).

## Project Owner

A *project owner* is the Flare [address](Concepts.md#addresses-accounts-and-keys) that creates and administers an FCC [project](../FCC/Concepts/Wallets.md).
The project owner controls wallet creation, key management, and configuration for the project's wallets.

## Key Admin

A *key admin* is one of a set of addresses associated with a wallet whose public keys are used for encrypting [Shamir secret shares](../FCC/Concepts/Keys.md#backup-procedure) during key backup.
Key admins participate in [key restoration](../FCC/Concepts/Keys.md#key-restoration-procedure) by decrypting and re-submitting their shares.
Operations requiring admin approval use a $k$-of-$n$ threshold over the admin public keys.

## Governance

*Governance* is the single Flare address authorized to perform privileged operations on Flare's smart contracts — for example, registering [system instructions senders](../FCC/Concepts/Instructions.md#sending-instructions), setting the [signing policy threshold](../FSP/SigningPolicy.md), and adding [system-supported key types](../FCC/FCE/Concepts.md#system-administration-functions-governance-only).
The address is backed by a multisig (or a single key on test networks) and can only be changed by a validator fork.

It is distinct from the per-extension [governance signers](#governance-signer) that approve TEE upgrades.

## Governance Signer

A *governance signer* is an address registered on-chain as part of a per-extension governance set.
The extension owner configures the set of signers and a threshold by calling [`setNewTeeGovernance`](../FCC/Reference/Contracts/FlareTeeManagerEvents.md#newgovernanceset).
Governance signers approve TEE upgrades by calling `signTeeUpgrade`; the contract validates each signature against the governance set and threshold before marking the [upgrade as signed](../FCC/Reference/Contracts/FlareTeeManagerEvents.md#teeupgradesigned).

## User

A *user* is any Flare address holder who interacts with the protocols — for example, by submitting FCC instructions via smart contracts, making [FDC attestation requests](../FDC/MakingRequest.md), or delegating tokens.
Unlike data providers, users do not need to register or run off-chain infrastructure.
