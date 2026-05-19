# Voting

_Voting_ is the [TEE proxy](../Components/TeeProxy.md) procedure that turns signed copies of an [instruction](Instructions.md) into a signed [action](Actions.md).

## Proxy Flow

For each instruction submitted via [`POST /instruction`](../Components/TeeProxy.md#external-write-apis), the proxy:

1. Recovers the [signer](Instructions.md#signers)'s address from the signature over [`hashForSigning`](Instructions.md#hashes).
2. Routes the submission to the [vote box](#vote-boxes) keyed by the instruction.
3. Counts the vote toward the [data provider](../../Terminology/Roles.md#data-provider) tally if the address is in the [signing policy](../../FSP/SigningPolicy.md) for the instruction's reward epoch, the [cosigner](Instructions.md#cosigners) tally if it appears in the instruction's `cosigners` list, or both.

Once the box reaches its [pass conditions](#pass-conditions), the proxy produces [actions](Actions.md) for the destination [TEE machine](../Components/TeeMachine.md); see [Outcomes](#outcomes).

## Vote Boxes

Each voting process runs in a _vote box_:

- Keyed by the carrying instruction's [`instructionId` and `instructionHash`](Instructions.md#hashes).
- Opened by the first valid signature from a data provider on a previously unseen pair, then closed after a deployment-configured expiration window.
  Cosigner-only signers cannot open a box; submissions that would do so are rejected and should be retried until a data provider has opened a matching box.
- Each signer may contribute at most one vote per box.

## Pass Conditions

A vote box _passes_ as soon as both conditions hold:

$$
\sum_{i \in V} W_i > t \qquad\text{and}\qquad C \geq c,
$$

where $V$ is the set of voting data providers, $W_i$ their weights under that signing policy, $t$ the data provider threshold, $C$ the count of cosigner signatures, and $c$ the cosigner threshold.
The cosigner term is vacuous when the carrying instruction lists no cosigners.

$t$ is the [signing policy's threshold](../../FSP/SigningPolicy.md#normalized-weights) for every command (including all user-defined commands) except [`F_FDC2 PROVE`](../Extensions/FDC2/Commands/Prove.md), which may carry a per-instruction override.

If the box closes without these conditions ever holding, it is silently dropped.

## Outcomes

A passing box produces two [instruction actions](Actions.md#instruction-actions), tagged in [`submissionTag`](../Types/Wire/Action.md#actiondata):

1. `threshold`: Produced when the box passes.
   The TEE machine executes the operation; the action's [result data](Actions.md#action-results) carries the operation output.
2. `end`: Produced when the box closes.
   The TEE machine emits the [`RewardingData`](Rewarding.md#rewardingdata) payload as the action's result data and performs no further operation work (system commands may run a consistency check at this stage and downgrade the status if it fails).

[`F_WALLET KEY_DATA_PROVIDER_RESTORE`](Commands/F_WALLET/KeyDataProviderRestore.md) is the exception: both actions are produced at close so the proxy can collect additional shares before key reconstruction.

Each accepted vote is acknowledged in the [`POST /instruction`](../Components/TeeProxy.md#external-write-apis) response with a signed receipt that feeds [reward attribution](Rewarding.md).
