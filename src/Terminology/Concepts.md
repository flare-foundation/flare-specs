# Concepts

Foundational concepts used across the Flare protocol specifications.

## Addresses, Accounts, and Keys

- _address_ — a $20$-byte identifier derived from a public key.
  On EVM-compatible chains, the last $20$ bytes of keccak256 of the uncompressed public key.
- _account_ — the on-chain state behind an address: balance, nonce, and (for contract accounts) code and storage.
  Use "address" for the identifier, "account" for the state.
- _private key_ — a $256$-bit secret scalar on the secp256k1 curve.
- _public key_ — the elliptic curve point obtained by multiplying the generator by the private key.
  Held on-chain as the [`PublicKey`](../FCC/Reference/Types/Abi/Common.md) struct with curve coordinates $(x, y)$.
- _signature_ — produced by signing a message hash with a private key using ECDSA.
  Flare's [signing procedure](../Utilities/Signing.md) prepends the Ethereum signed-message prefix before hashing.

## Epochs

- _voting epoch_ — the FSP's basic time unit; $90$ seconds.
- _reward epoch_ — $3360$ voting epochs (approximately $3.5$ days).
  Voter registration, signing policies, and reward distribution are scoped to reward epochs.

Full specification: [Epochs](../FSP/Epochs.md).

## Signing Policy

A _signing policy_ defines the data providers eligible to participate in a given reward epoch and their voting weights.
A new policy is generated each reward epoch during [voter registration](../FSP/Voters.md#voter-registration).

Full specification: [Signing Policy](../FSP/SigningPolicy.md).

## Weight and Vote Power

- _vote power_ — a data provider's influence in protocol voting; derived from WFLR delegations and validator stakes.
- _weight_ — vote power normalized to $[0, 1]$ for use in signing policies; a diversity factor encourages decentralization.

Full specification: [Weighting](../FSP/Weighting.md).
