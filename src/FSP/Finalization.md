# Finalization

Finalization of a voting round for a protocol is done on the Relay contract through function

```Solidity
function relay() external returns (bytes memory);
```

The finalization transaction input containes the relay function selector (4 bytes), followed by an encoded [Finalization](/src/FSP/Encoding.md#finalization) message.

After a successful finalization an event

```Solidity
event ProtocolMessageRelayed(
    uint8 indexed protocolId,
    uint32 indexed votingRoundId,
    bool isSecureRandom,
    bytes32 merkleRoot
);
```

is emitted.

## Finalizer Selection

Each round a few entities per protocol are selected for finalization.
Only they are incentivize to finalize inside the grace period TODO.

The seed is 32 byte hex string, that is compted by solidity code

```solidity
bytes32 initialSeed = keccak256(abi.encode(signingPolicySeed,protocolID,votingRoundID));
```

where signingPolicySeed is of type bytes32, protocolID is of type uint8, and votingRoundID is uint32.

where signingPolicySeed is uint256 value as emitted in field seed of `SigningPolicyInitialized` event for the signing policy active in voting round.

Start with $\mathrm{seed}= uint256(\mathrm{initialSeed})$, $\mathrm{selectedWeight}=0$, and empty set $\mathrm{selected}$.

Let $W$ be the total (normalized) weight in the active signing policy and let $\mathrm{threshold} = W * 0.05$
Each entity has an index $i$ and (normalized) weight $w(i)$ assigned by the signing policy.
Let $T(i) = \sum_{j=0}^{i} w(i)$.

While $\mathrm{selectedWeight} < \mathrm{threshold}$ we perform the following:
Let $\mathrm{selector}=\mathrm{seed}\mod W$ and let $i$ be the smallest index such that $\mathrm{selector} \leq T(i)$.
If $i \notin \mathrm{selected}$, we add $i$ to $\mathrm{selected}$ and add $w(i)$ to $\mathrm{selectedWeight}=0$.
Then update $\mathrm{seed} = keccak255(\mathrm{seed})$.

The entities whose indexes are in $\mathrm{selector}$ are incentivize to finalize in the grace period.

## Threshold

The threshold is set in signing policy.
It is set rounded up one half of the total normalized weight.
In a rare and unlikely case, it is raised to $12 * \mathrm{threshold} /10$.

Let $v$ be the votingRoundID of the message being finalized.
Let $r$ be the ID of current active signingPolicy.
Let $\mathrm{expected}(v)$ be the [expected reward epoch](Epoch.md#reward-epoch) for $v$.
Let $x$ be the ID of the last initialized signingPolicy.

If $\mathrm{expected}(v) = r$ and $r.\mathrm{StartVotingRoundId}\leq v$, the threshold is normal.

If $\mathrm{expected}(v) > r$ and $x=r$, the threshold is increased. TODO

## Rewarding

Each protocol has designated funds to incentivize fast finalization.
The value of the rewards can vary per protocol and voting round.

Let $V$ be the total designated rewards for a protocol in some voting round.

### In Grace Period

In each round, the selected entity is rewarded if they make a transaction from signingPolicyAddress inside the grace period that either:

- finalizes the protocol for the round;
- would finalize the protocol for the round but the protocol is already finalized.

Such an entity is rewarded by
$
\frac{V}{|\mathrm{selected}|}
$
and the reward is shared among their delegators.

If a selected entity does not make such transaction, their portion gets burned.

### Outside Grace Period

If finalization does not happen inside the grace period, any address that finalizes up to TODO gets the whole reward $V$.
