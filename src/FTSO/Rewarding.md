# Rewarding

Flare's data providers are rewarded separately for their contributions to the anchor and block-latency feeds.
A proportion of Flare's inflationary funds are allocated to the rewarding of the FTSO.

In the $j$th round, correpsonding to the $j$th voting epoch, let this quantity be $R_\mathrm{FTSO}(j)$.
These funds are then distributed into $R_\mathrm{anchor}(j)$, which are allocated to the anchor feeds, and $R_\mathrm{block}(j)$, which are allocated to participation in the block-latency feeds.
The parameters defining the split of rewards between the two feeds, satisfying the equation

$$R_\mathrm{FTSO}(j) = R_\mathrm{anchor}(j) + R_\mathrm{block}(j),$$

are set by governance, and can be modified by a governance vote.

## Selecting a Rewarded Feed

Each round, corresponding to a voting epoch, rewards for both types of feed are determined according to performance in a single randomly selected data feed, rather than an aggregation of performance across all anchor feeds.
The choice of data feed is sampled uniformly at random amongst existing data feeds, and is not known in advance.
This prevents providers from only focusing on the feed that is to be rewarded in a round.
This applies both to assigning accuracy rewards and to determining eligibility for signing and finalization rewards: only one, randomly selected, feed is used.

### Secure Reward Random Number

The rewarded feed random seed in a given round is generated using the earliest protocol secure random number generated in the subsequent voting rounds.

For voting round $j$, let $s$ be the first secure random number generated in round $j + k$ (for any $k \geq 1$).
The secure reward random number for round $j$ is computed as `keccak256(abi.encode(s, V))`.
If $k > 1$, the same $s$ is used for rounds $j, j+1, \ldots, j+k-1$.

If there is no secure random number within all the remaining voting rounds of the current reward epoch, the first 30 rounds of the next reward epoch are evaluated.
If a secure random number is still not found, no rewarded feed is chosen and round rewards get burnt for the current and all subsequent rounds of the reward epoch.

## Anchor Feeds

The aim of the anchor feed rewards is to incentivize the FTSO outputs to be both accurate and prompt.
To this end, rewards are split across accurate individual estimations, correct signing, and prompt finalizing.
Additionally, as well as being rewarded for correct participation, providers must be punished in cases where they deviate from the expected behaviour of the protocol.

### Accuracy Rewards

The majority ($80\%$) of available rewards are allocated for submitting accurate values contributing to the median computation of the FTSO round; in the $j$th voting epoch these rewards are denoted by $R_{\mathrm{med}}(j)$.
FTSO accuracy rewards are allocated according to two criteria: rewards for submitting a value within the weighted interquartile range (called the primary reward band) of submitted values, and rewards for submitting a value within a fixed percentage interval around the weighted median value (referred to as the secondary reward band), whose width is determined by a parameter $q$ set by governance that varies by feed.
Denote these reward bands

$${IQR}(j) = [\argmin_{k: W_k > \lfloor W_C/4 \rfloor} \mathrm{Anchor}_k(j), \argmax_{k: W_k < \lceil 3 \cdot W_C/4 \rceil} \mathrm{Anchor}_k(j)] $$

and

$${PCT}(j) = [\mathrm{Anchor}(j) - q \cdot \mathrm{Anchor}(j), \mathrm{Anchor}(j) + q \cdot \mathrm{Anchor}(j)]$$

respectively.
In the case where a submission lies exactly on the border of the interquartile range (IQR), its eligibility, or lack thereof, for primary band rewards is determined randomly.
Note that providers can be eligible for both rewards for the same submission, and the bands typically overlap substantially.

Denote by $R_\mathrm{IQR}(j)$ the rewards available for submissions within the primary band and $R_\mathrm{PCT}(j)$ for those in the secondary, satisfying $R_\mathrm{med}(j) = R_\mathrm{IQR}(j) + R_\mathrm{PCT}(j)$.
Let

$$\Sigma_\mathrm{IQR}(j) = \sum_{i : \mathrm{Anchor}_i(j) \in \mathrm{IQR}(j)}W_{i,C}$$

and

$$\Sigma_\mathrm{PCT}(j) = \sum_{i : \mathrm{Anchor}_i(j) \in \mathrm{PCT}(j)}W_{i,C}$$

denote the total calculation weight of providers whose submissions lie in the primary and secondary band for the round respectively.
Then, an individual provider $i$ with weight ${W_{i,C}}$ whose submission lies within the primary band gets reward ${R_\mathrm{IQR}}(i,j)$ defined as

$${R_\mathrm{IQR}}(i,j) = \frac{{W_{i,C}}}{\Sigma_\mathrm{IQR}(j)} \cdot R_\mathrm{IQR}(j),$$

and similarly reward ${R_\mathrm{PCT}}(i,j)$ for submissions within the secondary band

$${R_\mathrm{PCT}}(i,j) = \frac{{W_{i,C}}}{\Sigma_\mathrm{PCT}(j)} \cdot R_\mathrm{PCT}(j).$$

In the very unlikely case that the secondary band is empty, which is a theoretical possibility, secondary band rewards for the round are burnt.

### Signing Rewards

Signing rewards, denoted $R_\mathrm{sign}(j)$, make up around $10\%$ of the rewards for the round, and are allocated according to the weight of providers who submit valid signatures for the correct Merkle root in the sign phase or before finalization.
These rewards are provided to encourage prompt and correct participation in the signing phase.
In order to be eligible for signing rewards, a provider must have received accuracy rewards in the given round for the selected feed.

Let $\Sigma_{\mathrm{sign}}(j)$ denote the total weight of providers who correctly signed the agreed upon Merkle root in the sign phase or before finalization for the round.
Then, an eligible provider with weight $W_{i, \mathrm{sign}}$ who delivered a correct signature receives the reward ${R_\mathrm{sign}}(i,j)$ corresponding to their relative contribution to the total weight,

$${R_\mathrm{sign}}(i,j) = \frac{W_{i, \mathrm{sign}}}{\Sigma_\mathrm{sign}(j)} \cdot R_\mathrm{sign}(j).$$

### Finalization Rewards

The finalization rewards $R_\mathrm{fin}(j)$ make up around $10\%$ of the total rewards, and are distributed among the selected providers equally.
That is, in a round where the number of providers [selected](../FSP/Finalization.md#finalizer-selection) to finalize is $N_\mathrm{fin}(j)$, each of these providers that submits a valid finalization in the allotted time period receives the same finalization reward ${R_{\mathrm{fin}}}(i,j)$ equal to:

$${R_{\mathrm{fin}}}(i,j) = \frac{R_{\mathrm{fin}}(j)}{N_\mathrm{fin}(j)}.$$

If none of the selected providers submit a valid batch of signatures of a correct Merkle root to the relay contract in the allotted time, then all rewards are instead allocated to the first other provider to do so.
These rewards are provided to encourage prompt finalization of the FTSO data feed values.

As with signing rewards, providers are only eligible to receive finalization rewards if they have also received an accuracy reward in the same round.
Note that this does not effect the amount of rewards assigned to each eligible provider: if $N_\mathrm{fin}(j)$ providers are initially selected to finalize, each of those who received accuracy rewards and successfully finalizes receives a reward $\dfrac{R_{\mathrm{fin}}(i,j)}{N_\mathrm{fin}(j)}$ regardless of how many of those providers were both selected to finalize and received the necessary accuracy rewards to be eligible for finalization rewards.
Corresponding rewards that would have been assigned to selected providers who did not first receive accuracy rewards are burnt.

## Block-Latency Feeds

Providers participating in the block-latency feeds are rewarded for their updates as long as the block-latency feed is sufficiently close to the next anchor value.
Rewards are distributed to providers proportionally to the number of updates they submit.
These rewards are derived from two sources: Flare's inflationary pool, and fees paid by users as volatility incentives to increase the number of updates per block.

### Total Reward and Distribution

The total rewards on offer for the block-latency feeds are in three parts: denoted by $R_\mathrm{part}$ the rewards for participation, by $R_\mathrm{acc}$ for participation in accurate rounds, and by $R_\mathrm{vol}$ for participation during active volatility incentives. These funds are determined at different intervals as follows:

* $R_\mathrm{part}$ is set at the start of each reward epoch.
  Between reward epochs, reward sizes may be modified.
  These may be removed at a later date once the fast update feeds are sufficiently established.
* $R_\mathrm{acc}$ is calculated at the end of each voting epoch.
* $R_\mathrm{vol}$ varies block-by-block.

The rewards $R_\mathrm{part}$ and $R_\mathrm{acc}$ are derived from the inflationary funds: in each reward epoch, the total amount of inflationary rewards is the sum of the rewards over each voting round in the epoch, $\sum_j R_\mathrm{block}(j)$.
The parameter defining the split of this fund into participation and accuracy rewards is a parameter set by governance.

Combining these rewards, it follows that during each block the total reward $R_\mathrm{ftot}$ satisfies

$$R_\mathrm{ftot} = R_\mathrm{part} / b_{re} + R_\mathrm{acc} / b_{ve} + R_\mathrm{vol},$$

where $b_{re}$ is the number of blocks in the reward epoch and $b_{ve}$ is the number of blocks in the voting epoch.

Each update in a block is assigned an equal share of the total reward for the block, allocated to the provider of that update.
Equivalently, the participation reward is allocated in proportion to the number of updates to the block-latency feeds made by a provider during the reward epoch, the accuracy reward in proportion to those made during the voting epoch, and the volatility reward in proportion to the number of updates in each block.

### Triggering Accuracy Rewards

The role of the accuracy reward $R_\mathrm{acc}$ is to maintain agreement between the fast update and scaling feeds of the FTSO.
These rewards are based on the FTSO reward bands: accuracy rewards are triggered as long as the value of the block-latency feed feed at time $t_\text{start}(j + 1)$ lies within the primary reward band for the scaling feed selected to determine rewards for the $j$th round.
As long as this is the case, the reward $R_\mathrm{acc}$ is released in full.

### Volatility Rewards

Individuals such as DApps or other customers of the data stream may seek to fund additional volatility by increasing the number of updates made to the scaling feeds.
Volatility incentive offers are made with the transfer of a corresponding monetary value $m$.
Each offer has a duration of effect, denoted $T_v$, a parameter controlled by governance that determines the number of blocks for which it is valid for and after which the offer expires.
In each of the blocks within the duration of effect, the total reward $R_\mathrm{vol}$ is increased by $m/{T_v}$, which is allocated uniformly to updates in that block.

## Penalization

Thus far, correct provider behaviour has been assumed.
Proper functioning of the FTSO process requires that the data revealed in the reveal phase by each provider correctly hashes to their commitment published in the commit phase.
Additionally, in the signing and finalization phases only one root should receive enough signatures to be finalized, requiring that each signer does not sign multiple messages.

For various reasons, providers may not always act as desired; either for malicious reasons, such as a provider backing out of their commitment, or just due to an honest error.
Regardless of the root cause, this is disincentivized by a slashing a chunk of the rewards earned by the offending provider.

Each mismatched reveal or excess signature is punished in the same way: by burning a lump sum of provider rewards.
The size of the sum is determined by the combination of a system parameter $R_\mathrm{pen}$, the weight of the provider, and the total available accuracy rewards for the round.
A provider with (normalized) calculation weight ${W_{i,C}}^*$ who requires penalization in a voting round with accuracy rewards $R_{\mathrm{anchor}}(j)$ is penalized by subtracting an amount

$${R_{\mathrm{pen}}}(i,j) = R_\mathrm{pen} \cdot ( {W_{i,C}}^* \cdot R_{\mathrm{anchor}}(j))$$

of their rewards for the round for each penalization accrued.
Penalizations are applied at the end of each reward epoch, so that the maximum penanalization cannot exceed the provider's earnings for the round.
However, penalizations can be deducted from earnings in any protocol, so that a provider with penalizations exceeding their earnings in the FTSO may also have some of their rewards for e.g. the FDC burnt as well.
