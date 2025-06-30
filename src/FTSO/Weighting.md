# Weighting
The FTSOv2 protocol is a stake-based protocol, in the sense that the contribution to data feed values and other procedures by each provider is not equal. Rather, each provider's contribution to the protocol is proportional to its weight. Weight can be acquired in two ways: firstly, provider stake, the proportion of FLR tokens owned by the provider itself. Secondly, providers gain weight according to FLR tokens delegated to their address by other entities, who in turn receive a share of provider rewards for their delegation. Different phases of the FTSO process use different definitions of weight, as described below. Note that providers charge a small fee to their delegators, which manifests as them retaining a proportion of the reward allocated to the delegations. The size of this fee is set by the providers themselves.

## FTSO Calculation Weight
The median calculation for the FTSO uses only the delegation weight of the provider, the amount of wrapped Flare (WFLR) tokens delegated to the provider for participating in the FTSO protocol. If staking weight were taken into account, stake within the system held by providers inactive in the protocol would dilute the impact of WFLR delegation to active providers, potentially compromising the accuracy of the FTSO outputs.

Thus, for provider $i$ with weight $W_{D_i}$ of delegated tokens, the normalized FTSO calculation weight $W_{i,C}$ of the provider is equal to

$$W_{i,C} = \frac{W_{D_i}}{\sum_i W_{D_i}}.$$

This is the weight used for both the FTSO computation itself as well as the rewards on offer for successful FTSO participation.


## Signing Weight
The signing and finalization phases use the combination of both staked weight and delegated weight. Thus, the *normalized* signing weight $W_{i,S}$ of the $i$th provider can be calculated as 

$$W_{i,S} = \frac{(W_{S_i} + W_{D_i})}{W_{tot}}$$

where $W_{S_i}$ denotes the stake and $W_{D_i}$ the delegated stake of provider $i$, with $W_{tot}$ the total weight of the system, $W_{tot} = \sum_i (W_{S_i} + W_{D_i})$. In practice, all normalization is implicit; weights are used directly and parsed as percentages.

## Capping
In order to ensure that the system remains sufficiently decentralized, caps are enforced on the maximum weight that an individual provider can have in any given phase of the overall protocol. As the distinct phases of the FTSOv2 protocol have slightly different security requirements, the capping measures vary across the phases, as discussed below.

### Data Provider Capping
The goal of capping the individual provider contribution to the FTSO data feeds is to ensure that no individual entity has too much of an input to the median computation, which would damage the core property of decentralization. However, too aggressive a cap would distribute the feed values across too many low weight parties, who have little investment in the system, which in turn may enable Sybil attacks or damage the accuracy of the estimates.

The chosen cap is 2.5% of the weight in the system. If the weight of any providers in a round exceeds 2.5% of the total, then that provider's weight is considered to be exactly 2.5% in that round. Since normalization is implicit, if this cap is active (e.g.some providers have too much weight) then the removed weight $W_r$ is essentially redistributed across all providers proportionally to their existing, post-capped stake, e.g. the weight $W_{i,C}$ of provider $i$ is updated to:

$${W_{i,C}}^* = W_{i,C} \cdot \frac{100 + W_r}{100}.$$

so that in practice the capped providers have weight a little over the initial 2.5% cap.

### Capping Signing Weight
For signing weight, a more complicated two-step process is applied. As in the previous stage, the goal is to trade off decentralization against the possibility of disruption from many low-weight addresses. 

First, the same capping process as described in the previous paragraph is applied to the signing weight, so that each provider has a capped weight ${W_{i,S}}^*$. Then, a process known as *diversity weighting* is applied, rescaling each provider's weight proportionally to its value to the power of $3/4$. The purpose of diversity weighing is to further increase the decentralization by reducing the weight of larger providers. This relative increase in the power of low-weight providers is intended to decrease the number of low-weight providers required to end a signing phase, so that high-weight providers cannot halt progress by withholding signatures. Functionally, the signing weight $W_{i, \mathrm{sign}}$ of provider $i$ is set to:

$$W_{i, \mathrm{sign}} = \frac{{{W_{i,S}}^*}^{3/4}}{W_{s,tot}}$$

where $W_{s,tot}$ denotes the total post-weighted signing weight, $W_{s,tot} = \sum_i ({W_{i,S}}^*)^{3/4}$.