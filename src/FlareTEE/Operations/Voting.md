# Voting
In the Flare Confidential Compute architecture, *voting* is the process in which enough signatures from data providers and cosigners are collected to prepare an appropriately signed [action](Actions.md).
Data providers and cosigners send their signatures validating an instruction to the TEE proxy corresponding to the TEE machine on which the action will take place.
Once the proxy has received sufficient weight of signatures, it passes the action to the corresponding machine.

## Voting Process
A *voting process* is initialized when a data provider sends a signed instruction on an active signing policy to a TEE proxy. 
Here, active means either of the last two signing policies relayed to the TEE machine. 
Once a vote process is initialized, it is active for two minutes, or until the vote has passed with enough signatures. 
The amount of required signatures depends on the corresponding instruction, which includes parameters defining the weight of data provider signatures and number of cosigner signatures required. 
Once enough signatures have been received, the vote passes successfully, and the instruction can be turned into an action. 
On the other hand, if the vote process ends via time out, the vote has failed and no action is taken.

### Initialization and Conclusion
A TEE proxy on the signing policy for reward epoch $j$ receives a signed instruction from a data provider at time $T$.
At this point, the voting process begins, identified by `instructionHash`.
The proxy initializes a set of voters $V$ and a threshold $t$, fetched from the first instruction.
Each time the proxy receives a new vote from a provider with index $i$, $i$ is added to the set of voters $V$.
The vote remains open until either:

- The weight of set $V$ of providers who have voted exceeds the threshold, satisfying $\sum_{i \in V} W_i > t$.
-  The time reaches $T + 120$ seconds.

At which point, the voting process ends.
If the cosigner option was enabled on the instruction, then the first end condition (weight of providers) also requires that more cosigners than the cosigner threshold have submitted a vote for the instruction.

If the voting process ends because the threshold weight has been exceeded (and the cosigner threshold reached, if applicable), the vote concludes successfully and the proxy sends the instruction to the TEE machine as an [action](Actions.md).
A successful voting process produces two actions with submission tags `"threshold"` (at the point where the threshold is first reached) and `"end"` (at the conclusion of the voting period).
In some cases, only the `"threshold"` submission is produced.

If the vote fails (the threshold was not reached by `endTime`), the voting process is deleted from the proxy and no further actions are taken.

### Vote Tally Data Structure
The voting process for an instruction is identified by the relevant `instructionHash`.
 There may be several concurrent voting processes under the same `instructionID`, but only one will reach the signing threshold first and thus be executed by the TEE machine.
 At that point, each other voting process under the same `instructionID` are invalidated. 
  
The state of a vote process is tracked at the TEE proxy, which stores information given to it by the data provider who started the vote, and tallies the current state of the votes (signatures) received by providers and cosigners. 
Formally, the data structure stored at the TEE proxy contains:

- `instruction`: The instruction with an empty additionalVariableMessage.
- `threshold`: Threshold weight of signatures required given the current signing policy. Fetched on initialization of the voting process from the initial instruction. Has a minimum value of $30\%$.
- `cosigners`: List of cosigners permitted to sign the instruction.
- `cosignerThreshold`: The threshold number of cosigner signatures required.
- `weight`: Total accumulated weight of provider and count of cosigner signatures thus far.
- `startTime`: The timestamp at which the first vote was received at the TEE proxy, measured up to the second.
- `endTime`: The timestamp after which no further votes will be accepted, also measured up to the second.
- `proposer`: The (Flare) address that initialized the voting process.
- `votes`: Tracks the list of current voters. For each voter, the information `voterAddress` is stored, along with the list (`sequence`, `signature`, `relativeTime`, `additionalVariableMessage`). Relative time is the time after `startTime` that the vote was received, measured in seconds.
- `signatureCount`: Count of received signatures. This is used internally, to store the `sequence` field in votes.
- `voteHash`: A hash used to prevent tampering with the voter sequence. See the next section for more details.
- `status`: Initially set to active when the vote is initialized, then set to closed by the end of the voting process. At this point, no more votes are accepted.

### Voting Transparency
The voting process requires Flare's data providers to provide votes, including signed instructions, to the TEE proxies.
Since the data providers are rewarded for completing this process, the TEE proxy must store and provide information about the arrival time of the signatures. 
This is the information stored in `voteHash`, an iteratively computed hash tracking information about vote arrival. Information about how this data is used for rewarding can be found in [rewarding](Rewarding.md).

On arrival of the first vote, the initial `voteHash` is computed as a hash of an ABI encoding of the Solidity struct containing the instruction ID and hash, as well as the ID of the TEE and reward epoch:

```Solidity
struct VoteSequenceInit {
bytes32 instructionId;
bytes32 instructionHash;
uint32 rewardEpochId;
address teeId;
}
```
This `voteHash` is given a sequence number of $0$. 
On arrival of subsequent votes, a new `voteHash` is computed by hashing the ABI encoding of the Solidity struct `voteSequenceNext` defined as:

``` Solidity
struct VoteSequenceNext {
bytes32 voteHash;
uint64 sequence;
bytes signature;
bytes32 additionalVariableMessageHash
uint64 timestamp;
}
```
with each subsequent vote hash given a sequence number one higher than the previous. 
The `signature`, `additionalVariableMessageHash`, and `timestamp` fields are those taken from the incoming vote. 

Each time a new vote arrives and a new `voteHash` is computed, the TEE proxy signs a hash of the `VoteReceipt` message, again an ABI encoding of a Solidity struct containing

```Solidity
struct VoteReceipt {
bytes32 instructionHash;
uint64 sequence;
bytes signature;
bytes32 additionalVariableMessageHash
uint64 timestamp;
bytes32 voteHash;
}
```
with the fields each filled by those of the corresponding vote. 
That is, 
$$
\mathrm{VoteHash}_i = \mathrm{hash}(\mathrm{VoteSequenceNext}_{i}) 
$$
where
$$
\mathrm{VoteSequenceNext}_{i} = (\mathrm{VoteHash}_{i -1}, i, \mathrm{Sign}_i, \mathrm{hash}(\mathrm{VarMess}_i), \mathrm{Time}_i)
$$
where the final three parameters are the signature, additional variable message, and timestamp of the $\mathrm{i}$th vote.
The TEE proxy signs each of these hashes.

On conclusion of the action, the TEE machine itself signs the final `voteHash`; between this signature and the signer data in the [action result](Actions.md), all intermediate hashes and signatures can be reconstructed. 
This allows signer data published on-chain for rewarding purposes to be verified.