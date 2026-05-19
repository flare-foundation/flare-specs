# Concepts

This page defines foundational concepts used across the Flare protocol specifications.

## Addresses, Accounts, and Keys

An *address* is a 20-byte identifier derived from a public key.
On EVM-compatible chains, an address is computed as the last 20 bytes of the keccak256 hash of the uncompressed public key.

An *account* is the on-chain state associated with an address — its balance, nonce, and (for contract accounts) code and storage.
In this documentation, "address" refers to the identifier itself, while "account" refers to the on-chain state behind it.

A *private key* is a 256-bit secret scalar on the secp256k1 curve.
The corresponding *public key* is the elliptic curve point obtained by multiplying the generator point by the private key.
The on-chain representation of a public key is the [`PublicKey`](../FCC/Types/Abi/Common.md) struct containing the curve coordinates $(x, y)$.

A *signature* is produced by signing a message hash with a private key using ECDSA.
The [signing procedure](../Utilities/Signing.md) used across the Flare protocols prepends the Ethereum signed message prefix before hashing.

## Epochs

A *voting epoch* is the basic time unit of the Flare Systems Protocol, lasting 90 seconds.
A *reward epoch* spans 3360 voting epochs (approximately 3.5 days).
Voter registration, signing policies, and reward distribution are all scoped to reward epochs.
See [Epochs](../FSP/Epochs.md) for the full specification.

## Signing Policy

A *signing policy* defines the set of data providers eligible to participate in a given reward epoch and their corresponding voting weights.
A new signing policy is generated each reward epoch during the [voter registration](../FSP/Voters.md#voter-registration) phase.
See [Signing Policy](../FSP/SigningPolicy.md) for the full specification.

## Weight and Vote Power

*Vote power* is the influence a data provider has in protocol voting.
It is derived from WFLR delegations and validator stakes, then normalized into a *weight* between 0 and 1 for use in signing policies.
The weighting formula applies a diversity factor to encourage decentralization.
See [Weighting](../FSP/Weighting.md) for the full specification.

