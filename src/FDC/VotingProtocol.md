# Voting protocol

The FDC protocol is organized as a sequence of **voting rounds** (or "attestation rounds").
In each voting round, attestation providers vote on a package of attestation requests.

Multiple attestation requests are collected and put up for vote in a single voting round.
Using a [Merkle tree](/specs/scProtocol/merkle-tree.md), hashes of all verified attestation responses can be assembled into a single hash (the **Merkle root**) that is used for finalization.
Proving that a specific attestation is confirmed requires a combination of an attestation response and the specific Merkle proof.

Voting on many requests at once using the Merkle root has its disadvantages.
Even if two attestation providers disagree on only one attestation request, their assembled Merkle roots are completely different.
Hence, even one problematic request can disrupt the agreement on the correct Merkle root for a round.
To mitigate this, the following synchronization and safety mechanisms are applied:

- [Message Integrity Code](/specs/attestations/hash-MIC.md#message-integrity-code).
  The request has to contain the hash of the expected response, therefore, at most one valid response (up to hash collision) is possible for each request.
- [Bit voting](/specs/scProtocol/bit-voting.md).
  In the event that the majority of providers cannot confirm an attestation request, the providers that potentially have the data to confirm the request are informed about others' inability and are encouraged not to include the response in the Merkle tree.
- [Lowest used timestamp](/specs/attestations/attestation-type-definition.md#lowest-used-timestamp).
  Attestation providers collectively agree on which data is too old to be used to assemble attestation responses.
- The providers only vote with signature and omit the Merkle root to prevent copying.
  Then only providers that know the correct Merkle root can collect the right signatures and finalize.

### Phases of a Voting Round

The FDC is integrated into FSP and proceeds in voting rounds with 3 phases. The FDC with round ID $i$ starts at the beginning of [voting epoch](../FSP/Epoch.md#voting-epoch) $i$, $t_{\text{start}}(i)$:

1. Collect phase: $[t_{\text{start}}(i), t_{\text{start}}(i+1))$. Requests emitted in this time period are considered in the voting round with ID $i$. A Data provider collects the requests, orders them chronologically and starts the verification process for each request.
2. Choose phase: $[t_{\text{start}}(i + 1), t_{\text{reveal}}(i + 1) )$.
  In this phase, a provider finishes verification of the requests collected in the previous phase and computes the bit-vector for the bit-vote.
  The bit-vector is submitted to the chain using the submit2 function of the [Submission](../FSP/Contracts/Submission.md) smart contract.

1. Resolution phase: $[t_{\text{reveal}}(i + 1), t_{\text{start}}(i + 2) )$.
   - During this phase, an attestation provider submits the signature of the Merkle root and consensus bitVote. The signature data is submitted to the chain using the submitSignatures function of the [Submission](../FSP/Contracts/Submission.md) smart contract. Providers are encouraged to submit signature in the first $D_{SG} = 10s$ or until the finalization, whichever is later.
   - The finalization is possible as soon as the threshold weight of signatures for any Merkle root is reached. In the first $D_{FG} = 20s$, only providers chosen by the sortition are encouraged to post collected signatures (as only they are eligible for a reward until then) after that everyone is encouraged to post collected signatures in $45s$.
