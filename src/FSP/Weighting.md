# Weighting
The FSP and other enshrined protocols are stake-based: the relative contribution made by each provider is not always equal, but instead proportional to their weight. Weight can be acquired in two ways: firstly, provider stake, the amount of FLR tokens owned and staked by the provider itself. Secondly, providers gain weight according to WFLR tokens delegated to their address, typically by other users. Different protocols within the Flare network use different definitions of weight, which are described in this page. 
In order to ensure that the system remains sufficiently decentralized, caps and other controls are enforced on the weights of providers, rather than just directly considering stake and delegation. The use cases for distinct weights have slightly different security requirements, and the corresponding control measures vary: these control measures are also laid out here.

## Stake and Delegation Values
An entities weight is acquired through a mix of staked FLR and delegated WFLR. However, these quantities fluctuate during the reward epoch, and thus during the validity of each successive signing policy. Thus, a snapshot of the state of these values is taken and used for the duration of a signing policy.

In the $j$th reward epoch, the values defining the stake and delegation quantities of each provider correspond to those values in the randomly selected VotePowerBlock in the $j-1$th reward epoch, as defined in [todo:cite signing policy]. Then, the stake of the $i$th provider $W_{S_i}$ is the the amount of FLR staked to their node IDs in this block (as shown by [todo: cite P-Chain mirroring]), and the delegation $W_{D_i}$ the amount of WFLR delegated to their delegationAddress in this block. 

## Signing Weight
The most commonly used weight across all protocols in the Flare network is the *signing* weight, equivalent to the registration weight. The signing weight of a provider corresponds to the proportion of staked and delegated weight registered to the provider address. However, this correspondence is not direct: controls are applied to maintain decentralization of the system.

Explicitly, the signing weight $W_{i, \mathrm{sign}}$ of the $i$th provider can be calculated as 
$$W_{i, \mathrm{sign}} = (W_{S_i} + \min(W_{D_i}, W_{D\max}))^{3/4}$$
where $W_{S_i}$ denotes the stake of the provider and $W_{D_i}$ the amount of WFLR delegated to them. The capping term $W_{D\max}$ and the exponent are explained below.
### Processing Signing Weight
A two-step control process is applied, the goal of which is to trade off-decentralization against the possibility of disruption from many low-weight addresses. 

First, a maximum weight capping process is applied to the delegation weight, so that each provider has a capped weight 
$$\overline{{W_{i,S}}} =W_{S_i} + \min(W_{D_i}, W_{D\max,}).$$
The chosen cap is 2.5% of the WFLR supply, so that $W_{D\max} = 0.025 * \mathrm{totalSupplyWFLR}$, the total supply of WFLR in the network.

Following this, a process known as *diversity weighting* is applied, rescaling each provider's weight proportionally to its value to the power of $3/4$. The purpose of diversity weighing is to further increase the decentralization by reducing the weight of larger providers. Thus, the signing weight $W_{i, \mathrm{sign}}$ of provider $i$ is defined as:
$$W_{i, \mathrm{sign}} = \overline{{W_{i,S}}}^{3/4}.$$

Note that due to the limits of computation in solidity, the exact exponent calculation is performed as
$$
W_{i, \mathrm{sign}} = \mathrm{floor}\left(\mathrm{floor}\left(W_i^\frac{1}{2}\right)^\frac{1}{2}\right)\mathrm{floor}\left(W_i^\frac{1}{2}\right),
$$
where $W_i = W_{S_i} + \min(W_{D_i}, W_{D\max,})$.
### Normalization
In many use cases, this weight will be normalized; since normalization is implicit, if the cap is active (e.g. some providers have too much delegated WFLR) then the weight removed by the cap is essentially redistributed across all providers proportionally to their post-capped stake. When needed explicitly, the normalized signing weight ${W_{i, \mathrm{sign}}}^*$ of the $i$th provider is defined as
$${W_{i, \mathrm{sign}}}^* = \frac{W_{i, \mathrm{sign}}}{W_{s, tot}}$$
where $W_{s,\mathrm{tot}}$ denotes the total post-processed signing weight of all entities, $W_{s,\mathrm{tot}} = \sum_i {W_{i,\mathrm{sign}}}$.



## FTSO Calculation Weight
The median calculation for the FTSO protocol uses a separate weight measure, only considering the delegation weight of the provider. If staking weight were taken into account, stake within the network held by providers inactive in the protocol would dilute the impact of WFLR delegation to active providers, potentially compromising the accuracy of the FTSO outputs. Delegation weight is capped as before, to ensure that no individual provider has too much vote power.

Thus, for provider $i$ with weight $W_{D_i}$ of delegated tokens, the FTSO calculation weight $W_{i,C}$ of the provider is equal to
$$W_{i,C} = \min(W_{D_i}, W_{D\max}),$$
where as before the cap is set at 2.5\%. This weight is used for both the FTSO computation itself as well as when calculating the rewards on offer for successful FTSO participation. 
### Normalization
Again, normalized FTSO calculation weight will sometimes be relevant: since normalization is implicit, if the cap is active, the removed weight is essentially redistributed across all providers proportionally to their post-capped stake, so that providers normalized weight may slightly exceed 2.5%. Formally, the weight $W_{i,C}$ of provider $i$ is normalized to:

$${W_{i,C}}^* = \frac{W_{i,C}}{\sum_i W_{i,C}}.$$
