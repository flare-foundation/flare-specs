# Voting protocol

The FDC protocol operates in a sequence of _voting rounds_, sometimes referred to as attestation rounds.
In each voting round, many attestation requests are collected and put up for vote in a single voting round.
Flare's data providers then vote on a package of attestation requests to confirm from among the requests that arrived in that round.
Using a [Merkle tree](/specs/scProtocol/merkle-tree.md), hashes of all verified attestation responses can be assembled into a single hash (Merkle root) that is used for finalization.

Proving that a specific attestation is confirmed in a given round of the FDC requires a combination of an attestation response and a Merkle proof.
However, voting on many requests at once and packaging the confirmed attestations into a single Merkle root has its disadvantages: unless data providers agree on all requests in the voting round, their assembled Merkle roots are completely different.
Hence, even one problematic request could disrupt agreement on the correct Merkle root in a round.

To mitigate against this problem, the following synchronization and safety mechanisms are applied:

- [Message Integrity Code](/specs/attestations/hash-MIC.md#message-integrity-code): The request format is specified so that each request contains the hash of the expected response, so that there is only a single valid response to each request.
- [Bit voting](/specs/scProtocol/bit-voting.md): The bit voting process helps data providers see each others' view of the attestation requests, thus ensuring that they each answer the same set of requests in the round.
- [Lowest used timestamp](/specs/attestations/attestation-type-definition.md#lowest-used-timestamp): Attestation providers collectively agree on which data is too old to be used to assemble attestation responses.

Additionally, data providers vote on which requests to confirm by publishing their signatures of the Merkle root, rather than the root itself.
This ensures that data providers must actually verify each request themselves, rather than copying a response from another data provider.

## Phases of a Voting Round

The FDC is integrated into the FSP and proceeds in voting rounds with 3 phases.
The $i\text{th}$ round of the FDC starts at the beginning of the $i\text{th}$ [voting epoch](../FSP/Epochs.md#voting-epoch), e.g. at time $t_{\text{start}}(i)$, with each round running over two successive voting epochs. The phases are aligned as follows:

1. Collect phase: $[t_{\text{start}}(i), t_{\text{start}}(i+1))$.
   User attestation requests emitted in this time period are considered in the voting round with ID $i$.
   Data providers collect the requests, order them chronologically, and start the verification process for each request.
2. Choose phase: $[t_{\text{start}}(i + 1), t_{\text{reveal}}(i + 1) )$.
   In this phase, providers finish verification of the requests collected in the previous phase and compute their individual bit vector for the bit vote.
   The bit vector is submitted on-chain using the submit2 function of the [Submission](../FSP/Submission.md) smart contract.
   This process is explained in more detail in [Bitvote](./BitVote.md).
3. Resolution phase: $[t_{\text{reveal}}(i + 1), t_{\text{start}}(i + 2) )$.
   During this phase, data providers who can verify all requests stored in the consensus bit vote submit their signature of the corresponding Merkle root.
   The signature data is submitted to the chain using the submitSignatures function of the [Submission](../FSP/Submission.md) smart contract.
   Providers are rewarded for submitting a signature in the first $10$ seconds of the phase or any time before finalization, whichever is later.
   As soon as the threshold weight of signatures for any individual Merkle root is reached, finalization is possible.
   At this point eligible data providers should submit a finalization transaction to end the round.
   In the first $20$ seconds of the phase, only data providers selected to finalize by the random selection are rewarded for submitting a finalization transaction.
   If no valid finalization transaction is submitted in this window, finalization is opened up to all providers.
   The process for the random selection is explained in [todo: cite finalization].
