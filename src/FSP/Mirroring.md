# Mirroring

The mirroring is currently based on multisig scheme.
It is expected to be passed on to weighted signature scheme operated by data providers.

Upon running and syncing a Flare node, the node becomes an observation node in the Flare network. In order to participate in the validation, the stake has to be assigned to the node.
Each node is identified by node ID.
The node id is defined by a pair of a private-public in the configuration of the node.
Such a pair gets generated on the first run.
Stake assignment to a node id usually involves the following steps:

- Move FLR funds from C-chain to P-chain by carrying out first an export transaction on C-chain and then an import transaction on P-chain.
  This can be done by using the [Flare staking tool](https://github.com/flare-foundation/p-chain-staking-code).
  The result is funds on a P-chain account.
  The accounts on both chains are matched if they are derived from the same private key.
- Trigger a staking transaction, which is defined by amount, the node ID to which stake is assigned, start and end time, and fee.
  With a successful staking transaction the node becomes a validator and starts participating in the consensus for the duration of the stake.

Once the stake is open, other network participants can add to the stake by making a staking delegation to the node ID.
Staking delegations increase the validator weight.

Validators do not get directly rewarded on P-Chain, however, the weight or the validator is reflected in the rewards on C-Chain for the data providers who own the validator. (TODO)
Validators weight is also used to calculate voters weight in other protocols.
For such purposes, the data on validators weight has to be available on C-Chain which is achieved through mirroring.

## Service TODO

Stake record contains:

- txId - P-chain transaction ID
- stakingType - stake (0) or delegation (1)
- inputAddress - staker/delegator address
- nodeId - Node ID
- startTime
- endTime
- weight - Amount in Gwei

A stake record R falls into the voting epoch with ID $\mathrm{floor}\left(\frac{R.\mathrm{startTime} - T_0}{D}\right)$.
