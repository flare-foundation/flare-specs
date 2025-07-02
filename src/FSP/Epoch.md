# Epoch

The Flare System Protocol organizes time into discrete **voting** amd **reward epochs** to coordinate network activities and incentivize participation.

Each voting epoch lasts **90** seconds and is identified by a sequential ID, with precise start and end times determined by the network's [system parameters](https://github.com/flare-foundation/flare-smart-contracts-v2/tree/main/deployment/chain-config). These voting epochs are the fundamental units for submitting and reaching consensus on protocol data. Multiple voting epochs are grouped into a reward epoch, which typically spans **3.5 days** and consists of **3360** voting epochs.

Reward epochs serve as the accounting periods for aggregating protocol participation and distributing rewards. 

## Voting Epoch

The following system parameters define voting epoch timings:

- $T_{\text{0}}$ - start time of the first voting epoch.
- $D_{\text{epoch}}$ - duration of a voting epoch, in seconds. Currently fixed to $90$ seconds for all networks.
- $D_{\text{reveal}}$ - reveal deadline offset, in seconds. Currently fixed to $45$ seconds for all networks.

All timestamps are in [Unix time](https://en.wikipedia.org/wiki/Unix_time).

Start and reveal deadline timestamps for a voting epoch $v$ can be derived as follows:

$$t_{\text{start}}(v) = T_{\text{0}} + v \cdot D_{\text{epoch}}$$
$$t_{\text{reveal}}(v) = t_{\text{start}}(v) + D_{\text{reveal}}$$


A voting epoch $v$ includes all blocks with timestamps in the semi-open interval:

$$[t_{\text{start}}(v) , t_{\text{start}}(v + 1))$$

The current voting epoch ID can be derived as follows:

$$ id_\text{epoch}(t) = \left\lfloor \frac{\text{t} - T_{\text{0}}}{D_{\text{epoch}}} \right\rfloor$$

## Reward Epoch

The following system parameters define reward epoch timings:
- $V_{\text{0}}$ - voting epoch id marking the start of the first reward epoch.
- $D_{\text{epoch}}$ - reward epoch duration, in voting epochs.

A reward epoch $e$ contains voting epochs with IDs in the interval: 

$$[V_0+ e \cdot D_{epoch} , V_0+ (e+1) \cdot D_{epoch})$$


The reward epoch ID for given voting epoch $v$ can be derived as follows:
$$
     id_\text{epoch}(v) = \left\lfloor \frac{\text{v} - R_{\text{0}}}{V_{\text{epoch}}} \right\rfloor
$$

The actual start of the reward epoch is defied by its [Signing Policy](./SigningPolicy.md).
A reward epoch begins with the voting epoch specified in its signing policy and ends at the start of the next reward epoch, as defined by the subsequent signing policy. A reward epoch cannot start before its designated starting voting epoch.