# TEE Proxy

A _TEE proxy_ is the public-facing gateway for its paired [TEE machine](Machine.md).
It accepts [instructions](../../Concepts/Instructions.md) and signatures from [data providers](../../../Terminology/Roles.md#data-provider) and [cosigners](../../Concepts/Instructions.md#cosigners), runs the [voting process](../../Concepts/Voting.md), queues [actions](../../Concepts/Actions.md) for the machine, stores results, and serves them onward to external consumers.
Each TEE machine has exactly one TEE proxy; together they form a registered FCC node.

## Proxy Identity

Each proxy holds an identity key pair generated at deployment.
The public part — $\mathrm{Proxy}_\mathrm{ID}$ — is registered on Flare against the machine's `teeId` at [registration](../../TeeManagement/Registration.md), and the proxy uses the private part to sign its receipts and action responses.

Both proxy and machine are owned by the same operator.
To prevent the operator from silently dropping requests at the proxy layer, every external-write API returns a receipt signed by the TEE machine itself.
Until a caller holds that receipt, it has no guarantee that the proxy forwarded the request.

## Signing Policy

The proxy keeps its paired TEE machine in sync with the current [signing policy](../../../FSP/SigningPolicy.md):

- On initialization, it installs the current policy on the machine via [`INITIALIZE_POLICY`](../Operations/F_POLICY.md#initialize_policy).
   The initial [attestation](../../TeeManagement/Attestation.md) lets data providers verify that the correct policy was installed.
- During operation, the proxy reads new policies from a C-chain indexer and pushes them via [`UPDATE_POLICY`](../Operations/F_POLICY.md#update_policy) as a [direct action](../../Concepts/Actions.md#direct-actions).

## Proxy-Issued Direct Actions

Every [direct action](../../Concepts/Actions.md#direct-actions) the proxy issues to its paired TEE machine on its own initiative:

| Command | Trigger | [Queue](#processing-queues) | Purpose |
|---|---|---|---|
| [`F_POLICY INITIALIZE_POLICY`](../Operations/F_POLICY.md#initialize_policy) | Once per paired TEE machine, on first connection | Direct | Seed the machine's first signing policy. |
| [`F_POLICY UPDATE_POLICY`](../Operations/F_POLICY.md#update_policy) | When a new signing policy becomes active on the Flare C-chain | Direct | Rotate the signing policy on the machine. |
| [`F_GET TEE_INFO`](../Operations/F_GET.md#tee_info) | Periodic, every $\sim 10$ s | Direct | Refresh the [last-attestation cache](#in-memory-stores) served at `GET /info`. |
| [`F_GET KEY_INFO`](../Operations/F_GET.md#key_info) | Periodic, every $\sim 60$ min | Direct | Sync the [key data store](#in-memory-stores) (keys present, nonces). |
| [`F_GET KEY_PROOF`](../Operations/F_GET.md#key_proof) | Follow-up to `KEY_INFO`, for pairs whose nonce changed | Direct | Fetch fresh [`SignedKeyExistenceProof`](../Types/Wire/Key.md#signedkeyexistenceproof) values for the key data store. |
| [`F_GET TEE_BACKUP`](../Operations/F_GET.md#tee_backup) | Via [result hooks](#result-hooks): per new key, or per stored key after each `UPDATE_POLICY` | Backup | Store fresh backups in the [backup store](#persistent-stores). |

The proxy does not issue any other `F_` action; all other `F_` instructions originate on-chain (`FlareTeeManager`, `Fdc2Hub`, `TeePayments`) and reach the proxy through [signers](../../Concepts/Instructions.md#signers).

## Signing Threshold Resolution

The proxy resolves the effective [cosigner](../../Concepts/Instructions.md#cosigners) set and data-provider threshold for an instruction based on its `(opType, opCommand)`:

1. [`F_XRP PAY`](../../PMW/Reference/Operations/Pay.md) and [`F_XRP REISSUE`](../../PMW/Reference/Operations/Reissue.md): cosigners are taken from the wallet configuration.
2. [`F_WALLET KEY_DATA_PROVIDER_RESTORE`](../Operations/F_WALLET.md#key_data_provider_restore): cosigners and thresholds are taken from the backup metadata.
3. [`F_FDC2 PROVE`](../../FDC2/Reference/Operations/Prove.md): the data-provider threshold is taken from `thresholdBIPS` in the [`Fdc2RequestHeader`](../../FDC2/Reference/Types/Abi/Fdc2.md#fdc2requestheader); a zero value falls back to the signing policy default.
4. All other instructions: `cosigners` and `cosignersThreshold` are taken from the instruction itself.

## Size Constraints

The proxy may reject an instruction before voting if the payload exceeds the supported size limits for that instruction family.
These limits apply to `originalMessage`, `additionalFixedMessage`, and `additionalVariableMessage`.
Each deployment publishes its own limit profile; an over-limit instruction never starts or advances a vote.

Example profile:

1. `originalMessage`: up to $50$ KiB for all families.
2. `additionalFixedMessage`: up to $100$ KiB for all families.
3. `additionalVariableMessage`: up to $50$ KiB for standard families.
4. `additionalVariableMessage`: up to $1$ MiB for [`KEY_DATA_PROVIDER_RESTORE`](../Operations/F_WALLET.md#key_data_provider_restore).

## Per-Provider Open-Vote Cap

The proxy enforces a per-data-provider cap on concurrently open voting processes.
When a data provider has more than the configured limit in flight, `POST /instruction` returns [$429$ Too Many Requests](#external-write-apis).
This is a deliberate DoS protection: it prevents a single compromised data provider from exhausting the proxy's in-memory vote-box state.

## Processing Queues

The proxy hosts three independent queues, each polled separately by the TEE machine so a slow or failing action on one queue does not block the others:

1. **Direct**: every [direct action](../../Concepts/Actions.md#direct-actions) except `TEE_BACKUP` — both proxy-issued system operations and externally submitted custom extension operations.
2. **Main**: [instruction actions](../../Concepts/Actions.md#instruction-actions).
3. **Backup**: [`TEE_BACKUP`](../Operations/F_GET.md#tee_backup) direct actions.

The proxy may apply per-queue filtering and may prioritize its own internal reads.

## Action Result Handling

When the TEE machine posts an [`ActionResponse`](../Types/Wire/Action.md#actionresponse) to the [internal result API](#internal-apis), the proxy:

1. Verifies the response's [TEE-machine signature](../../Concepts/Actions.md#action-responses) against its paired machine identity.
2. Runs any matching [result hook](#result-hooks).
3. Stores the response in the [action result store](#persistent-stores), keyed by `(actionId, submissionTag)`, subject to the [override rules](#result-store-override-rules) below.

When the same response is later served via the [external result API](#external-read-apis), the proxy adds its own [`proxySignature`](../../Concepts/Actions.md#action-responses) so consumers can authenticate the proxy as well.

### Result Store Override Rules

The action result store is keyed by `(actionId, submissionTag)` and enforces:

- A stored _final_ result ([`status`](../../Concepts/Actions.md#action-results) `0` or `1`) is immutable; any subsequent write is rejected.
- A stored _transient_ result (`status ≥ 2`) is overwritten only by a final result, or by a transient result with a strictly greater `status`. Equal or lower transient status is rejected.

Transient statuses are therefore monotonically increasing and final statuses are write-once.

### Result Hooks

A small set of successful system command results trigger proxy-side follow-up before storage:

1. [`UPDATE_POLICY`](../Operations/F_POLICY.md#update_policy): the proxy enqueues a [`TEE_BACKUP`](../Operations/F_GET.md#tee_backup) action on the backup queue for every stored wallet key.
2. [`KEY_GENERATE`](../Operations/F_WALLET.md#key_generate), [`KEY_DATA_PROVIDER_RESTORE`](../Operations/F_WALLET.md#key_data_provider_restore), [`KEY_DELETE`](../Operations/F_WALLET.md#key_delete): the proxy updates its tracked keys; additions also enqueue a `TEE_BACKUP` for the new key.
3. [`TEE_BACKUP`](../Operations/F_GET.md#tee_backup): the produced backup is made available via the [external backup APIs](#external-read-apis).

## Proxy State

### Persistent Stores

Survive proxy restarts; held in a key-value store that supports queues (Redis in the reference deployment, any equivalent backend works).
Retention is per record.

- **Action store**: `(actionId, submissionTag) → actionData`. Tracks the action payload that was queued for the machine. Retained for $30$ days.
- **Action result store**: `(actionId, submissionTag) → actionResult`. Tracks the result returned by the machine. Retained for $14$ days; `submit`-tag results for $30$ minutes. Subject to [override rules](#result-store-override-rules).
- **Backup store**: `backupIdHash → backupData`. Holds extracted key backups produced by [`TEE_BACKUP`](../Operations/F_GET.md#tee_backup), triggered by [`UPDATE_POLICY`](../Operations/F_POLICY.md#update_policy) and key generation/restoration. Retained for $8$ days.
- **Backup index store**: `(walletId, keyId) → backupIdHash`. Resolves a wallet key to the latest backup. Retained for $8$ days.

### In-Memory Stores

Recomputed on restart.

- **Voting process store**: `instructionHash → VotingProcess`. Tracks active voting processes; cyclic with one round per signing policy.
- **Voting process list**: `instructionId → []instructionHash`. Concurrent votes for the same instruction ID, scoped to the voting process store.
- **Key data store**: `(walletId, keyId) → (timestamp, SignedKeyExistenceProof)`. The proxy refreshes it periodically (every $\sim 60$ minutes) by combining [`KEY_INFO`](../Operations/F_GET.md#key_info) (returns `(walletId, keyId, nonce)` triples) with [`KEY_PROOF`](../Operations/F_GET.md#key_proof) (returns [`SignedKeyExistenceProof`](../Types/Wire/Key.md#signedkeyexistenceproof) for triples whose nonce changed). Entries for keys no longer present on the TEE are dropped on each sync.
- **Last attestation**: cached output of the most recent [`TEE_INFO`](../Operations/F_GET.md#tee_info), exposed at `GET /info`. Refreshed periodically, every $\sim 10$ seconds, with a challenge derived from the latest C-chain block hash.

## TEE Proxy APIs

A proxy exposes internal and external REST APIs.
In a production deployment the TEE machine and the internal APIs sit behind a firewall; the external APIs are public.

All APIs return standard HTTP responses.
A successful response is `200 OK` with a JSON body.
Error responses include a `description` field for diagnostics.
Malformed input returns `400 Bad Request`.

### External Write APIs

Used by [data providers](../../../Terminology/Roles.md#data-provider) and other external callers.
Every request carries a random challenge; responses return a receipt signed by the TEE machine.

- **`POST /instruction`** — submits a signed [`Instruction`](../Types/Wire/Instruction.md#instruction).
  The proxy validates the target TEE ID, the operation pair, and the signer identity before accepting or advancing the vote; queued actions land on the [main queue](#processing-queues).
  Responses:
  - **$200$ OK**: receipt with `instructionHash`, `sequence`, `signature`, `additionalVariableMessageHash`, `timestamp`, `voteHash`, and a proxy signature.
  - **$400$ Bad Request**: instruction malformed or over the [size limits](#size-constraints).
  - **$403$ Forbidden**: sender is not allowed to start a voting process (not a data provider); the client may retry after a short delay.
  - **$429$ Too Many Requests**: per-data-provider [open-vote cap](#per-provider-open-vote-cap) reached; the [relay client](RelayClient.md) should retry.
  - **$500$ Internal Server Error**: other error; details in `description`.

- **`POST /direct`** — submits a [`DirectInstruction`](../Types/Wire/Instruction.md#directinstruction) to create a [direct action](../../Concepts/Actions.md#direct-actions) for a non-system operation.
  Optionally enabled per deployment and may require API-key authentication.
  System (`F_`-prefixed) operations are rejected.
  Responses:
  - **$200$ OK**: receipt with `directInstruction` and `actionId`, signed by the proxy identity.
  - **$400$ Bad Request**: system op-type submitted to the external endpoint.
  - **$429$ Too Many Requests**: the corresponding action is or was already in the queue.
  - **$500$ Internal Server Error**: other error.

### External Read APIs

- **`GET /info`** — latest TEE attestation. Reads from the cached [`TEE_INFO`](../Operations/F_GET.md#tee_info) result.
  - **$200$ OK**: `teeInfo` (`challenge`, `publicKey`, `initialSigningPolicyId`, `initialSigningPolicyHash`, `lastSigningPolicyId`, `lastSigningPolicyHash`, `state`, `teeTimestamp`, `platform`, `attestation`, `proxySignature`).
  - **$503$ Service Unavailable**: proxy not yet initialized.

- **`GET /wallet/<walletId>/<keyId>`** — latest [`SignedKeyExistenceProof`](../Types/Wire/Key.md#signedkeyexistenceproof) and decoded [`KeyData`](../Types/Wire/Key.md) for the key.
  - **$200$ OK**: `info` (decoded fields) and `proof` (raw signed proof).
  - **$400$ Bad Request**: malformed `walletId` or `keyId`.
  - **$404$ Not Found**: no data for the given key.

- **`GET /action/result/<actionId>?submissionTag=<tag>`** — action result. Default `submissionTag = threshold`.
  - **$200$ OK**: `data` (the action result) and `proxySignature` over `hash(data.data)`.
  - **$400$ Bad Request**: malformed `actionId` or `submissionTag`.
  - **$404$ Not Found**: no data for the key.

- **`GET /action/status/<rewardEpochId>/<instructionId>`** — diagnostic view of the voting processes for an instruction.
  - **$200$ OK**: `instructionId`, `finalizedHash` (zero if none finalized), and `voteResults` (`instructionHash`, `weight`, `threshold`, `cosigners`, `cosignersThreshold`, `finalized`, `start`, `end` per process).
  - **$400$ Bad Request**: malformed `rewardEpochId` or `instructionId`.
  - **$404$ Not Found**: no data.

- **`GET /backup/<backupIdHash>`** — backup package by backup ID hash.
  - **$200$ OK**: `backupId` and JSON-encoded `backup`.
  - **$404$ Not Found**: no data.

- **`GET /backup/<walletId>/<keyId>`** — latest backup for a given private key.
  - **$200$ OK**: `backupId` and JSON-encoded `backup`.
  - **$404$ Not Found**: no data.

### Internal APIs

Behind a firewall; accessible only to the owner and the paired TEE machine.

- **`POST /queue/<queueId>`** — pops the next item from the named [processing queue](#processing-queues).
  - **$200$ OK**: `data` of the next action, or `null` if the queue is empty.
  - **$400$ Bad Request**: invalid `queueId`.

- **`POST /result`** — pushes an [`ActionResponse`](../Types/Wire/Action.md#actionresponse) back to the proxy.
  The proxy verifies the response's signature against the paired TEE machine before storing it.
  - **$200$ OK**: stored.

- **`GET /healthy`** — health probe.
- **`GET /startup`** — startup probe (returns `200 OK` once startup completes).
- **`GET /ready`** — readiness probe (returns `200 OK` once the proxy is ready to accept traffic).
