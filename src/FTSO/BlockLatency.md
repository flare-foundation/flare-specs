# Block-Latency Feeds
*Block-latency* feeds, also referred to as *fast update* feeds, enable data updates to be computed every block by publishing frequent incremental small value changes (updates) over time, rather than computing the values from scratch. This process relies on selecting random samples of data providers to submit incremental updates from the last stream value. Each chosen provider submits an update as a *unit delta*, stating whether the value should go up, down, or remain constant. This is then converted to a *numeric delta*, representing the percentage change of the value of a feed caused by a single unit delta. The size of the random sample, as well as the size of the numeric delta are two system parameters set by governance balancing volatility and security. 

## Overview
For a given data feed, the block-latency feed has a numeric value $P$ which changes according to updates given by providers. Updates to the block-latency feeds generate a continuous stream of values for each feed, where the value during block $n$ is calculated by applying any update transactions in the block to the value at the start of the block. The value at the start of the current block is stored on chain and maintained at each update transaction, so that the live value can be used in smart contracts.

### Updates and Eligibility

Updates to the data stream are given incrementally in a cadence of one or several for each block, with increments provided by data providers who are chosen by random sampling.  Each eligible data provider submits a transaction that proves their eligibility, determined through cryptographic sortition, and gives a unit value change, termed a unit delta, for each data feed in the FTSO. 

Applied to the FTSO, cryptographic sortition is a process for selecting random providers to take part in rounds of the update protocol. Selected providers are able to cryptographically demonstrate their eligibility. Each block corresponds to a round of sortition, and in each block the $i$th provider is selected to participate with probability $p_\mathrm{sort}(i)$ proportional to its normalized (signing) weight ${W_{i,\mathrm{sign}}}^*$, independently of the other providers. That is,

$$p_\mathrm{sort}(i) = {W_{i, \mathrm{sign}}}^* \cdot e, $$

where the parameter $e$ defines the mean number of selected providers per block.

Thus, the amount of providers in a block is not fixed, but instead follows a binomial distribution with mean value $e$. This parameter is set by governance, but can be temporarily modified by users.  To do so, third parties may pay a fee, known as an *incentive offer*, to temporarily increase the (expected) number of data providers chosen to submit an update by each round of sortition by a specified amount. This allows the block-latency feeds to correctly represent the prices of assets at times of extreme volatility.

In practice, it is not feasible to require that eligible providers submit their transaction in the same block as the round of sortition in which they are chosen, or even in the one afterwards. Therefore, each round of sortition provides credentials that are active for several blocks afterwards, the number of which is referred to as the *submission window* and denoted $s$.

### Encoding of updates

An update for a single fast update feed is a *delta* value, including 0, encoded using the standard *two's complement* format for a signed integer with a fixed number of bits.  The entire set of updates is provided as a packed array of signed-integer deltas, ordered according to a predetermined standard for data feeds.  Deltas are only allowed to have one magnitude, in either direction, or be zero. If larger value variations in single blocks are necessary the volatility incentive provides a mechanism to increase the value of $e$ to make this possible.

### Value of a feed
The block-latency feeds have a configurable numeric increment, so that $\pm 1$ in a unit delta increment corresponds to an actual value update by a numeric delta.  This is determined by a precision parameter $p$, and is dynamic: when a feed has current value $P$, a unit delta increment $\delta$ updates the value to $\Delta P$, defined as:

$$\Delta P= (1 + p)^\delta P.$$

The precision value is chosen by governance, and is represented as a fixed-point number in the interval $(0,1)$ with a 15-bit fractional part. Thus, the value $P$ of the block-latency feed in block $n$ is computed by applying each delta increment in block $n$ to the value $P_{n}$ at the start of block $n$,

$$P= \prod_i (1 + p)^{\delta_i} P_{n}$$

where $\delta_1, \dots, \delta_k$ denote the delta increments in block $n$.