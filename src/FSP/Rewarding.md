# Rewarding

Rewards are distributed per reward epoch after its end based on the weights and performance of data providers.

Rewards are acquired across all protocols but are distributed together.
A provider has to satisfy certain minimal conditions in each protocol to be eligible for rewards.
A provider can get punished in one (or more) protocol which and the punishment is deducted from rewards in other protocols.
In the worst case, a provider gets zero rewards.

## Minimal conditions

A provider is eligible for the rewards only if they fulfill all the minimal conditions.

## Reward claims

Each reward claim contains:

- rewardEpochId - reward epoch ID for the reward.
- beneficiary - the address of the reward beneficiary or node id (20-bytes)
- amount - amount of the reward in FLR
- claimType - the type of reward claim.
  It can be one of:
  - direct - the reward is solely owed to the beneficiary (provided as address).
    This type of claims is used for back claims of undistributed rewards for providers of funds into rewarding pools, burn claims, or other direct rewarding approaches needed in sub protocols.
  - fee - similar to claims of type direct. Beneficiaries can be an eligible voter for the reward epoch only (his address is provided). The fees include WFLR delegation fees and node staking fees.
  - wflr - The beneficiary is an address of an eligible voter for the given reward epoch. The amount includes the value that should be distributed to the delegators according their share in WWFLR(beneficiary, rewardEpochId).
  - mirror - The beneficiary is a node ID of an eligible voter for the given reward epoch. The amount includes the value that should be distributed to the delegators according their share in WM(beneficiary, rewardEpochId).
  - cchain - The beneficiary can be only one of the eligible voters for the given reward epoch (address is provided). The amount includes the value that should be distributed to the delegators according to their share in WC(beneficiary, rewardEpochId).
