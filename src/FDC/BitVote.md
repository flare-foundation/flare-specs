# Bit Voting

For a voting round to be successfully finalized, one Merkle root has to be backed by at least 50% of the weight.
This means that a majority of the data providers have to build the exact same Merkle tree.
Some attestation requests might be unstable in a sense that some providers have the data to assemble a response and some do not (note that the response is practically unique due to MIC).
An example is a request related to a transaction on in block which is just being confirmed sufficiently, and some verifiers may perceive the block to be confirmed, while others with small delay may perceive it as unconfirmed.
A few such unstable requests could prevent successful finalization.
The purpose of bit-voting is to reach consensus on which attestation responses should be included in the Merkle tree.

Bit-voting works as follows.
Each attestation request is assigned the index of arrival in the collect phase.
If more requests have the same request bytes in one round, they are merged into one request with summed fees and the lowest index of arrival among the requests merged.
Data providers try to verify the attestations as they arrive and keep track of which get verified.
Providers assemble a bit vector with 1 on the i-th place (counting from the right), if they can confirm i-th attestation request or 0 otherwise.
The bit-vector is encoded into hexadecimal and prepended with the number of unique requests (2 bytes).
For example, in a round with 5 requests (all different) where the first, second and fourth are confirmed we get bitVector $01011$ that is encoded to `0x00050b`.
The encoded bit-vector is sent in calldata before the deadline of the choose phase in the FSP submit1 transaction.
Each data provider collects bit-vectors submitted by other providers.
A bitVote is valid if it has the correct number of bits, is posted by a submit address that has a weight according to the signing policy, and is posted inside the choose phase.
If a provider posts more than one valid bitVote in a round, only the last is considered.
Valid bitVotes are used to compute the consensus bit-vector.

## Bit Vote algorithm

The algorithm takes the following inputs:

- bit vectors with weight sorted by the index of the voter as defined in the signing policy.
- array of fees, where i-th fee corresponds to the attestation assigned i-th bit (counted from the right) of bit vectors.
- total weight.
- Maximal number of steps.

### Pre-Processing

#### Filtering

The aim of filtering is to identify the bits and votes that will certainly be included or certainly excluded in the final selection.

We have 6 sets:

- RemainingVotes
- AlwaysInVotes
- AlwaysOutVotes
- RemainingBits
- AlwaysInBits
- AlwaysOutBits

We start with all votes in RemainingVotes and all bits in RemainingBits.
Then we:

1. Move all bits from RemainingBits that do not have more than 50% support to AlwaysOutBits.
2. Move all votes from RemainingVotes that have ones on all the RemainingBits to AlwaysInVotes.
3. Move all votes from RemainingVotes that have zeros on RemainingBits to AlwaysOutVotes.
4. Move all bits that are supported by all RemainingVotes to the AlwaysInBits.

GuaranteedFees is the sum of fees of all bits in AlwaysInBits.
GuaranteedWeight is the sum of all of the weights of AlwaysInVotes.

#### Aggregating

We aggregate remaining bits that agree on all remaining votes and form a set of RemainingAggregatedBits.
The index of the aggregated bit is the lowest index of the bits and its fee is the sum of fees.

We aggregate remaining votes that agree on all remaining bits and form a set of RemainingAggregatedVotes.
The index of the aggregated vote is the lowest index of the vote and weight is the sum of weights.

### Branch and Bound Bits

We order the RemainingAggregatedBits (we specify how later).
The search space is the power set of the RemainingAggregatedBits.
We conceptualize the following rooted full binary tree whose depth is the number of the RemainingAggregatedBits:

Each node has the following:

- votes
- weight (weight of the votes + guaranteedWeight)
- includedBits
- fees (fees of included bits + guaranteedFees)

The node has value

$$
\mathrm{Value}(\mathrm{fees}, \mathrm{weight}) = (\mathrm{cappedWeight} * \mathrm{fees}, \mathrm{weight} * \mathrm{fees}),
$$

where $$\mathrm{cappedWeight} = \mathrm{min}\{\mathrm{weight}, 0.8 * \mathrm{totalWeight}\}.$$

A node at depth $k$ that is not a leaf has two children:

- child0: has $k$-th bit removed from the includedBits and its fee deduced from fees.
  Votes and weight remain unchanged.
  Visiting such node increased the steps counter by $2$.
- child1: has all the votes that do not support the $k$-th bit removed and their weights deducted from weight.
  IncludedBits and fees remain the same.
  Visiting such node increases the steps counter by $1 + \mathrm{floor}(\#VotesOnParentNode/2)$.

Note that the $\mathrm{Value}$ of a node is greater or equal to the value of its descendants.  
A leaf represents a feasible solution if its weight is more than 50% of the total weight and its $\mathrm{Value}$ is the $\mathrm{Value}$ of the solution.

The votes of the root are RemainingAggregatedVotes and includedBits are RemainingAggregatedBits.

At the beginning we set the CurrentBound to a known bound or $\mathrm{Value}(0,0)$ if there is not any.

We traverse the tree to the leaves according to the strategy.
If the maximal number of steps has been reached, the search is stopped.
If $2* weight$ of the node is less of equal to the $totalWeight$, its branches are not searched.
If a node has a Value lower or equal to CurrentBound, we do not search its branches.
Once we reach a leaf, we compute its Value, if the Value is greater than CurrentBound we set CurrentBound to the Value.

If the search exceeds the set number of steps or the whole space has been searched, the solution is the visited leaf with the highest Value (equal to the current bound).
If more leaves have the same value, the solution is the one that has been visited first.
If no leaf surpasses the initial current bound, an empty solution is returned (all votes, no bits).

### Branch and Bound Votes

We order the RemainingAggregatedVotes (we specify how later).
The search space is the power set of the RemainingAggregatedVotes.
We conceptualize the following rooted full binary tree whose depth is the number of the RemainingAggregatedVotes:

Each node has the following:

- votes
- weight (weight of the votes + guaranteedWeight)
- includedBits
- fees (fees of included bits + guaranteedFees)

The node has value

$$
\mathrm{Value}(\mathrm{fees}, \mathrm{weight}) = (\mathrm{cappedWeight} * \mathrm{fees}, \mathrm{weight} * \mathrm{fees}),
$$

where $\mathrm{cappedWeight} = \mathrm{min}\{\mathrm{weight}, 0.8 * \mathrm{totalWeight}\}.$

A node at depth $k$ that is not a leaf has two children:

- child0: has $k$-th vote removed from the votes and its weight deduced from weight.
  IncludedBits and fees remain unchanged.
  Visiting such node increases the steps counter by $1$.
- child1: has all the bits that are not supported by the k-th vote removed and their fees deducted from fees.
  Votes and weight remain the same.
  Visiting such node increases the steps counter by $1 + \#RemovedBits + \mathrm{floor}(\#IncludedBits)$.

Note that the $\mathrm{Value}$ of a node is greater or equal to the value of its descendants.  
A leaf represents a feasible solution and its $\mathrm{Value}$ is the $\mathrm{Value}$ of the solution.

The votes of the root are RemainingAggregatedVotes and includedBits are RemainingAggregatedBits.

At the beginning we set the CurrentBound to a known bound or Value(0,0) if there is not any.

We traverse the tree to the leaves according to the strategy.
If the maximal number of steps has been reached on a node that is not leaf, the search is stopped.
If $2* weight$ of the node is less of equal to the $totalWeight$, its branches are not searched.
If a node has a Value lower or equal to CurrentBound, we do not search its branches.
Once we reach a leaf, we compute its Value, if the Value is greater than CurrentBound we set CurrentBound to the Value.
If the maximal number of steps has been reached on a leaf, the its value is considered and then the search is concluded.

If the search exceeds the set number of steps or the whole space has been searched, the solution is the visited leaf with the highest Value (equal to the current bound).
If more leaves have the same value, the solution is the one that has been visited first.
If no leaf surpasses the initial current bound, an empty solution is returned (all votes, no bits).

### Ensemble

1.  Preprocess the data

2.  Decide which branch and bound to run first based on the number of RemainingAggregatedVotes and RemainingAggregatedBits.
    If there are less votes, branch and bound on votes is first, otherwise, branch and bound on bits is first.

3.  The first method is run in parallel with 2 strategies.
    The strategies for branch and bound on bits are:

    - (a) Order bits by their value descending ($\mathrm{cappedSupport} * \mathrm{fee}$) (ties are broken by ($\mathrm{support} * \mathrm{fee}$)) and at depth $k$ first explore child1 - branches where $k$-th bit is included.
    - (b) Order bits by their value ascending and at depth k first explore child0 - branches where $k$-th bit is not included.

      For branch and bound on votes, the strategies are:

      - (a) Order votes by their value descending ($\mathrm{weight}  * \mathrm{supportedFees}$) and at depth $k$ first explore child1 - branches where $k$-th vote is included.
      - (b) Order votes by their value ascending ($\mathrm{weight} * \mathrm{supportedFees}$) and at depth $k$ first explore child0 - branches where $k$-th vote is not included.

    Run the first branch and bound (twice).
    If the whole space is searched (maximal number of steps is not reached), it returns the optimal solution.
    If the whole space is not searched, the following procedure is added:

    - For branch and bound on bits, if an unincluded bit is supported by all the included votes, the bit is added. Value is updated.
    - For branch and bound on votes, if an unincluded vote supports all included bits, the vote is added. Value is updated.

    The better solution of both methods is returned.
    In a case of a tie, the solution from method (a) is returned.

4.  If the first method does not return an optimal solution, run the second bnb with currentBound set by the first solution. If the run results in a better solution, it is returned. In a case of a tie a solution from the first method is returned.

5.  Apply data from preprocessing to obtain the solution of the initial problem.
