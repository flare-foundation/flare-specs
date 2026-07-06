<p align="left">
  <a href="https://flare.network/" target="blank"><img src="https://content.flare.network/Flare-2.svg" width="410" height="106" alt="Flare Logo" /></a>
</p>

# Flare Specifications

This repository contains the technical specifications for Flare's core protocols.

## Protocols

### Flare Systems Protocol (FSP)

- [Introduction](src/FSP/Introduction.md)
- [Epochs](src/FSP/Epochs.md)
- [Voters](src/FSP/Voters.md)
- [Signing Policy](src/FSP/SigningPolicy.md)
- [Submissions](src/FSP/Submission.md)
- [Finalizations](src/FSP/Finalization.md)
- [Rewarding](src/FSP/Rewarding.md)
- [Weighting](src/FSP/Weighting.md)
- [Random Number](src/FSP/RandomNumber.md)
- [Encoding Reference](src/FSP/Encoding.md)

### Flare Data Connector (FDC)

- [Introduction](src/FDC/Introduction.md)
- [Voting Protocol](src/FDC/VotingProtocol.md)
- [Making Requests](src/FDC/MakingRequest.md)
- [Bit Voting](src/FDC/BitVote.md)
- [Attestation Type](src/FDC/AttesationType.md)
  - [AddressValidity](src/FDC/AttestationTypes/AddressValidity.md)
  - [BalanceDecreasingTransaction](src/FDC/AttestationTypes/BalanceDecreasingTransaction.md)
  - [ConfirmedBlockHeightExists](src/FDC/AttestationTypes/ConfirmedBlockHeightExists.md)
  - [EVMTransaction](src/FDC/AttestationTypes/EVMTransaction.md)
  - [Payment](src/FDC/AttestationTypes/Payment.md)
  - [ReferencedPaymentNonexistence](src/FDC/AttestationTypes/ReferencedPaymentNonexistence.md)
- [Rewarding](src/FDC/Rewarding.md)
- [Encoding Reference](src/FDC/Encoding.md)

### Flare Time Series Oracle (FTSO)

- [Introduction](src/FTSO/Introduction.md)
- [Anchor](src/FTSO/Anchor.md)
- [Block Latency](src/FTSO/BlockLatency.md)
- [Rewarding](src/FTSO/Rewarding.md)
- [Encoding Reference](src/FTSO/Encoding.md)

### [Flare Confidential Compute (FCC)](src/FCC/README.md)

- [Architecture](src/FCC/Architecture.md)
- [Concepts](src/FCC/Concepts/)
- [Flare Compute Extension](src/FCC/FCE/)
- [Reference](src/FCC/Reference/)
- [Workflows](src/FCC/Workflows/)

### [Protocol Managed Wallets (PMW)](src/PMW/README.md)

- [Concepts](src/PMW/Concepts.md)
- [Transactions](src/pmw/Transactions.md)
- [Reference](src/pmw/Reference/)
- [Workflows](src/PMW/Workflows/)

### [Flare Data Connector 2 (FDC2)](src/FDC2/README.md)

- [Concepts](src/FDC2/Concepts.md)
- [Verifier](src/FDC2/Verifier.md)
- [Reference](src/FDC2/Reference/)
- [Workflows](src/FDC2/Workflows/)

## Terminology

Cross-cutting definitions used across protocols:

- [Roles](src/Terminology/Roles.md)
- [Concepts](src/Terminology/Concepts.md)

## Utilities

Shared cryptographic and mathematical utilities used across protocols:

- [Integer Operations](src/Utilities/IntOperations.md)
- [Merkle Tree](src/Utilities/MerkleTree.md)
- [Signing](src/Utilities/Signing.md)

## Security

- [FSP Attack Surface](src/Security/FspThreatModel.md) — trust boundaries, deployment topology, and per-service attack surface for security reviews

## Status

This repository is actively maintained and updated.
Some sections may be works in progress as protocols evolve.