# Rewarding
Flare's data providers are rewarded separately for their contributions to the Anchor feeds and Block-Latency feeds. A proportion of Flare's inflationary funds are alocated to the rewarding of the FTSO. In a given voting epoch, denote this quantity $R_{tot}$. These funds are then distributed into $R_{FTSO}$, which are allocated to the anchor feeds, and $R_p$, which are allocated to participation in the block-latency feeds. The parameter defining the split of rewards between the two feeds, satsifying the equation

$$R_{tot} = R_{FTSO} + R_p,$$

is set by governance, and can be modified by a governance vote.

## Anchor Feeds
Rewards for participating in the anchor feeds of the FTSOv2 come from Flare's inflationary pool. 
The aim of these rewards is to incentivize the FTSO outputs to be both accurate and prompt. 
To this end, rewards are split across accurate individual estimations, correct signing, and prompt finalizing. 
The first of these rewards handles accuracy, with the other two primarily focused on efficiency. Additionally, as well as being rewarded for correct participation, providers must be punished in cases where they deviate from the expected behaviour of the protocol.

### Selecting a Rewarded Feed

Each round, rewards are determined according to performance in a single randomly selected data feed, rather than an aggregation of performance across all anchor feeds. The choice of data feed is sampled uniformly at random amongst existing data feeds, and is not known in advance. The random seed determining which feed is to be rewarded in a given round is generated as part of the process generating randomness in the round. This prevents providers from only focusing on the feed that is to be rewarded in a round: to maximize expected rewards providers should submit an accurate estimate for each feed. This applies both to assigning accuracy rewards and to determining eligibility for signing and finalization rewards: only one, randomly selected, feed is used.

### Accuracy Rewards
The majority (80%) of available rewards are allocated for submitting accurate values contributing to the median computation of the FTSO round; these rewards are denoted by $R_{\mathrm{FTSO}}$. FTSO accuracy rewards are allocated according to two criteria: rewards for submitting a value within the weighted interquartile range (called the primary reward band) of submitted values, and rewards for submitting a value within a percentage interval around the weighted median value (referred to as the secondary reward band), whose width is a parameter determined by governanace. In the case where a submission lies exactly on the border of the interquartile range (IQR), its eligibility, or lack thereof, for primary band rewards is determined randomly. Note that providers can be eligible for both rewards for the same submission, and the bands typically overlap substantially.

Denote by $R_\mathrm{IQR}$ the rewards available for submissions within the primary band and $R_\mathrm{PCT}$ for those in the secondary, satisfying $R_\mathrm{FTSO} = R_\mathrm{IQR} + R_\mathrm{PCT}$. Let $\Sigma_\mathrm{IQR}$ and $\Sigma_\mathrm{PCT}$ denote the total (post capping) weight of providers whose submissions lie in the primary and secondary band respectively. Then, an individual provider $i$ with weight ${W_{i,C}}^*$ whose submission lies within the primary band gets reward ${R_\mathrm{IQR}}^i$ defined as

$${R_\mathrm{IQR}}^i = \frac{{W_{i,C}}^*}{\Sigma_\mathrm{IQR}} \cdot R_\mathrm{IQR}$$

and similarly reward ${R_\mathrm{PCT}}^i$ for submissions within the secondary

$${R_\mathrm{PCT}}^i = \frac{{W_{i,C}}^*}{\Sigma_\mathrm{PCT}} \cdot R_\mathrm{PCT},$$

with these rewards split amongst the provider and its delegators proportionally to their contribution to the provider's weight. In the very rare case that the secondary band is empty, which is a theoretical possibility, secondary band rewards for the round are burnt.

### Signing Rewards
Signing rewards, denoted $R_\mathrm{sign}$, make up around 10% of the rewards for the round, and are allocated according to the weight of providers who submit valid signatures for the correct Merkle root in the sign phase or before finalization. These rewards are provided to encourage prompt and correct participation in the signing phase. In order to be eligible for signing rewards, a provider must have received accuracy rewards in the given round for the selected feed.

Let $\Sigma_{sign}$ denote the total weight of providers who correctly signed the agreed upon Merkle root in the sign phase or before finalization. Then, an eligible provider with weight $W_{i, \mathrm{sign}}$ who delivered a correct signature receives the reward ${R_\mathrm{sign}}^i$ corresponding to their relative contribution to the total weight,

$${R_\mathrm{sign}}^i = \frac{W_{i, \mathrm{sign}}}{\Sigma_\mathrm{sign}} \cdot R_\mathrm{sign}.$$

### Finalization Rewards
The finalization rewards $R_\mathrm{fin}$ make up around 10% of the total rewards, and are distributed among the selected providers equally. That is, in a round where the number of providers selected to finalize is $N_\mathrm{fin}$, each of these providers that submits a valid finalization in the allotted time period receives the same finalization reward ${R_{\mathrm{fin}}}^i$ equal to:

$${R_{\mathrm{fin}}}^i = \frac{R_{\mathrm{fin}}}{N_\mathrm{fin}}.$$

If none of the selected providers submit a valid batch of signatures of a correct Merkle root to the relay contract in the allotted time, then all rewards are instead allocated to the first other provider to do so. These rewards are provided to encourage prompt finalization of the FTSO data feed values.

As with signing rewards, providers are only eligible to receive finalization rewards if they have also received an accuracy reward in the same round. Note that this does not effect the amount of rewards assigned to each eligible provider: if $N_\mathrm{fin}$ providers are initially selected to finalize, each of those who received accuracy rewards and successfully finalizes receives a reward $\dfrac{R_{\mathrm{fin}}}{N_\mathrm{fin}}$ regardless of how many of those providers were both selected to finalize and received the necessary accuracy rewards to be eligible for finalization rewards. Corresponding rewards that would have been assigned to selected providers who did not first receive accuracy rewards are burnt.

## Block-Latency Feeds

Providers participating in the block-latency feeds are rewarded for their updates as long as the block-latency data stream is sufficiently close to the next anchor feed value. Rewards are distributed to providers proportionally to the number of updates they submitted in the round. These rewards are derived from two sources: Flare's inflationary pool, and fees paid by users as volatility incenvites to increase the number of updates per block.

### Total Reward and Distribution
The total rewards on offer for the Block-Latency feeds are in three parts: denoted by $R_p$ the rewards for participation, by $R_a$ for participation in accurate rounds, and by $R_v$ for participation during active volatility incentives. These funds are determined at different intervals as follows:

- $R_p$ is set at the start of each *reward epoch*. Between reward epochs, reward sizes may be modified. These may be removed at a later date once the block-latency feeds are sufficiently established.
- $R_a$ is calculated at the end of each voting epoch. 
- $R_v$ varies block-by-block.

Combining these rewards, it follows that during each block the total reward $R_t$ satisfies

$$R_t = R_p / b_{re} + R_a / b_{pe} + R_v,$$

where $b_{re}$ is the number of blocks in the reward epoch and $b_{pe}$ is the number of blocks in the voting epoch.

Each update in a block is assigned an equal share of the total reward for the block, allocated to the provider of that update.  Equivalently, the participation reward is allocated in proportion to the number of updates to the block-latency feeds made by a provider during the reward epoch, the accuracy reward in proportion to those made during the voting epoch, and the volatility reward in proportion to the number of updates in each block.

### Triggering Accuracy Rewards

The role of the accuracy reward $R_a$ is to maintain agreement between the block-latency and anchor feeds of the FTSO. These rewards are based on the FTSO reward system that defines several *reward bands* around the median value in each epoch, which encourage providers to predict the median value closely. The proposed accuracy rewards simply adjust the incentive as required so that  providers are rewarded for the block-latency feeds matching the anchor values.

Accuracy rewards are triggered as long as the value of the block-latency feed lies within the primary reward band for the anchor feed selected to determine rewards for the round. As long as this is the case, the reward $R_a$ is released in full.


### Volatility Rewards

Individuals such as DApps or other customers of the data stream may seek to fund additional volatility by increasing the number of updates made to the block-latency feeds. The pricing of this is such that the cost of increasing the number of updates scales exponentially.

Volatility incentive offers are made with the transfer of a corresponding monetary value $m$.  Each offer has a duration of effect, denoted $T_v$, a parameter controlled by governance that determines the number of blocks for which it is valid for and after which the offer expires.  In each of the blocks within the duration of effect, the total reward $R_v$ is increased by $m/{T_v}$, which is allocated uniformly to updates in that block.

## Penalization
Thus far, correct provider behaviour has been assumed. That is, proper functioning of the FTSO process requires that the data revealed in the reveal phase by each provider correctly hashes to their commitment published in the commit phase. Additionally, it was assumed in the signing and finalization phases that only one root receives enough signatures to be finalized, implicitly requiring that each signer does not sign multiple messages. Finally, it is assumed that providers complete their responsibilites in a timely manner. 

For various reasons, providers may not always act as desired; either for malicious reasons, such as a provider backing out of their commitment, or just due to an honest error. Regardless of the root cause, this is disincentivized by a slashing a chunk of the rewards earned by the offending provider. Details of the various punishments are laid out below.

### Punishing Explicit Misbehaviour
Each mismatched reveal or excess signature is punished in the same way: by burning a lump sum of provider rewards. The size of the sum is determined by a combination of a parameter $R_\mathrm{pen}$, the weight of the provider, and the total available accuracy rewards for the round. A provider with (normalized) calculation weight $W_{i,C}$ who requires penalization in a voting round with accuracy rewards $R_{\mathrm{FTSO}}$ is penalized by subtracting an amount

$${R_{\mathrm{pen}}}^i = R_\mathrm{pen} \cdot ( W_{i,C} \cdot R_{\mathrm{FTSO}})$$

of their rewards for the round for each penalization accrued. 

### Punishing Excessive Latency
The system punishes providers for failing to participate in this phase in a timely manner. If the signing process has not received enough weight of signatures before a certain number of blocks, $DB_{\mathrm{sign}}$, has passed in the signing phase, a burning process begins. For those providers who have not yet published a correct signature, a proportion of delegation fees are burnt in each subsequent block. Since provider fees are only obtained by providers who are rewarded for accurate data submissions in a given round, this burning procedure only affects successful providers who delay providing a signature. The proportion of fees burnt is quadratic in the number of blocks passed since $DB_{\mathrm{sign}}$, until a maximum block count $DB_{\mathrm{max}}$ is reached, at which point all fees have been burnt. The proportion $P_{\mathrm{burn}}$ of burnt fees by a provider publishing a signature in block $DB_{\mathrm{pub}} > DB_{\mathrm{sign}}$ is defined $P_{\mathrm{burn}} = \mathrm{min}(\mathrm{Burn}, 1)$, where 

$$\mathrm{Burn} = (\dfrac{DB_{\mathrm{pub}} - DB_{\mathrm{sign}}}{DB_{\mathrm{max}} - DB_{\mathrm{sign}}})^2.$$

The parameters of the burning system $DB_{\mathrm{sign}}$ and $DB_{\mathrm{max}}$ are set by governance.
