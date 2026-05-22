# Extension API

HTTP contract between a [TEE machine](../../Reference/Components/Machine.md) and its co-resident FCE process.
The TEE machine and the extension run inside the same confidential VM and communicate over a local HTTP loopback.
The TEE machine is the FCE's only client and only inbound caller; outbound results from the FCE flow back through the same machine.

The contract has two directions:

- **TEE machine → extension** — dispatching actions and reading extension state for attestation.
- **Extension → TEE machine** — delivering asynchronous results that the machine signs and forwards to its [TEE proxy](../../Reference/Components/Proxy.md).

## TEE machine → extension

The extension serves two endpoints on its local HTTP port.

### `POST /action`

Dispatches one inbound [`Action`](../../Reference/Types/Wire/Action.md#action) to the extension.

- **Request body** — the JSON [`Action`](../../Reference/Types/Wire/Action.md#action) as received from the [TEE proxy](../../Reference/Components/Proxy.md). The machine forwards it verbatim, with one restriction: the FCE only ever sees actions whose `submissionTag` is `threshold` (instruction action) or `submit` (direct action). `end` actions are built by the TEE machine locally (they always emit the [`RewardingData`](../../Concepts/Rewarding.md#rewardingdata) payload), so the extension is never consulted for them.
- **Response body** — a JSON-encoded [`ActionResult`](../../Reference/Types/Wire/Action.md#actionresult).
- **Failure** — any non-2xx response, malformed JSON, or HTTP-level error causes the TEE machine to fabricate a `status = 0` (error) `ActionResult` and proceed.

The TEE machine takes the returned `ActionResult` verbatim and wraps it in an [`ActionResponse`](../../Concepts/Actions.md#action-responses) signed with the machine's identity key, then posts it to the proxy.

**Echo requirement.** The proxy keys result storage by `(id, submissionTag)` without cross-checking the inbound action, so the extension must echo `id`, `submissionTag`, `opType`, and `opCommand` faithfully from the inbound `Action`. A result that mismatches on any of these is stored in an unreachable slot.

**Status semantics.** `status` values are interpreted by the proxy as:

- `0` (error/invalid) and `1` (success) — terminal. Once stored, never overwritten.
- `2`, `3`, … — transient (in-progress). Can be overwritten by a strictly greater transient or by a terminal. Lets the extension signal progress toward completion.

A sync-only extension returns `0` or `1` directly. An async extension may return `2`+ here and post the final result asynchronously (see [`POST /result`](#post-result) below).

### `GET /state`

Returns the FCE's current extension state, surfaced in [TEE attestations](../../Concepts/Machines.md#attestation) under the `state` field of [`TeeState`](../../Reference/Types/Abi/TeeMachine.md#teestate).

- **Response body** — a JSON object with two fields:
  - `stateVersion`: a `bytes32` version hash identifying the state schema this FCE version emits. Version `0` (32-byte zero) means "empty state".
  - `state`: the ABI-encoded state body for that version, as `bytes`.

The TEE machine treats this body as opaque: it never parses `state`, only forwards it. On-chain verification of attestation state is delegated to the FCE's [`stateVerifier`](../Concepts.md#extension-data-structure) contract.

## Extension → TEE machine

The TEE machine exposes one endpoint to the FCE, used for asynchronous result delivery.

### `POST /result`

Deliver an [`ActionResult`](../../Reference/Types/Wire/Action.md#actionresult) for an action whose initial `/action` response was transient (`status` $\geq 2$).

- **Request body** — a JSON-encoded `ActionResult`.
- **Effect** — the TEE machine wraps it in an [`ActionResponse`](../../Concepts/Actions.md#action-responses) signed with the machine's identity key and posts it to the [TEE proxy](../../Reference/Components/Proxy.md). The proxy's result-storage [override rules](#post-action) apply: a transient result can advance to a higher transient or to a terminal; a terminal result is immutable.
- **Echo requirement** — same as for `/action`: `id`, `submissionTag`, `opType`, `opCommand` must match the original inbound action.

This is the only mechanism by which an async FCE produces final results after returning an in-progress status from `/action`.

## Cosigner Enforcement

System actions enforce the instruction's [`cosigners`/`cosignersThreshold`](../../Concepts/Instructions.md#cosigners) inside the TEE machine before the FCE is called.
Custom FCE actions are dispatched _without_ any cosigner check by the machine: the FCE that defines a custom op-type is responsible for verifying the cosigner threshold itself before consuming any FCE-owned state.

## Connection

A reference deployment runs the FCE on `http://localhost:<port>` inside the same confidential VM as the TEE machine. The exact port is FCE-specific; the TEE machine reads it from its startup configuration. Outside-the-VM access to either endpoint is not part of the contract and is blocked at the network layer in production deployments.
