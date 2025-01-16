# Epoch

# Voting Epoch

The shortest time periods are called voting epochs with duration $D_V=90s$.
The voting epoch with ID $0$ started at $T_0$.
The voting epoch with ID $i$ starts at timestamp $T_0+i*D_V$, and includes all blocks with timestamps in the semi open interval $[T_0+i*D_V , T_0+(i+1)*D_V)$.
All timestamps in [Unix time](https://en.wikipedia.org/wiki/Unix_time).

# Reward Epoch

A reward epoch is consists of several voting epochs.
Expected length of a reward epoch is $D_{REW}=3360$ voting epochs ($3.5$ days).

The reward epoch with ID $0$ starts at voting epoch $F_0$.
The reward epoch with ID $j$ is expected to contain voting epochs with IDs from the interval $[F_0+j*D_{REW} , F_0+(j+1)*D_{REW})$.

The actual start of the reward epoch is defied by its [Signing Policy](./SigningPolicy.md).
It starts with voting epoch stated in signing policy and ends with the start of the next reward epoch (as stated in its signing policy).
It can never happen that a reward epoch starts before the expected start.
