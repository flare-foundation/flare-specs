# Weighting
The FSP and other enshrined protocols are stake-based: the relative contribution made by each provider is not always equal, but instead proportional to their weight. Weight can be acquired in two ways: firstly, provider stake, the amount of FLR tokens owned and staked by the provider itself. Secondly, providers gain weight according to WFLR tokens delegated to their address, typically by other users. Different protocols within the Flare network use different definitions of weight, which are described in this page. 

In order to ensure that the system remains sufficiently decentralized, caps and other controls are enforced on the weights of providers, rather than just directly considering stake and delegation. The use cases for distinct weights have slightly different security requirements, and the corresponding control measures vary: these control measures are also laid out here.

## Signing Weight
The most commonly used weight across all protocols in the Flare network is the *signing* weight, sometimes referred to as the registration weight. The signing weight of a provider corresponds to the proportion of staked and delegated weight registered to the provider address. However, this correspondence is not direct: controls are applied to maintain decentralization of the system.

Explicitly, the signing weight $W_{i, \mathrm{sign}}$ of the $i$th provider can be calculated as 

$$W_{i, \mathrm{sign}} = (W_{S_i} + \max(W_{D_i}, W_{D\max,}))^{3/4}$$

where $W_{S_i}$ denotes the stake of the provider and $W_{D_i}$ the amount of WFLR delegated to the provider address. The capping term $W_{D\max,}$ and the exponent are explained below.

### Processing Signing Weight
A two-step control process is applied, the goal of which is to trade off-decentralization against the possibility of disruption from many low-weight addresses. 

First, a maximum weight capping process is applied to the delegation weight, so that each provider has a capped weight 
$$\overline{{W_{i,S}}} =W_{S_i} + \max(W_{D_i}, W_{D\max,}).$$

The chosen cap is 2.5% of the WFLR supply, so that $W_{D\max} = 0.025 * \mathrm{totalSupplyWFLR}$, the total supply of WFLR in the network. 

Following this, a process known as *diversity weighting* is applied, rescaling each provider's weight proportionally to its value to the power of $3/4$. The purpose of diversity weighing is to further increase the decentralization by reducing the weight of larger providers. Thus, the signing weight $W_{i, \mathrm{sign}}$ of provider $i$ is defined as:

$$W_{i, \mathrm{sign}} = \overline{{W_{i,S}}}^{3/4}$$.

In many use cases, this weight will be normalized; since normalization is implicit, if the cap is active (e.g. some providers have too much delegated WFLR) then the weight removed by the cap is essentially redistributed across all providers proportionally to their post-capped stake, so that in practice the capped providers have weight a little over the initial 2.5% cap. The normalized signing weight ${W_{i, \mathrm{sign}}}^*$ of the $i$th provider is

$${W_{i, \mathrm{sign}}}^* = \frac{W_{i, \mathrm{sign}}}{W_{s, tot}}$$

where $W_{s,\mathrm{tot}}$ denotes the total post-processed signing weight, $W_{s,\mathrm{tot}} = \sum_i {W_{i,\mathrm{sign}}}$.

## FTSO Calculation Weight
The median calculation for the FTSO protocol uses a separate weight measure, only considering the delegation weight of the provider. If staking weight were taken into account, stake within the network held by providers inactive in the protocol would dilute the impact of WFLR delegation to active providers, potentially compromising the accuracy of the FTSO outputs. Delegation weight is capped as before, to ensure that no individual provider has too control over the value of the median computaiton.

Thus, for provider $i$ with weight $W_{D_i}$ of delegated tokens, the FTSO calculation weight $W_{i,C}$ of the provider is equal to

$$W_{i,C} = \max(W_{D_i}, W_{D\max}),$$

where as before the cap is set at 2.5\%. This weight is used for both the FTSO computation itself as well as the rewards on offer for successful FTSO participation. 

Typically, normalized FTSO calculation weight will be used: since normalization is implicit, if the cap is active, the removed weight is essentially redistributed across all providers proportionally to their post-capped stake, so that providers normalized weight may slightly exceed 2.5%. That is, the weight $W_{i,C}$ of provider $i$ is normalized to:

$${W_{i,C}}^* = \frac{W_{i,C}}{\sum_i W_{i,C}}.$$