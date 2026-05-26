# InstructionLifecycle

State machine for one instruction from its on-chain emission to TEE-machine execution and (optionally) on-chain consumption of the result.

The other instruction-driven workflows ([XrpPayment](../../PMW/Workflows/XrpPayment.md), [Fdc2Attestation](../../FDC2/Workflows/Fdc2Attestation.md), [KeyAdd](KeyAdd.md), and so on) all compose this lifecycle.
For the type-level definitions, see [Concepts/Instructions](../Concepts/Instructions.md) and [Concepts/Actions](../Concepts/Actions.md); for the contract surface, [`FlareTeeManager § Sending Instructions`](../Reference/Contracts/FlareTeeManager.md#sending-instructions).

## Preconditions

- An extension is [configured](../FCE/Workflows/Configuration.md) with at least one TEE machine in `PRODUCTION`.
- An [instructions sender](../Concepts/Instructions.md#instructions-senders) is registered for the extension (or the caller is a [system instructions sender](../FCE/Concepts.md) for `F_`-prefixed op-types).
- The current [signing policy](../../FSP/SigningPolicy.md) is installed on every destination machine (per [SigningPolicyTransition](SigningPolicyTransition.md)).

## States

- `Issued` — `TeeInstructionsSent` emitted on the Flare C-chain; no relay client has yet submitted a signed copy.
- `Voting` — at least one signed copy has reached a destination [TEE proxy](../Reference/Components/Proxy.md); signatures are accumulating per machine.
- `Quorate` — proxy has enough signatures for some destination machine: the data-provider [voting threshold](../Concepts/Voting.md#pass-conditions), plus the cosigner threshold if the instruction specifies cosigners.
- `Executing` — the TEE machine has pulled the bundled [action](../Concepts/Actions.md) from its proxy queue.
- `Responded` — the TEE machine has posted an [action response](../Concepts/Actions.md#action-responses) back to the proxy.
- `Consumed` — the action response has been used on-chain (e.g. an FDC2 proof verified, an external transaction submitted, a payment status posted). Optional and operation-specific.
- `Expired` — the instruction's `rewardEpochId` falls more than one epoch behind the destination machine's active [signing policy](../Concepts/Machines.md#signing-policy) before reaching `Quorate`; the machine rejects it as stale.

## Initial State

`Issued`, immediately after the on-chain `TeeInstructionsSent` event fires.

## Transitions

### emit: ∅ → Issued

- **Action**: [`FlareTeeManager.sendInstructions(receivingTeesAndKeys, instructionId, opType, opCommand, originalMessage, additionalFixedMessage, cosigners, cosignersThreshold, claimBackAddress)`](../Reference/Contracts/FlareTeeManager.md#sending-instructions) or `sendSystemInstructions(...)` for `F_` op-types — payable.
- **Caller**: a registered [instructions sender](../Concepts/Instructions.md#instructions-senders) (or a system instructions sender for `F_` op-types).
- **Effects**: Emits [`TeeInstructionsSent`](../Reference/Contracts/FlareTeeManagerEvents.md#teeinstructionssent) carrying the instruction fields and the list of destination $\mathrm{TEE}_\mathrm{ID}$s; `instructionId` is bound to the issuing block's hash.

### vote: Issued | Voting → Voting

- **Action**: a relay client signs the instruction over [`hashForSigning`](../Concepts/Instructions.md#hashes) and POSTs it to the destination proxy.
- **Caller**: a [data provider](../../Terminology/Roles.md#data-provider) under the instruction's signing policy, or a [cosigner](../Concepts/Instructions.md#cosigners) listed on the instruction.
- **Guards**: signature recovers to the caller's Flare address; the proxy can match it to the on-chain `TeeInstructionsSent` event.
- **Effects**: proxy records the signature against the instruction; per-instruction tally updated.

### reachQuorum: Voting → Quorate

- **Action**: proxy detects that [pass conditions](../Concepts/Voting.md#pass-conditions) are satisfied for one destination machine.
- **Caller**: the [TEE proxy](../Reference/Components/Proxy.md) (internal).
- **Effects**: proxy assembles an [`Action`](../Reference/Types/Wire/Action.md#action) bundling the instruction with its accumulated signatures and enqueues it on the per-machine [processing queue](../Reference/Components/Proxy.md#processing-queues).

### dispatch: Quorate → Executing

- **Action**: TEE machine polls the proxy's [internal queue API](../Reference/Components/Proxy.md#internal-apis) and pulls the action.
- **Caller**: the [TEE machine](../Reference/Components/Machine.md).
- **Guards**: machine re-validates the action (matching `teeId`, registered `(opType, opCommand)`, in-range `rewardEpochId`, signature recovery, [pass conditions](../Concepts/Voting.md#pass-conditions)); a failed check produces an error response instead.
- **Effects**: action is in flight inside the enclave.

### produceResponse: Executing → Responded

- **Action**: TEE machine executes the handler for `(opType, opCommand)`, signs the result with either its identity key or a wallet key, and POSTs the [action response](../Concepts/Actions.md#action-responses) back to the proxy.
- **Caller**: TEE machine.
- **Effects**: response stored on the proxy and served via its public [API](../Reference/Components/Proxy.md). For some operations, the machine also performs an external side effect (XRPL signing, FDC2 attestation hash submission, etc.).

### consume: Responded → Consumed (optional)

- **Action**: an operation-specific on-chain verification call — e.g. [`Fdc2Hub.verifyProof`](../../FDC2/Reference/Contracts/Fdc2Hub.md), an external-chain submission, or an internal `confirm…` call — accepts the action response.
- **Caller**: any party willing to pay gas; typically the original instructions sender or a downstream user.
- **Effects**: operation-specific on-chain state change.

### expire: Issued | Voting → Expired

- **Action**: no explicit call. The destination TEE machine rejects the action when its `rewardEpochId` is more than one epoch behind the machine's active signing policy (per [Machine validation rule 4](../Reference/Components/Machine.md#validation)).
- **Effects**: the action will not execute; the proxy may still hold the signatures but no response is generated.

## Invariants

- `instructionId` is unique per emission and identical across all signed copies of the instruction.
- A signature contributes at most once to a single tally (data provider or cosigner; a signer present in both counts toward both).
- The proxy never dispatches an action until the [pass conditions](../Concepts/Voting.md#pass-conditions) hold.
- The TEE machine independently re-verifies the pass conditions before execution; a malicious proxy cannot bypass voting (see [Trust Model](../Concepts/TrustModel.md#untrusted-proxy)).
- A [_direct action_](../Concepts/Actions.md#direct-actions) bypasses `Issued → Voting → Quorate` and enters `Executing` directly via a separate queue; the rest of the flow is identical.

## Terminal States

`Responded`, `Consumed`, or `Expired`. Operations that produce only an off-chain artifact (e.g. an external transaction signed by the TEE) terminate at `Responded`; operations whose result is consumed on-chain terminate at `Consumed`.

## Notes

- Retry semantics: any signer can re-submit the same instruction to the proxy; duplicates are deduplicated by signature. Operations that mutate TEE state add their own replay protection (see [Trust Model](../Concepts/TrustModel.md#delivery-and-replay-semantics)).
- The proxy is untrusted but rate-limited and authenticated at the API level; even a fully malicious proxy can only delay or censor (see [Trust Model](../Concepts/TrustModel.md#untrusted-proxy)).
- For multi-machine instructions (multiple destinations), each destination machine runs its own copy of this lifecycle in parallel.
