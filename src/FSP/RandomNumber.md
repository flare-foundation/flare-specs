# Random Number

Random numbers in FSP are derived from the finalized [FTSO Merkle root](TODO: link) for each voting round, providing cryptographically secure randomness for protocol operations.

The random number for the last finalized round can be accessed from the [Relay](https://github.com/flare-foundation/flare-smart-contracts-v2/blob/main/contracts/protocol/implementation/Relay.sol#L1388) smart contract.
The return value also provides a boolean indicating whether the random number for that round is [secure](../FTSO/Anchor.md#randomness).
