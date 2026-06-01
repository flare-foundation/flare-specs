# Roles

Roles and actors across the Flare protocol specs.

## Governance

_Governance_ is the single Flare address authorized to perform privileged operations on Flare's smart contracts — e.g. registering [system instructions senders](../FCC/Concepts/Instructions.md#sending-instructions), setting the [signing policy threshold](../FSP/SigningPolicy.md), and adding [system-supported key types](../FCC/FCE/Concepts.md#system-administration-functions-governance-only).
Backed by a multisig (or a single key on test networks); changeable only by a validator fork.

Distinct from the per-extension [governance signers](#governance-signer) that approve TEE upgrades.

## Data Provider

A _data provider_ (also _voter_, _validator_, _infrastructure provider_, or _entity_) is an off-chain participant on Flare who accrues [vote power](Concepts.md#weight-and-vote-power) from the community via delegations of wrapped FLR tokens (WFLR) or stakes.
Data providers participate in every Flare protocol:

- operate a Flare validator node.
- submit and finalize voting-round data in the [FSP](../FSP/Introduction.md).
- sign the [signing policy](../FSP/SigningPolicy.md) for each new [reward epoch](Concepts.md#epochs).
- provide price feeds in the [FTSO](../FTSO/Introduction.md).
- confirm attestations in the [FDC](../FDC/Introduction.md).
- run [relay clients](../FCC/Reference/Components/RelayClient.md) to relay instructions to [TEE machines](../FCC/Concepts/Machines.md) in the [FCC](../FCC/README.md).

Each protocol rewards correct participation and penalizes non-compliance:

- [FSP Rewarding](../FSP/Rewarding.md)
- [FTSO Rewarding](../FTSO/Rewarding.md)
- [FDC Rewarding](../FDC/Rewarding.md)
- FCC rewarding is planned but not yet specified.

## Delegator

A _delegator_ is a WFLR holder who delegates vote power to a data provider's [delegation address](../FSP/Voters.md#entity-definition), and shares in the [rewards](../FSP/Rewarding.md) earned by that data provider.

## User

A _user_ is any Flare address holder who interacts with the protocols — e.g. submitting FCC instructions via smart contracts, making [FDC attestation requests](../FDC/MakingRequest.md), or delegating tokens.
Users need no on-chain registration or off-chain infrastructure.

## Extension Owner

An _extension owner_ is the Flare [address](Concepts.md#addresses-accounts-and-keys) that registers and administers a [Flare Compute Extension](../FCC/FCE/README.md).
Responsibilities:

- control the supported code versions.
- manage the extension's allowlists of machine owners and project owners.
- configure the [governance signer](#governance-signer) set.
- delegate the [emergency-pause overlay](../FCC/Reference/Contracts/FlareTeeManager.md#emergency-pause) via per-extension [pauser/unpauser](#extension-emergency-pauser-and-unpauser) lists.

Eligibility is gated by a global allowlist maintained by [governance](#governance) — see [Concepts/Machines § Owner Allowlist](../FCC/Concepts/Machines.md#owner-allowlist).

## Governance Signer

A _governance signer_ is one of a per-extension set of addresses authorized to approve TEE upgrades.
The [extension owner](#extension-owner) configures the set and a signing threshold.

## Extension Emergency Pauser and Unpauser

Per-extension address lists, maintained by the [extension owner](#extension-owner), authorized to [emergency-pause](../FCC/Reference/Contracts/FlareTeeManager.md#emergency-pause) or unpause the extension.

## TEE Operator

A _TEE operator_ deploys and maintains one or more TEE machines and their associated [TEE proxies](../FCC/Reference/Components/Proxy.md).
A TEE operator need not be a data provider.
Eligibility is gated by the extension's [machine owner allowlist](../FCC/Concepts/Machines.md#owner-allowlist).

## Project Owner

A _project owner_ is the Flare [address](Concepts.md#addresses-accounts-and-keys) that creates and administers an FCC [project](../FCC/Concepts/Wallets.md), controlling wallet creation, key management, and wallet configuration.
Pause authority on the project's wallets may be delegated to per-project [wallet pauser/unpauser](#wallet-pauser-and-unpauser) lists.

## Wallet Pauser and Unpauser

Per-project address lists, maintained by the [project owner](#project-owner), authorized to pause or unpause the project's [wallets](../FCC/Concepts/Wallets.md).

## Key Admin

A _key admin_ is one of a set of addresses associated with a [wallet](../FCC/Concepts/Wallets.md) whose public keys encrypt [Shamir secret shares](../FCC/Concepts/Keys.md#backup-procedure) during key backup.
On [key restoration](../FCC/Concepts/Keys.md#key-restoration-procedure), admins decrypt and re-submit their shares.
Operations requiring admin approval use a $k$-of-$n$ threshold over the admin public keys.
