# Fast Update Feeds
Fast Update feeds enable data updates to be computed every block by publishing frequent incremental small value changes (updates) over time, rather than computing the values from scratch. This process relies on selecting random samples of data providers to submit incremental updates from the last stream value. Each chosen provider submits an update as a *unit delta*, stating whether the value should go up, down, or remain constant. This is then converted to a *numeric delta*, representing the percentage change of the value of a feed caused by a single unit delta. The size of the random sample, as well as the size of the numeric delta are two system parameters which enable the system to reflect desired data volatility whilst retaining appropriate levels of security. 

## Overview

### Updates and Eligibility

Updates to the data stream are given incrementally in a cadence of one or several for each block, with increments provided by data providers who are chosen by random sampling.  Each data provider submits a transaction that proves their eligibility, determined through cryptographic sortition, and gives a unit value change, termed a unit delta, for each data feed in the FTSO. 

Applied to the FTSO, cryptographic sortition is a process for selecting random providers to take part in rounds of the update protocol. Each block corresponds to a round of sortition, and the $i$th provider is selected to participate with probability proportional to its (signing) weight $W_{i,S}$ TODO: align notation. This selection is independent of that of the other providers and other rounds of the process, so that sortition does not pick a fixed number of users per block. Providers are able to cryptographically demonstrate that they have been selected to participate, and cannot cheat the process. 

The choice of eligible providers is pseudo-random and unpredictable. The amount of providers in a block is variable; it follows a binomial distribution with mean value $e$, a parameter which can be set by governance or by offering incentives.  Additionally, third parties may pay a fee, known as an *incentive offer*, to temporarily increase the (expected) number of data providers chosen to submit an update by each round of sortition. This allows the fast update feeds to correctly represent the prices of assets at times of extreme volatility.

In practice, it is not feasible to require that eligible providers submit their transaction in the same block as the round of sortition in which they are chosen, or even in the one afterwards. Therefore, each round of sortition provides credentials that are active for several blocks afterwards, the number of which is referred to as the *submission window* and denoted $s$.

### Encoding of updates

An update for a single fast update feed is a *delta* value, including 0, encoded using the standard *two's complement* format for a signed integer with a fixed number of bits.  The entire set of updates is provided as a packed array of signed-integer deltas, ordered according to a predetermined standard for data feeds.  Deltas are only allowed to have one magnitude, in either direction, or be zero. If larger value variations in single blocks are necessary the volatility incentive provides a mechanism to increase the value of $e$ to make this possible.

Each data feed has a configurable numeric delta increment, so that $\pm 1$ in a unit delta increment corresponds to an actual value update by that numeric delta.  For simplicity  the feeds' numeric deltas are all determined by a single precision parameter $p$, and are dynamic: when a feed has current value $P$, a unit delta increment $\delta$ updates the value to $\Delta P$, defined as:

$$\Delta P = (1 + p)^\delta P.$$

The precision value is chosen by governance, and is represented as a fixed-point number in the interval $(0,1)$ with a fractional part of 15 bits.

Updates to the fast update feeds generate a stream of values for each feed, where the value as of block $n$ is the value as of block $n - 1$ plus the overall delta in block $n$, defined as the application of each numeric delta increment of that block. This value is stored on chain and is maintained at each update transaction, so that the live value can be used in smart contracts.