# Anchor Feeds

The FTSOv2 protocol takes place in a sequence of _voting rounds_, with each iteration lasting exactly one round and pushing a single update to each data feed.
This produces a sequence of values known as the _anchor feed_, also referred to as the _scaling feeds_.
Each voting round begins at the start of a new [voting epoch](../FSP/Epochs.md#voting-epoch), determining the value of each anchor feed for that $90$ second epoch.
The value of each feed is determined by aggregating value submissions from each participating data provider into a weighted median value.

Each round takes place across two _voting epochs_, with rounds and epochs identified by _round ids_ and _epoch ids_ respectively, with enumeration aligned so that round $j$ begins at the same time as epoch $j$.
However, the duration of the voting round is longer than the epoch, so that more than one voting round may be proceeding at a time.

The $j$th voting round of the FTSOv2 protocol begins at time $t_\text{start}(j)$, and proceeds in four phases: the _commit_ phase, in which the data providers commit to their data vectors for the round, the _reveal_ phase, where the data providers reveal the values underlying their respective commits, the _sign_ phase, when providers collate data estimates to produce the median data values, and a _finalization_ phase, ending the round when a provider collects sufficiently many signatures of the median values for the data estimates to be finalized.

## Phases

### Commit Phase

The commit phase begins the voting round and lasts the entire $90$ second duration of the voting epoch $j$, spanning the window $[t_\mathrm{start}(j), t_\mathrm{start}(j + 1))$.
In this phase, each data provider $i$ computes their individual estimate $\mathrm{Anchor}_i(j)$ for each data feed and encodes it into a $4$-byte vector using offset binary encoding, then publishes a hash commitment to the combination $\mathrm{data}$ of these vectors.
The commitment is calculated as

$$\mathrm{Commit Hash} = \mathrm{Hash}(\mathrm{address}, j, \mathrm{rand}, \mathrm{data})$$

where $\mathrm{rand}$ is a locally generated $32$-byte random number and $\mathrm{address}$ the data provider's submit address.
This random number serves two purposes: it blinds the commit hash of the user from a search attack, and is used later (once revealed) to contribute to on-chain randomness.
Each provider's $\mathrm{CommitHash}$ is uploaded to the chain in a commit transaction, which is valid as long as its block timestamp correctly matches up with the voting epoch $j$.

### Reveal Phase

Beginning immediately after the commit phase ends, at time $t_\text{start}(j + 1)$, the reveal phase lasts $45$ seconds and requires each provider to reveal their individual estimates committed to in the previous phase.
To do so, they each complete a _reveal transaction_, revealing all inputs to their hash commitment.
Each provider reveals its estimates _data_ and its random number _rand_.
A reveal transaction is valid as long as the hash of the revealed data matches up with the hash commitment of the provider; validity of the reveal transaction can be confirmed off-chain, and also requires that the block timestamp of the transaction lies within the reveal phase.

### Signing Phase

The sign phase begins as soon as the reveal phase finishes.
During this phase, data providers collate submissions from the commit and reveal phases, filter out invalid submissions, and compute the weighted median anchor feed values.
At the same time, the revealed $\mathrm{rand}_i$ values are combined to produce a random number for the round (see [Round Random Number](#round-random-number) below).

#### Anchor Feed Values

To compute the weighted median, data providers first order the submissions $\mathrm{Anchor}_i(j)$ from lowest to highest.
Let $W_m = \sum_{i = 1}^{i = m} W_{i,C}$ denote the sum of the [calculation weights](../FSP/Weighting#ftso-calculation-weight) of the providers who submitted the $m$ lowest values, and let $W_C$ denote the combined calculation weight of all providers.
Then, for each anchor feed, the final price $\mathrm{Anchor}(j)$ is computed as

$$ \mathrm{Anchor}(j) = \argmin_{m : W_m \geq \lceil{W_C/2}\rceil} \mathrm{Anchor}_m(j)$$
if $W_C$ is even and

$$ \mathrm{Anchor}(j) = \argmin_{m : W_m \geq \lceil{W_C/2}\rceil} (\mathrm{Anchor}_m(j) + \mathrm{Anchor}_{m+1}(j))/2$$
if $W_C$ is odd.

#### Round Random Number

The random numbers revealed by each party in the reveal phase are combined into an aggregate random number for the round.
Each of the provider-generated 32-byte random value is parsed as a 256-bit unsigned integer $\mathrm{rand}_i$, and added together:

$$\mathrm{rand} = \left( \sum_i \mathrm{rand}_i \right) \bmod 2^{256}.$$

As long as all individual randomness contributions are added, and at least one $\mathrm{rand}_i$ was generated using a secure random process, the resulting output is a secure random value.
However, a provider could attempt to manipulate the resulting random number by selectively withholding their contribution (i.e., not revealing their random number in the reveal phase, or providing a value that doesn't match their commitment).
A "benching" mechanism is in place to disincentivize this behavior:

* If a provider fails to reveal their committed random number, they receive a reward penalty and are "benched" for the next $20$ voting rounds.
* If there are any newly benched providers in the current round, the resulting random number is generated, but marked as "insecure".
* If there are no newly benched providers, and at least two unbenched provider contributions are present, the random number is considered "secure".

A Boolean flag specifying whether the generated random number is considered secure is also added to computation output.

#### Round Results

Each provider packages together the computed weighted median feed values and the aggregated random number with its security flag into a [Merkle tree](../Utilities/MerkleTree.md), and then publishes a _sign transaction_ consisting of the Merkle root and a signature of the root.

This Merkle root itself can be used as a secure random value, and is accessible from smart contracts once finalized.

### Finalization Phase

The finalization phase begins at the end of the signing phase.
For this phase, a random selection of providers is chosen to participate, selected sequentially and independently with probability equivalent to their signing weight until more than $5\%$ of the total weight of providers has been selected.
Thus, the number of chosen providers varies, with enough providers chosen each round so that at least $5\%$ of the total signing weight of providers are able to finalize.
The results of this sampling are available in advance, so that providers know whether they have been selected for finalization before the phase begins.
This process is the same as described in [Finalization](../FSP/Finalization.md#finalizer-selection) .

Using the available signatures from the signing phase, each of the selected data providers can end the round by collating enough signatures for the same Merkle root and submitting them to the _relay contract_, which verifies that the signatures are valid and that a sufficient voting weight of signatures (at least $50\%$) has been submitted.
Assuming these checks pass, the Merkle root is published on the voting contract for the round.
If none of the selected providers have completed the finalization phase after $10$ seconds, it is opened to all data providers and concluded once any provider has submitted a finalization.

### Overlapping Phases

In practice, there is some overlap between the signing and finalization phases: the finalization process may be completed as soon as enough valid signatures are available for the voting round.
In this case, signatures deposited during the signing phase but after finalization is completed are still rewarded as normal.
Conversely, assuming finalization is not completed early, signatures deposited after the signing phase ends but before finalization is completed are considered valid and rewarded as usual.
