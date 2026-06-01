# Rewarding

After each accepted vote, the [TEE proxy](../Reference/Components/Proxy.md) returns a signed receipt extending a per-instruction hash chain.
When voting ends, the [TEE machine](../Reference/Components/Machine.md) signs the final hash and emits it in the action result.

These artifacts are intended to feed reward attribution, but the consuming mechanism is not yet implemented or specified.

## Vote Receipts

Each accepted vote is acknowledged in the [`POST /instruction`](../Reference/Components/Proxy.md#external-write-apis) HTTP response with the [`VoteReceipt`](../Reference/Types/Abi/Voting.md#votereceipt) for that vote plus the proxy's [signature](../../Utilities/Signing.md) over it, produced with the proxy's identity key.

The proxy populates each receipt field as follows:

- `instructionHash`: the instruction's [`instructionHash`](Instructions.md#hashes).
- `sequence`: this vote's index in the [vote box](Voting.md#vote-boxes) (0, 1, 2, …).
- `signature`: the voter's signature (as submitted).
- `additionalVariableMessageHash`: keccak256 of this vote's `additionalVariableMessage`.
- `timestamp`: arrival timestamp at the proxy.
- `voteHash`: keccak256 of this vote's ABI-encoded [`VoteSequenceNext`](#vote-hash-chain).

### Vote-Hash Chain

The proxy maintains one vote-hash chain per [vote box](Voting.md#vote-boxes); each accepted vote extends it.

- **Initial hash** (set when the box opens): keccak256 of the ABI-encoded [`VoteSequenceInit`](../Reference/Types/Abi/Voting.md#votesequenceinit):
  - `instructionId`, `instructionHash`, `rewardEpochId`: from the instruction.
  - `teeId`: the proxy's TEE machine.
- **Next hash** (computed on each accepted vote): keccak256 of the ABI-encoded [`VoteSequenceNext`](../Reference/Types/Abi/Voting.md#votesequencenext):
  - `voteHash`: previous chain value (the initial hash for the first vote).
  - `sequence`, `signature`, `additionalVariableMessageHash`, `timestamp`: same as the matching receipt fields.

## RewardingData

The TEE machine builds [`RewardingData`](../Reference/Types/Wire/Action.md#rewardingdata) on every `end` instruction action, JSON-encodes it, and places it in [`ActionResult.data`](Actions.md#action-results).
Fields:

- `voteSequence`: a [`VoteSequence`](../Reference/Types/Wire/Action.md#votesequence) holding the final `voteHash`, the instruction's `instructionId`, `instructionHash`, `rewardEpochId`, `teeId`, and the per-vote `signatures`, `additionalVariableMessageHashes`, and `timestamps`.
  The TEE machine recomputes the chain locally from the action's signatures, variable messages, and timestamps.
- `signature`: the TEE machine's signature over `voteHash`, produced with its $\mathrm{TEE}_{\mathrm{ID}}$ key.
- `additionalData`: a copy of `ActionResult.additionalResultStatus`.
- `version`: the TEE machine's encoding version.

## Reconstructing the Vote Ordering

A verifier with the instruction, all $N$ per-vote receipts, and the final `RewardingData` can replay the chain and confirm the ordering:

1. Compute the initial hash $h_0$ from the instruction's `VoteSequenceInit` fields (see [Vote-Hash Chain](#vote-hash-chain)).
2. Order receipts by `sequence` ($0, 1, \ldots, N{-}1$).
   For each $i$, compute $h_{i+1}$ from $h_i$ and `receipt[i]`'s fields via `VoteSequenceNext`, and check it matches `receipt[i].voteHash`.
3. Check $h_N$ equals `RewardingData.voteSequence.voteHash`.
4. Verify the [TEE machine](../Reference/Components/Machine.md)'s signature on $h_N$ against the destination $\mathrm{TEE}_{\mathrm{ID}}$.
5. Verify each receipt's proxy signature against the proxy's identity key, and each voter's signature inside the receipt against the recovered [signer](Instructions.md#signers) address.

The receipts establish the order and proxy commitment; the final TEE signature anchors the chain to the machine.
