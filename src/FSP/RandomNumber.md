# Random Number

The FSP requires access to on-chain randomness for a variety of cryptographic features, including selecting random providers for the finalization phase and facilitating sortition for the FTSO block-latency feeds. 

This is enabled by the [FTSO scaling protocol](../FTSO/Anchor.md#randomness), which generates a secure distributed random number for each voting round. The random number for the last finalized round can be accessed from the [Relay](https://github.com/flare-foundation/flare-smart-contracts-v2/blob/main/contracts/protocol/implementation/Relay.sol#L1388) smart contract.
The return value also provides a boolean flag indicating whether the random number for that specific round is secure.
