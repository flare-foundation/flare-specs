# Instructions

State machine for sending a custom (non-system) instruction to an [FCE](../README.md) and retrieving the result.
The instruction and action semantics belong to [Concepts/Instructions](../../Concepts/Instructions.md) and [Concepts/Actions](../../Concepts/Actions.md); the extension-side handler contract is the FCE's [`Api.md`](../Reference/Api.md).

## Preconditions

- The target extension is [registered and configured](Configuration.md); its `instructionsSender` field is set.
- At least one TEE machine of the extension is in `PRODUCTION`.
- `opType` does not carry the `F_` prefix (system extension only).
- Any extension-specific authorisation (e.g. application-level account permissions) is already satisfied.

## States

- `Unsent`: no on-chain instruction has been emitted for this request.
- `Emitted`: `FlareTeeManager.sendInstructions` (called through the extension's `instructionsSender`) has emitted [`TeeInstructionsSent`](../../Reference/Contracts/FlareTeeManagerEvents.md#teeinstructionssent); voting has not yet reached threshold.
- `Threshold`: the target proxies' [vote boxes](../../Concepts/Voting.md#vote-boxes) have passed; each proxy has dispatched a `threshold` tag [action](../../Concepts/Actions.md) to its TEE machine, which forwarded it to the extension via [`POST /action`](../Reference/Api.md#post-action).
- `Final`: the extension returned a terminal [`ActionResult`](../../Reference/Types/Wire/Action.md#actionresult) (`status` $\in \{0, 1\}$), either synchronously from `/action` or asynchronously via [`POST /result`](../Reference/Api.md#post-result). The proxy has stored the signed [`ActionResponse`](../../Concepts/Actions.md#action-responses) and serves it on `GET /action/result/<instructionId>`.

## Initial State

`Unsent`.

## Transitions

### sendInstructions: Unsent → Emitted

- **Action**: the caller invokes the extension's instructions sender contract, which ultimately calls [`FlareTeeManager.sendInstructions(teeIds, instructionParams)`](../../Reference/Contracts/FlareTeeManager.md#sending-instructions). The `instructionParams` carry `opType`, `opCommand`, `message`, optional `cosigners` and `cosignersThreshold`, and `claimBackAddress`. Payable.
- **Caller**: the address authorised by the instructions sender contract (extension-specific).
- **Guards** (enforced by `FlareTeeManager`):
  - `msg.sender = extension.instructionsSender` (or a [system instructions sender](../../Reference/Contracts/FlareTeeManager.md#caller-validation)).
  - `opType` does not begin with `F_`.
  - All `teeIds` belong to the same extension and are in `PRODUCTION`.
  - `msg.value ≥ operation fee`.
- **Effects**: emits [`TeeInstructionsSent`](../../Reference/Contracts/FlareTeeManagerEvents.md#teeinstructionssent); off-chain signers begin building and relaying signed instructions.

### vote: Emitted → Threshold

- **Action**: standard [voting](../../Concepts/Voting.md) on each target proxy.
- **Caller**: data providers (and cosigners, if any).
- **Guards**: data provider weight $\geq$ signing policy threshold (or per-instruction override) and cosigner count $\geq$ `cosignersThreshold`.
- **Effects**: each proxy enqueues a `threshold` tag [action](../../Concepts/Actions.md#instruction-actions); the TEE machine fetches it and calls [`POST /action`](../Reference/Api.md#post-action) on the extension.

### resolveResult: Threshold → Final

- **Action**: the extension returns an `ActionResult`. Either synchronously (terminal `status` in the `/action` response) or asynchronously (`status` $\geq 2$ from `/action`, followed by one or more [`POST /result`](../Reference/Api.md#post-result) updates, the last with terminal status).
- **Caller**: the FCE process (running co-resident with the TEE machine).
- **Guards** (enforced by the proxy's result store): terminal results are write-once; transient results can only be overwritten by a strictly greater transient or by a terminal.
- **Effects**: the TEE machine signs the result with its identity key, posts it as an [`ActionResponse`](../../Concepts/Actions.md#action-responses) to the proxy, and the proxy publishes it on `GET /action/result/<instructionId>`.

## Invariants

- A custom extension instruction's `opType` never has the `F_` prefix.
- The extension's `/action` endpoint never sees an `end` tag action (those are built locally by the TEE machine); see [Reference/Api](../Reference/Api.md#post-action).
- The result stored at `(id, submissionTag)` echoes the inbound `id`, `submissionTag`, `opType`, and `opCommand` faithfully. A mismatch produces an unreachable result; see the [echo requirement](../Reference/Api.md#post-action).

## Terminal States

`Final`.
The caller reads the result with `GET /action/result/<instructionId>` and decodes `result.data` per the extension's own result schema.

## Notes

- An extension that intentionally supports [direct actions](../../Concepts/Actions.md#direct-actions) can be addressed instead via the proxy's `POST /direct` endpoint, skipping `sendInstructions` and voting. The same `Threshold → Final` transition applies (with `submissionTag = submit` rather than `threshold`).
- For end-to-end authorisation, payload encoding, and result schemas, see the documentation of the specific extension. This workflow is the framework contract.