# Epoch

The Flare System Protocol organizes time into discrete **voting rounds** and **reward epochs** to coordinate network activities and incentivize participation.

Each voting round lasts **90** seconds and is identified by a sequential ID, with precise start and end times determined by the network's [system parameters](https://github.com/flare-foundation/flare-smart-contracts-v2/tree/main/deployment/chain-config). These voting rounds are the fundamental units for submitting and reaching consensus on protocol data. Multiple voting rounds are grouped into a reward epoch, which typically spans **3.5 days** and consists of **3360** voting rounds.

Reward epochs serve as the accounting periods for aggregating protocol participation and distributing rewards. 

## Voting Round

The following system parameters define voting round timings:

- $T_{\text{0}}$ - start time of the first voting round.
- $D_{\text{round}}$ - duration of a voting round, in seconds. Currently fixed to $90$ seconds for all networks.
- $D_{\text{reveal}}$ - reveal deadline offset, in seconds. Currently fixed to $45$ seconds for all networks.

All timestamps are in [Unix time](https://en.wikipedia.org/wiki/Unix_time).

Start and reveal deadline timestamps for a voting round $r$ can be derived as follows:

$$t_{\text{start}}(r) = T_{\text{0}} + r \cdot D_{\text{round}}$$
$$t_{\text{reveal}}(r) = t_{\text{start}}(r) + D_{\text{reveal}}$$


A voting round r includes all blocks with timestamps in the semi-open interval:

$$[t_{\text{start}}(r) , t_{\text{start}}(r + 1))$$

The current voting round ID can be derived as follows:

$$ id_\text{round}(t) = \left\lfloor \frac{\text{t} - T_{\text{0}}}{D_{\text{round}}} \right\rfloor$$


## Reward Epoch

The following system parameters define reward epoch timings:
- $R_{\text{0}}$ - voting round id marking the start of the first reward epoch.
- $D_{\text{epoch}}$ - reward epoch duration, in voting rounds.

A reward epoch $e$ contains voting rounds with IDs in the interval: 

$$[R_0+ e \cdot D_{epoch} , R_0+ (e+1) \cdot D_{epoch})$$


The reward epoch ID for given voting round $r$ can be derived as follows:
$$
     id_\text{epoch}(r) = \left\lfloor \frac{\text{r} - R_{\text{0}}}{D_{\text{epoch}}} \right\rfloor
$$

The actual start of the reward epoch is defied by its [Signing Policy](./SigningPolicy.md).
A reward epoch begins with the voting round specified in its signing policy and ends at the start of the next reward epoch, as defined by the subsequent signing policy. A reward epoch cannot start before its designated starting round.