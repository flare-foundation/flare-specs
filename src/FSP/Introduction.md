# Introduction

The Flare Systems Protocol (FSP) is a foundational infrastructure designed to support Flare's enshrined protocols (technically referred to as sub-protocols).
Its primary goal is to facilitate secure, efficient, and decentralized consensus mechanisms through weighted voting by a select group of entities known as data providers or voters.
These data providers are off-chain participants who accrue vote power from the Flare community via delegations of wrapped FLR tokens (WFLR) or stakes.

FSP ensures that agreements on offchain data or calculations are reached securely and fairly, enabling the reliable operation of sub-protocols like the Flare Time Series Oracle and the Flare Data Connector.

<img src="https://dev.flare.network/img/fsp/fsp_light.svg" alt="FSP Architecture" width="600">

Key FSP Features:

1. **Decentralized Governance**: Through a weighted voting system involving a diverse set of voters.
2. **Efficient Data Management**: By offloading complex calculations offchain and minimizing onchain storage requirements.
3. **Robust Reward Mechanisms**: Incentivizing participation and penalizing delays or non-compliance to maintain network health.
4. **Extensibility**: Designed to support additional sub-protocols and future enhancements like C-chain staking.
5. **Security**: Implements mechanisms to prevent malicious behavior and ensures data integrity through Merkle proofs.
