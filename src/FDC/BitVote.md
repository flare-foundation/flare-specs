# Bit Voting

For a voting round to be successfully finalized, support for one Merkle root must surpass the voting threshold of at least $50\%$ of the weight of data providers.
This means that a majority of the data providers have to build the exact same Merkle tree, containing the same set of confirmed attestation requests.
Some attestation requests might be unstable, in the sense that some providers have the data to assemble a response and some do not.
For example, consider an attestation request related to a transaction on an external chain in a block which has only recently been published: some verifiers may perceive the block to be confirmed, while others may have a small delay and thus view it as unconfirmed.

Regardless of the cause, a few unstable requests could prevent successful finalization if no preventative measures were taken.
The bit-voting procedure, described in this section, allows providers to reach consensus on which attestation responses should be included in the Merkle tree for the round.

## Workflow

Each attestation request is assigned an index of arrival in the [collect phase](VotingProtocol.md#phases-of-a-voting-round).
If multiple requests have the same request bytes in one round, they are merged into one request whose fee is the summed fees of the matching requests and index is the lowest index of arrival among the merged requests.

As attestation requests arrive, data providers try to verify them and keep track of which requests they have successfully verified.
Once they have checked all the requests, each data provider assembles a binary bit-vector whose entry is $1$ on the $i$th place (counting from the right) if they can confirm the $i$th request and a $0$ otherwise.
An individual data provider's bit-vector is sometimes referred to as their _bit-vote_.

The bit-vector is encoded into hexadecimal and prepended with the number of unique requests (in $2$ bytes).
For example, in a round with $5$ distinct requests where the first, second, and fourth are confirmed, the resulting bit-vector is $01011$ and is encoded as `0x00050b`.
The provider sends the encoded bit-vector in calldata before the deadline of the choose phase, as part of the FSP transaction to the [`submit2`](../FSP/Submission.md#submit1-submit2) function of the `Submission` smart contract.

Each data provider then collects all valid bit-vectors submitted by other providers.
A data provider considers another data provider's bit-vector to be valid if it shows the same number of requests as their own, is posted by a submit address corresponding to a data provider in the signing policy, and is posted inside the [choose phase](VotingProtocol.md#phases-of-a-voting-round).
If a provider posts more than one valid bit-vector in a round, only the last is considered.

Each data provider uses the set of valid bit-vectors to compute the consensus bit-vector.
This off-chain computation computes a large set of requests with wide support among providers, according to the following principles:

- The consensus bit-vector has to be supported by more than $50\%$ of the total weight of providers.
- It has to be computed deterministically.
- It has to be computed in a reasonable time frame (a few seconds at most).

The consensus bit-vector then determines the set of requests that are contained in the consensus Merkle root for the round.

## Bit Vote Algorithm

The goal of Bit Vote algorithm is to to find a set $R$ of request that fulfills the following: Let

$T$ be the total weight of the data providers,
$S_R$ be the weight of the providers supporting all the requests in set $R$,
and $F_R$ be the sum of fees of the requests in the set $R$.

We define the value of $R$ as

$$
V_R = \min{\{0.8 \times T, S_R\}} \times F_R
$$

we want to find the set with the highest $V_R$.
The search space can be very large thus we use Branch and Bound technique.

### Inputs and Outputs

The bit-voting algorithm takes the following inputs:

- the set of bit-vectors (bit-votes) submitted by data providers together with each provider's weight.
- an array of request fees, where the $i\text{th}$ fee corresponds to the fees of the attestation request(s) assigned the $i\text{th}$ bit of the bit-vectors.
- the maximal number of steps, a parameter that is configured by governance. This is currently set to $20$ million.

The algorithm outputs a consensus bit-vector $B$, whose $i\text{th}$ entry is $1$ if the $i\text{th}$ attestation request should be included in the consensus Merkle root, and $0$ otherwise,

### Pre-Processing

The first stage of the bit voting algorithm is pre-processing, simplifying the space of bit-votes and requests so that it is easier to find a good consensus bit-vector.

#### Filtering

The aim of filtering is to identify request bits that will always be included or excluded in the final selection and votes that will either support (e.g. confirm all requests in) all suitable consensus bit-vectors or not support any appropriate candidates.

This results in 6 relevant sets:

- RemainingVotes
- AlwaysInVotes
- AlwaysOutVotes
- RemainingBits
- AlwaysInBits
- AlwaysOutBits

Filtering begins with all bit-votes in RemainingVotes and all bits in RemainingBits.
The other $4$ sets are then filled as follows:

1. Move all bits from RemainingBits that do not have more than $50\%$ support to AlwaysOutBits.
2. Move all votes from RemainingVotes that have ones on all the RemainingBits to AlwaysInVotes.
3. Move all votes from RemainingVotes that have zeros on all RemainingBits to AlwaysOutVotes.
4. Move all bits that are supported by all RemainingVotes to the AlwaysInBits.

This defines two additional terms: GuaranteedFees denotes the sum of fees of all bits in AlwaysInBits and GuaranteedWeight the sum of all of the weights of AlwaysInVotes.

#### Aggregating

Next, two aggregations are performed on bits and votes that agree on the remaining space: first, aggregate all remaining bits so that those that agree on all remaining votes are combined into a single bit, resulting in a set RemainingAggregatedBits.
The index of an aggregated bit is the lowest index of the bits that were aggregated and its fee is the sum of fees of the aggregated requests.

Secondly, aggregate remaining votes that agree on all remaining bits into a set of aggregated votes, giving rise to a set RemainingAggregatedVotes.
The index of the aggregated vote is the lowest index of the aggregated votes and its weight is the sum of their weights.

### Branch and Bound

Once the space of bit-votes and fees has been simplified, the search over consensus bit-vectors begins.
This proceeds in a sequence of searches referred to as _branch and bound_ algorithms.
In each branch and bound algorithm, the space of votes and bits is parsed in a tree structure, which is searched to locate several candidate consensus bit-vectors.
The best consensus bit-vector located by the search is then returned.
The bit-voting process contains two types of branch and bound algorithm: by bit and by vote.

#### Tree Structure

Each branch and bound process conceptualizes a rooted full binary tree whose depth is either the number of the RemainingAggregatedBits or RemainingAggregatedVotes.
Each node in each tree contains the following information:

- a set of included votes (includedVotes).
- a weight, defined as the sum of the weights of the included votes and the guaranteedWeight.
- a set of included bits (includedBits).
- a fee, defined as the sum of the fees of the included bits and the guaranteedFees.

The trees are constructed beginning from a root node containing all remaining bits and votes: children are defined by removing either bits or votes, as specified below.
The leaf nodes of each tree correspond to candidate consensus bit-vectors defined by all remaining bits and votes in the node.

#### Value of a Node

The aim of the branch and bound stage is to find the best consensus bit-vector for the round, where best is determined according to a value function.
Each node has a value, defined as:

$$

\mathrm{Value}(\mathrm{fees}, \mathrm{weight}) = (\mathrm{cappedWeight} _ \mathrm{fees}, \mathrm{weight} _ \mathrm{fees}),


$$

where $\mathrm{cappedWeight} = \mathrm{min}\{\mathrm{weight}, 0.8 * \mathrm{totalWeight}\}.$

In each tree, nodes will be constructed by removing either bits or votes from the parent node; consequentially, child nodes have value lower than or equal to that of their parents.

#### Branch and Bound Bits

The first type of branch and bound algorithm is by bits.
The branch and bound bits algorithm takes as input the sets of aggregated bits and votes, an order for RemainingAggregatedBits (specified as an input), and a maximum step count denoting how much of the tree will be explored.

A binary tree is then built, starting from a root node containing all remaining aggregated bits and remaining aggregated votes.
A node at depth $k$ that is not a leaf has two children:

- child0: has the $k\text{th}$ bit removed from includedBits and its fee deducted from the fees of the parent node.
  Votes and weight are unchanged from the parent node.
  Visiting such a node increases the step counter by $2$.
- child1: has all the votes that do not support the $k$th bit removed and their weights deducted from weight.
  IncludedBits and fees are unchanged.
  Visiting such a node increases the step counter by $1 + \mathrm{floor}(\#\text{VotesOnParentNode}/2)$.

The tree is then traversed to its leaves to find candidate consensus bit-vectors.
A bound CurrentBound on the value of the best tested bit-vector is set to an input bound (which could be the empty bound $\mathrm{Value}(0,0)$).
As described below, the branches of the tree are traversed, starting from the root node, until either the whole tree has been searched or the maximum step count is reached.
In what follows, the most recently visited node with an unexplored branch is referred to as the _next path_ node:

- If the weight of the node is less than half the total weight, return to the next path node and begin down the unexplored branch.
- If a node has a value less than or equal to CurrentBound, return to the next path node and begin down the unexplored branch.
- If a branch is traversed to the leaf, compute its value. If the value is greater than CurrentBound we set CurrentBound to the value. Then, return to the next path node and begin down the unexplored branch.

When the search reaches the maximum number of steps or the whole space has been searched, the algorithm outputs the bit-vector corresponding to the visited leaf with the highest value, with ties broken by selecting the first visited.
If no leaf surpasses the initial bound, an empty solution is returned.

#### Branch and Bound Votes

Branch and bound votes functions similarly to the bits case, except that now the space is searched by votes.
Again, the input consists of the sets of aggregated bits and votes and a maximum step count denoting how much of the tree will be explored. However, this time, the ordering input is on the set of RemainingAggregatedVotes.

Again, a node at depth $k$ that is not a leaf has two children; however, this time they are defined by votes:

- child0: has the $k\text{th}$ vote removed from includedVotes and its weight deducted from the weight of the parent node.
  Bits and fees are unchanged from the parent node. Visiting such a node increases the step counter by $2$.
- child1: has all the bits that are not supported by the $k\text{th}$ vote removed and their fees deducted from the fees.
  Votes and weight are unchanged from the parent node.
  Visiting such a node increases the step counter by $1 + \mathrm{floor}(\#\text{IncludedBits}/2)$.

Once again, the tree is traversed to its leaves to find candidate consensus bit-vectors, starting with an input CurrentBound.
The branches of the tree are traversed, starting from the root node, until either the whole tree has been searched or the maximum step count is reached:

- If the weight of the node is less than half the total weight or the value less than or equal to current bound, return to the next path node and begin down the next branch.
- If a branch is traversed to the leaf, compute its value.
  If the value is greater than CurrentBound we set CurrentBound to the value.
  Then, return to the next path node.

Again, when the search reaches the maximum number of steps or the whole space has been searched, the algorithm outputs the visited leaf with the highest value, with ties broken in order of visitation.
If no leaf surpasses the initial bound, an empty solution is returned.

### Bit Vote Specification

The bit voting algorithm proceeds as follows:

1.  Filter and aggregate the bit-votes and request bits.

2.  Compare the number of RemainingAggregatedVotes and RemainingAggregatedBits.
    If there are less votes, proceed with two iterations of the branch and bound votes process, with votes ordered as described in step 3.
    Otherwise, proceed with two iterations of the branch and bound bits process, with bits ordered as described in step 3.

3.  The first method is run in parallel with $2$ orderings and no initial CurrentBound.
    The strategies for branch and bound on votes are:

    - (a) Order votes in order of descending value ($\mathrm{weight}  * \mathrm{supportedFees}$) and at depth $k$ first explore child1 - branches where $k$th vote is included.
    - (b) Order votes in order of ascending value and at depth $k$ first explore child0 - branches where $k$th vote is not included.

    For branch and bound on bits, the strategies are:

    - (a) Order bits in order of descending value ($\mathrm{cappedSupport} * \mathrm{fee}$), with ties broken in order of uncapped support, and at depth $k$ first explore child1 - branches where $k$th bit is included.
    - (b) Order bits in order of ascending value and at depth k first explore child0 - branches where $k$th bit is not included.

    Run the first branch and bound, and if the whole space is searched before the maximal number of steps is reached, return the solution, which is the optimal consensus bit-vector according to value.
    If the whole space is not searched, the following procedure is added:

    - For branch and bound on votes, if an unincluded vote supports all included bits, the vote is added and the value is updated.
    - For branch and bound on bits, if an unincluded bit is supported by all the included votes, the bit is added and the value is updated.

    Both iterations of the branch and bound algorithm return a candidate consensus bit-vector, with the solution with higher value returned by this step.
    In a case of a tie, the solution from method (a) is returned.

4.  If neither of the first two methods searched the entire space, run both iterations of the other branch and bound method with currentBound set by the first solution.
    If either run results in a better solution, this is returned.
    In the case of a tie, the solution from the first method is returned.

5.  Return the candidate consensus bit-vector with the highest value according to steps 3 and 4.
    $$
