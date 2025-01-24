# Rewarding

Rewards are distributed per reward epoch after its end based on the weights and performance infrastructure entities.

Rewards are accrued across all protocols but are distributed together.
An entity has to satisfy certain minimal conditions in each protocol to be eligible for rewards.
An entity can get punished in one (or more) protocol and the punishment is deducted from rewards accrued in other protocols.
In the worst case, an entity gets zero rewards.

## WNatDelegationFee

## Minimal conditions

An entity is eligible for the rewards only if they fulfill all the minimal conditions.

## Reward claims

Each reward claim contains:

- rewardEpochId - reward epoch ID for the reward.
- beneficiary - the address of the reward beneficiary or node id (20-bytes)
- amount - amount of the reward in FLR
- claimType - the type of reward claim.
  It can be one of:

  - **direct** - The beneficiary is any address.
    The reward is solely owed to the beneficiary.
    This type of claims is used for back claims of undistributed rewards for providers of funds into rewarding pools, burn claims, or other direct rewarding approaches needed in sub protocols.
  - **fee** - Beneficiaries is the identity address an eligible entity for the reward epoch only (his address is provided).
    The fees include WFLR delegation fees and node staking fees.
    The reward is solely owed to the beneficiary.
  - **wflr** - The beneficiary is the delegation address of an eligible eligible for the given reward epoch.
    The amount includes the value is to be distributed to the delegators according their share in $W_D(beneficiary)$.
  - **mirror** - The beneficiary is a node ID of an eligible entity for the given reward epoch.
    The amount includes the value that is to be distributed to the stakers according their share in the amount staked to node ID.

## Distribution

Let $R$ be the rewards accrued by the entity $p$.
Let $W_P(p)$, $W_D(p)$, and $W'_D(p)$ be defined as in the calculation of
