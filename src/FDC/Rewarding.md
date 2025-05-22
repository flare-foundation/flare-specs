# Rewarding

Rewards for FDC are gathered from the following sources:

- attestation requests fees
- inflation

Rewards are distributed for participation in voting and finalization.

## Value of the round

The value of the round is sum of fee and inflation rewards

$$R(j) = R_I(j) + R_{\mathrm{fee}}(j)$$

and is only available if the round is successfully finalized.
The share $R_V(j) = 0.9 * R(j)$ is for voting and the share $R_F(j) = 0.1 * R(j)$ is for finalization.

### Fee Rewards

Let $R_{\mathrm{fee}}(j)$ be the sum of fees of all confirmed requests in voting round $j$, based on the consensus bit vector.

### Inflation Rewards

For each reward epoch, there is an assigned amount of inflation.
For the attestation types backed by the governance, a percent of inflation and a threshold is set.
If the number of successfully confirmed attestation requests of that type reaches the threshold, the designated inflation is set to be distributed, otherwise it is burned.

Let $I(r)$ be the inflation set to be distributed in the reward epoch $r$ and let $L(r)$ be the length of reward epoch in voting rounds.
The amount of inflation rewards for round $j$ in reward epoch $r$ is
$
R_I(j) = \frac{I(r)}{L(r)}.
$

## Success coefficients

A providers are eligible for rewards in proportion to their weights.
A provider $v$ with a fraction of total weight $w(v)$ with success coefficients $S(v,j)$ in round $j$ is eligible for

$$
R_V(j,v) = R_V(j) * w(v) * S(v,j)
$$

rewards in voting round $j$.

### Successful participation

A provider successfully participates in a round if the following is fulfilled:

- Provided a bitVote from submitAddress inside choose period and the provided bitVote dominated the consensus bitVote.
- Signed the (later) finalized Merkle root with signingPolicyAddress and provided the signature in grace period.

In such case, the success coefficient is $S(v,j) = 1$.

Or

- Did not provide bitVote or the provided bitVote did not dominate the consensus bitVote.
- Signed the (later) finalized Merkle root with signingPolicyAddress and provided the signature in grace period.

In such case, the success coefficient is $S(v,j) = 0.8$.

The rest of $R_V(j)$ that is not distributed is burned.

### Punishable offense

- Provided a signature of Merkle root that was different from the finalized one.
  This case also covers providing signatures of multiple Merkle roots.

or

- Provided a bitVote from submitAddress inside choose period and the provided bitVote dominated the consensus bitVote.
- Did not provide any Merkle root in time.

In such case, the success coefficient is $S(v,j) = -30$.

## Minimal condition
