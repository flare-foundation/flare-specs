# Weighting

The FSP and other enshrined protocols are stake-based: the relative contribution made by each provider is not always equal, but instead proportional to their weight.
Weight can be acquired in two ways: firstly, provider stake, the amount of FLR tokens owned and staked by the provider itself, as well as stake delegations to the provider.
Secondly, providers gain weight according to WFLR tokens delegated to their address, typically by other users.

In order to ensure that the system remains sufficiently decentralized, caps and other controls are enforced on the weights of providers, rather than just directly considering stake and delegation.
The computation of weight and control measures are laid out in this page.

## Stake and Delegation Values

An entity's weight is acquired through a mix of staked FLR and delegated WFLR.
However, these quantities fluctuate during the reward epoch, and thus during the validity of each successive signing policy.
Thus, a snapshot of the state of these values is taken and used for the duration of a signing policy.

In the $j$th reward epoch, the values defining the stake and delegation quantities of each provider correspond to those values in the randomly selected `VotePowerBlock` in the $j-1$th reward epoch, as described in [SigningPolicy](SigningPolicy.md#vote-power-block-selection).
Then, the stake of the $i$th provider $W_{S_i}$ is the amount of FLR staked to their node IDs in this block<!-- (as shown by [todo: cite P-Chain mirroring]) -->, while the delegation $W_{D_i}$ is the amount of WFLR delegated to their `delegationAddress` in this block.

The values $W_{S_i}$ and $W_{D_i}$ include both the amount contributed by the entity itself and other token owners who have staked or [delegated](Voters.md#staking-and-delegation) to the appropriate entity addresses.
For the purposes of weight computation, tokens staked or delegated by other users have the same value as those owned by the entity itself.

## Signing Weight

The weight used across all protocols in the Flare network is the _signing weight_, equivalent to the registration weight.
The signing weight of a provider corresponds to the proportion of staked and delegated weight registered to the provider address.
However, this correspondence is not direct: controls are applied to maintain decentralization of the system.

Explicitly, the signing weight $W_{i, \mathrm{sign}}$ of the $i$th provider can be calculated as

$$W_{i, \mathrm{sign}} = (\text{stakingFactor} \cdot W_{S_i} + \min(W_{D_i}, W_{D\max}))^{3/4}$$

where $W_{S_i}$ denotes the stake of the provider, $W_{D_i}$ the amount of WFLR delegated to them, and `stakingFactor` a governance defined multiplier currently set to $5%.
The capping term $W_{D\max}$ and the exponent are explained below.

## Processing Signing Weight

A two-step control process is applied, the goal of which is to trade off-decentralization against the possibility of disruption from many low-weight addresses.

First, a maximum weight capping process is applied to the delegation weight.
The chosen cap is 2.5% of the WFLR supply, so that $W_{D\max} = 0.025 * \mathrm{totalSupplyWFLR}$, where the total supply of WFLR in the network is readed from the `WNat` contract.

Following this, a process known as _diversity weighting_ is applied, rescaling each provider's weight proportionally to its value to the power of $3/4$.
The purpose of diversity weighing is to further increase the decentralization by reducing the weight of larger providers.

Note that due to the limits of computation in solidity, the exact exponent calculation is performed as

$$
W_{i, \mathrm{sign}} = \mathrm{floor}\left(\mathrm{floor}\left(W_i^\frac{1}{2}\right)^\frac{1}{2}\right)\mathrm{floor}\left(W_i^\frac{1}{2}\right),
$$

where $W_i = \text{stakingFactor} \cdot W_{S_i} + \min(W_{D_i}, W_{D\max,})$.

## Normalization
In many use cases, this weight will be normalized.
The normalized weight signing weight ${W_{i, \mathrm{sign}}}^*$ of the $i$th provider, also known as the signing policy weight, is defined as

$${W_{i, \mathrm{sign}}}^* = \lfloor \frac{W_{i, \mathrm{sign}} \cdot 65535}{W_{s, tot}} \rfloor $$

where $W_{s,\mathrm{tot}}$ denotes the total post-processed signing weight of all entities, $W_{s,\mathrm{tot}} = \sum_i {W_{i,\mathrm{sign}}}$.
