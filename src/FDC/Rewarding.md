# Rewarding

Rewards for provider participation in the FDC are gathered from two sources: firstly, fees gathered from attestation requests are distributed among contributing providers.
Secondly, a proportion of Flare's inflationary funds are allocated to the rewarding of the FDC.
Rewards are distributed for participation in voting and in finalization.
For the $j\text{th}$ round of the the FDC, let $R_\mathrm{fee}(j)$ denote the total collected fees, and $R_\mathrm{IFDC}(j)$ denote the inflation assigned to the FDC.
Then, the rewards $R_\mathrm{FDC}(j)$ available for the FDC in the round, referred to as the _value_ of the round, is the sum

$$R_\mathrm{FDC}(j) = R_\mathrm{IFDC}(j) + R_{\mathrm{fee}}(j).$$

The value of the round is then split in to two sources of rewards: rewards for participating in the voting and attestation process, and rewards for finalization.
These rewards are parameterized by $R_\mathrm{att}(j)$ and $R_\mathrm{fin}(j)$, which satisfy

$$R_\mathrm{FDC}(j) = R_\mathrm{att}(j) + R_{\mathrm{fin}}(j)$$

and are set by governance; finalization rewards typically make up around 10% of the total FDC rewards.

## Triggering Rewards

The quantities $R_{\mathrm{IFDC}}(j)$ and $R_\mathrm{fee}(j)$ are not fixed, but instead determined by events occurring in the round $j$, corresponding to the $j\text{th}$ voting epoch, and in the reward epoch $r$ containing the $j\text{th}$ round.
These events are summarized below.

### Fee Based Rewards

The fee reward $R_{\mathrm{fee}}(j)$ is determined on a per-round basis, and is the sum of the fees of all _confirmed_ attestation requests in voting round $j$, based on the consensus bit vector and corresponding Merkle root described in [TODO: ref].
Fees for requests in round $j$ that were not confirmed are burnt.

### Inflationary Rewards

The inflationary rewards $R_\mathrm{IFDC}(j)$ are determined on a per-reward epoch basis, with an amount $R_\mathrm{IFDC}(r)$ of funds assigned to reward epoch $r$ dependent on the events of the reward epoch.
Once this quantity is determined, it is then distributed equally across each round in the reward epoch, so that $R_\mathrm{IFDC}(j) = \dfrac{R_\mathrm{IFDC}(r)}{D_\mathrm{epoch}}$, where $D_\mathrm{epoch}$ denotes the duration of a reward epoch in terms of voting epochs.

The inflationary funds assigned to the FDC are in place to reward data providers for supporting certain attestation types that are backed by governance.
A maximum amount of inflationary rewards $R_{\text{max}}(r)$ is assigned for the reward epoch.
Then, for each of these attestation types, a percentage of inflation and a threshold value is set.
If the number of successfully confirmed attestation requests of that type across the entire reward epoch reaches the threshold, then the designated inflation is distributed, otherwise it is burned.

The value $R_\mathrm{IFDC}(r)$ is the sum of the rewards assigned for each type that successfully reached the threshold. Let $A_G$ denote the set of attestation types supported by governance, and $A_G(r)$ the set of types which had a number of attestations exceeding their threshold in reward epoch $r$.
For an attestation type $a \in A_G(r)$ let $R_a(r)$ denote the percentage of inflationary rewards assigned to that type. Then, the total amount of inflationary funds assigned to the $r\text{th}$ reward epoch can be computed as:

$$R_\mathrm{IFDC}(r) = \sum_{a \in A_G(r)} R_a(r) \cdot R_{\text{max}}(r).$$

## Attestation Rewards

Assuming correct participation in the attestation and voting processes of the FDC, data providers are eligible to an amount of rewards proportional to their weight.
In cases of only partially successful participation, some of their rewards will be withheld; for provider $i$ in round $j$ this information is stored as a success coefficient $S(i,j) \in [0,1]$.
Thus, a provider $i$ with a fraction of total weight $W_{i, \mathrm{sign}}$ with success coefficients $S(i,j)$ in round $j$ is eligible for

$$
R_\mathrm{att}(i,j) = R_\mathrm{att}(j) \cdot W_{i, \mathrm{sign}} \cdot S(i,j)
$$

rewards in voting round $j$.

### Successful participation

A provider successfully participates in a round if it fulfilled the following criteria:

- Provided a bit-vote from submitAddress inside the choose period and this bit-vote dominated the consensus bit-vote.
- Signed the (later) finalized Merkle root with signingPolicyAddress and provided its signature in the grace period.

In such case, the success coefficient is $S(i,j) = 1$.

A partially successful provider still receives rewards if it only provided a signature but did not contribute to the bit vote e.g.

- Did not provide a bit-vote or the provided bit-vote did not dominate the consensus bit-vote.
- Signed the (later) finalized Merkle root with signingPolicyAddress and provided its signature in the grace period.

In such case, the success coefficient is $S(i,j) = 0.8$.
If the provider was unsuccessful in either of the above criteria, it receives no rewards e.g. $S(i,j) = 0$.
In cases where $S(i,j) < 1$, remaining rewards that would be allocated to the provider are burnt.

## Finalization Rewards

The finalization rewards $R_\mathrm{fin}(j)$ make up around 10% of the total rewards, and are distributed among the selected providers equally.
The process is the same as described in [TODO: cite FTSO rewards].
In a round where the number of providers selected to finalize is $N_\mathrm{fin}(j)$, each of these providers that submits a valid finalization in the allotted time period receives reward ${R_{\mathrm{fin}}}(i,j)$ equal to:

$${R_{\mathrm{fin}}}(i,j) = \frac{R_{\mathrm{fin}}(j)}{N_\mathrm{fin}(j)}.$$

If none of the selected providers submit a valid batch of signatures of a correct Merkle root to the relay contract in the allotted time, then all rewards are instead allocated to the first other provider to do so.
Note that each provider's reward is fixed regardless of the number of providers that actually submit a valid finalization: rewards that would be assigned to a provider that fails to submit a valid finalization are burnt, not redistributed.

## Penalization

As well as rewarded for contributing to the FDC, data providers are punished for inappropriate behaviour, regardless of whether or not the misbehaviour was malicious or an honest mistake.
Providers receive a penalization if they completed any of the following actions:

- Provided a signature of a Merkle root that was different from the finalized one, including providing signatures of multiple Merkle roots.
- Provided a bitVote from submitAddress inside the choose period which dominated the consensus bitVote but then did not provide a Merkle root in time.

In such case, the provider receives a penalization

$${R_{\mathrm{pen}}}(i,j) = R_\mathrm{pen} \cdot W_{i,\text{sign}} \cdot R_{\mathrm{att}}(j)$$

parameterized by $R_\mathrm{pen}$, which is currently set to $30$.
Equivalently, a penalization sets the success coefficient for the provider to $S(i,j) = -R_{\mathrm{pen}}$.
As in the FTSO, penalizations are applied at the end of each reward epoch and can not exceed the provider's total rewards in the reward epoch across all protocols.
