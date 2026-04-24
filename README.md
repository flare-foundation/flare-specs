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

### Flare Confidential Compute (FlareTEE)

- [Introduction](src/FlareTEE/Introduction.md)
- [Architecture](src/FlareTEE/Architecture.md)
- Operations
  - [Instructions](src/FlareTEE/Operations/Instructions.md)
  - [Actions](src/FlareTEE/Operations/Actions.md)
  - [Voting](src/FlareTEE/Operations/Voting.md)
  - [Relay Client](src/FlareTEE/Operations/RelayClient.md)
  - [Projects and Configuration](src/FlareTEE/Operations/ProjectsAndConfiguration.md)
- Extensions
  - [Overview](src/FlareTEE/Extensions/Overview.md)
  - [System Extension](src/FlareTEE/Extensions/SystemExtension.md)
  - [FDC2](src/FlareTEE/Extensions/FDC2.md)
  - [FDC2 Verifier Server](src/FlareTEE/Extensions/Fdc2VerifierServer.md)
  - [PMW](src/FlareTEE/Extensions/PMW/PMW.md)
  - [PMW Transactions](src/FlareTEE/Extensions/PMW/Transactions.md)
- TEE Management
  - [Registration](src/FlareTEE/TeeManagement/Registration.md)
  - [State and Attestation](src/FlareTEE/TeeManagement/StateAndAttestation.md)
  - [Key Management](src/FlareTEE/TeeManagement/KeyManagement.md)
  - [TEE Proxy](src/FlareTEE/TeeManagement/TeeProxy.md)
- [Events](src/FlareTEE/Types/Abi/Events/index.md)
- References
  - [Commands](src/FlareTEE/Commands/index.md)
  - [Workflows](src/FlareTEE/Workflows/index.md)
  - [Attestation Types](src/FlareTEE/AttestationTypes/index.md)
  - [Type Reference](src/FlareTEE/Types/index.md)

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
