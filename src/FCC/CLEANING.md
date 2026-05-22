# Cleaning Status

## Cleaned Files

Phase 2 [cleaning](#cleaning-plan) status:

- [x] `Images/`
- [x] `Operations/*.md` (except `Operations/Commands/`)
- [x] `Components/RelayClient.md`
- [x] `Architecture.md`
- [x] `README.md`
- [x] `../Utilities/Signing.md`

## Not Yet Cleaned

Files not listed in [Cleaned Files](#cleaned-files) have not been through a full Phase 1 + Phase 2 pass.
Mechanical fixes (link updates, naming, event corrections, type-ref updates) made during refactors of other files do not count as a cleaning pass.

## Cleaning Plan

For each `FCC/` file, work in two phases.

### Phase 1: Verify content

Verify factual claims against the latest code in:

- `~/flare/tee/*`
- `~/flare/fsp/flare-smart-contracts-v2`
- `~/flare/libs/go-flare-common`
- `~/flare/fdc/verifier-xrp-indexer`

Reads can hit the working tree directly, or `git show origin/<ref>:<path>` for an origin-pinned read.

Commit hashes captured on 2026-05-21 (refresh by re-fetching each remote and re-running the head log):

| Repo | Read ref | HEAD commit | Date |
|------|----------|-------------|------|
| `tee/tee-node` | `origin/main` | `4ba38512` | 2026-05-14 |
| `tee/tee-proxy` | `origin/main` | `31bfb8e0` | 2026-05-14 |
| `tee/tee-relay-client` | `origin/tee-diamond-cut` | `52eee370` | 2026-04-24 |
| `tee/go-verifier-api` | `origin/main` | `027fbbf0` | 2026-05-21 |
| `fsp/flare-smart-contracts-v2` | `origin/tee-diamond-cut` | `ff7f3cc4` | 2026-05-18 |
| `libs/go-flare-common` | `origin/tee-diamond-cut` | `876c09e6` | 2026-04-24 |
| `fdc/verifier-xrp-indexer` | `origin/main` | `fbf952c9` | 2026-04-17 |

`tee-node` is the base TEE machine implementation; deployments may extend it by composing user-provided FCE repos on top.

### Phase 2: Improve style

1. Apply the [style guide](../../STYLE_GUIDE.md).
2. Make content as terse as possible without losing information.
3. Prefer lists to prose.
4. Prefer linking to other files over repeating their content.
5. Link any term, role, concept, type, contract, or command discussed elsewhere in the docs on its first occurrence in the file.
6. Do not document implementation details.
   What counts as implementation detail:
   - Internal data structures, function decompositions, libraries, language-level choices, and storage backends.
   - Smart-contract functions that are not part of the user-facing surface.

   What is _not_ implementation detail and should be documented:
   - Periodic triggers — name the component that owns the schedule and give an approximate cadence as a "feel for the system" cue using $\sim$ (e.g. "the proxy issues `KEY_INFO` every $\sim 60$ minutes"). The exact cadence is impl detail, but the existence of the periodic loop is part of the externally observable behavior.
   - User-facing smart-contract interfaces — function names intended to be called by users, their parameters, ownership rules, and emitted events.

7. Treat each component as a black box: document only what crosses its boundary — HTTP requests/responses, on-chain calls and events, file artifacts handed to other parties, and externally observable timing or ordering guarantees (e.g. best-effort delivery, periodic refresh every $\sim X$ seconds, or that one queue's processing does not block another's).
   Do not document internal structs or formats that never leave the component.
   On-chain state and events count as external — document them.
8. Replace inline ABI and wire schemas with links into the canonical type docs (e.g. `Types/Abi/...` and `Types/Wire/...`); do not duplicate type definitions in prose.
9. Repair any broken inbound anchor links in other files when section anchors change.

### Order

1. `Extensions/` — `README.md`, `Concepts.md`, `FDC2/README.md`, `FDC2/Verifier.md`, `SystemExtension.md`, then `PMW/`.
2. `TeeManagement/` — `Registration.md`, `State.md`, `Attestation.md`, `Keys.md`, `FlareTeeManager.md`.
3. `Components/` — `TeeProxy.md` (`TeeMachine.md` and `RelayClient.md` are already cleaned).
4. `Workflows/`, `Extensions/FDC2/AttestationTypes/`, `Extensions/PMW/Commands/`, `Extensions/FDC2/Commands/` — leaf docs; pass last so they can defer to the now-canonical pages.

## Deferred FCC/ Restructure

- Consider moving `TeeManagement/FlareTeeManager.md` into `Components/`. The remaining `TeeManagement/` files (`Registration.md`, `State.md`, `Attestation.md`, `Keys.md`, `Wallets.md`) are topical aspects of `FlareTeeManager`'s behavior rather than separate contracts, so the diamond fits the "system components" set alongside `TeeMachine.md`, `TeeProxy.md`, and `RelayClient.md`. If executed, reframe `Components/` to cover both on-chain and off-chain components (not off-chain-only), give `TeeManagement/` either a new `README.md` overview or rename the dir to something like `OnChain/` or `ContractTopics/`, and sweep inbound links.

## Cross-cutting renames and fixes

Apply as a batch once the prose passes are settled, since they touch many inbound links.

#### Rename `TeeExtensionRegistry.md` → `FlareTeeManagerEvents.md`

The contract emitting `TeeInstructionsSent`, `TeeExtensionRegistered`, `TeeExtensionContractsSet`, `NewOwnerProposed`, etc. is the `FlareTeeManager` diamond (`contracts/tee/diamond/FlareTeeManager.sol`); no contract named `TeeExtensionRegistry` exists in code.
Relevant facets:

- `InstructionsFacet` emits `TeeInstructionsSent` (`library/Instructions.sol:154`).
- `ExtensionManagerFacet` handles extension registration.

Rename `Types/Abi/Events/TeeExtensionRegistry.md` and update every inbound link across `Operations/`, `Extensions/`, `TeeManagement/`, `Commands/`, and `Workflows/`.
Sweep other event-doc filenames in `Types/Abi/Events/` for similar contract-name mismatches.

The contract spec lives at `TeeManagement/FlareTeeManager.md`.
To avoid filename collision with that component spec, rename the events doc to `Types/Abi/Events/FlareTeeManagerEvents.md` (or similar disambiguating name) rather than plain `FlareTeeManager.md`.

#### Replace wallet/project/key-manager contract names with `FlareTeeManager`

The legacy contract names `TeeWalletProjectManager`, `TeeWalletManager`, `TeeWalletKeyManager`, and `TeeWalletBackupManager` no longer exist as standalone contracts: every entry point is now a function on the `FlareTeeManager` diamond.
The diamond's facet decomposition is internal organization and should not appear in specs.
Several function signatures are also out of date — e.g. `createProject(extensionId, keyType, signingAlgo)` (no `authorizationAddress`); `setMultisigThreshold` is its own call; `setPausingAddresses` / `resume` are payable and take a `claimBackAddress`.

Inbound users of the old names still to update:

- `Workflows/WalletSetup.md`, `Workflows/KeyAdd.md`, `Workflows/KeyDelete.md`, `Workflows/KeyRestore.md`, `Workflows/VrfProof.md`, `Workflows/XrpPayment.md`, `Workflows/README.md`.
- `Extensions/PMW/Transactions.md`.
- Event-doc filenames in `Types/Abi/Events/`: `TeeWalletProjectManager.md`, `TeeWalletManager.md`, `TeeWalletKeyManager.md`, `TeeWalletBackupManager.md` should follow the same convention as the `TeeExtensionRegistry.md` → `FlareTeeManagerEvents.md` rename (consolidated `FlareTeeManagerEvents.md`).

#### Standardize "instructions sender" terminology

Current docs mix _instruction sender_ (singular), _instructions sender_ (plural), `instructionsSender` (backticks), `_teeExtensionInstructionsSender` (Solidity arg), and _instructions-sender_ (hyphenated).
Canonical forms:

- `instructionsSender` in backticks for the literal Solidity struct field or function argument.
- "instructions sender" in plain prose for the role/concept — plural, no hyphen.
- _italic_ only on first occurrence in a doc, as informal definition.

Known files to fix: `Extensions/Concepts.md`, `Workflows/ExtensionConfiguration.md`, and the inbound link from `Operations/Instructions.md` once `Extensions/Concepts.md` gains a stable anchor.

A _system instructions sender_ (governance-registered, allowed to send `F_` op-types and to call `sendSystemInstructions`) is currently only mentioned in passing in `Extensions/Concepts.md`.
Give it a dedicated subsection with a stable anchor so it can be linked on first mention from `Operations/Instructions.md` and elsewhere.

Once those anchors exist, add links in `Operations/Instructions.md`'s `### Instructions Senders` bullets:

- _system instructions sender_ → its dedicated subsection in `Extensions/Concepts.md` (where governance whitelisting via `registerSystemInstructionsSenders` is documented).
- an _extension's instructions sender_ → the `instructionsSender` field in `Extensions/Concepts.md`'s extension data structure, and the registration call that sets it.

The link additions were attempted on the current `Extensions/Concepts.md` anchors but reverted because those anchors are not yet stable (the file is in the not-yet-cleaned set).

#### Light sweep for `opType` / `opCommand` terminology

Variance is small. Canonical forms:

- `opType` and `opCommand` in backticks for the literal Solidity / Go field name.
- "operation type" and "operation command" in plain prose.
- "op-type" and "op-command" hyphenated only as compound modifiers (e.g. "op-type prefix").

Spot-check `Workflows/XrpPayment.md`, `Extensions/FDC2/AttestationTypes/PMW*.md`, and `Workflows/ExtensionInstructions.md`.

#### Disambiguate the term _operator_

`Terminology/Roles.md#tee-operator` defines a _TEE operator_ as the party deploying TEE machines, but `Components/RelayClient.md:4` introduces a second meaning — the relay-client operator (a data provider or cosigner whose key signs relayed instructions).
Either rename one usage or add a relay-client-operator entry to `Roles.md` and cross-link from `RelayClient.md`.

#### Audit `Types/Abi/` and `Types/Wire/` for internal-only types

`Types/Wire/Instruction.md` is in place (added during the Instructions / RelayClient refactor).
Audit the rest of `Types/Abi/` and `Types/Wire/` for types that are purely internal to one component (e.g. Go-only struct names like `DataFixed`, `Data`) and remove or rename them.

#### Reconcile `$id` / `$ref` casing in JSON-Schema docs

Schemas across `Types/Abi/` and `Types/Wire/` use PascalCase `$id` (e.g. `"Data"`, `"PublicKey"`, `"SignedKeyExistenceProof"`) but lowercase `$ref` (e.g. `"#data"`, `"#publickey"`).
The lowercase form mirrors the markdown anchor that the surrounding `## Heading` produces, so it works as a navigation hint, but a strict JSON-Schema validator would not resolve `#data` to a schema with `$id: "Data"`.
Settle on one of:

- Keep the existing convention (lowercase `$ref` aligned with markdown anchors) and accept that the `$ref` is for human navigation, not validator resolution.
- Switch to PascalCase `$ref` matching `$id`, breaking the markdown-anchor coincidence but yielding strictly valid JSON Schema.

Whichever is chosen, apply uniformly across all `Types/` files.

#### Math-mode pass for variables, numbers, and set notation

Repo-wide sweep to align with the style guide rules that variables, numbers, and indexed identifiers belong in math mode.
Replace Unicode operators (`∈`, `≤`, `≥`, etc.) and plain-text variable/set notation (e.g. `` `v` ∈ {0, 1} ``) with math-mode equivalents (`$v \in \{0, 1\}$`).
Use the existing `$\,\|\,$` convention for byte concatenation.

#### Backtick contract and code function names; leave math functions plain

Repo-wide sweep: ensure contract names, Solidity/Go function names, struct field names, and identifier-like literals are in backticks (e.g. `FlareTeeManager`, `sendInstructions`, `instructionHash`).
Mathematical function names — hash functions like keccak256, primitives like ECDSA — stay plain in prose (and use `\mathrm{...}` in equations).

#### Standardize encoding-convention terminology

The style guide specifies _abi-encoded_ (lowercase, hyphenated).
Apply the analogous form for JSON: _JSON-encoded_ (uppercase JSON, hyphen, lowercase _encoded_).

Current variants across the repo:

- _JSON-encoded_ — preferred (most cleaned docs already use this).
- _JSON encoding_ — appears as a noun phrase in `Operations/Actions.md` lines 20, 47; rewrite as "JSON-encoded" wherever grammatically possible, or accept the noun form only where unavoidable.
- _JSON marshaled_, _marshalled_, _marshaled_ — Go-specific jargon; replace (`Components/TeeProxy.md` lines 164, 170; `Types/Wire/Action.md` line 73).

Add the convention to `STYLE_GUIDE.md` alongside the _abi-encoded_ entry.

#### Replace deprecated "TEE extension" / "TEE machine extension" with "FCE"

The terms "TEE extension" and "TEE machine extension" are deprecated; the canonical term is _FCE_ (Flare Compute Extension).
Known files using the deprecated terminology:

- `Extensions/README.md` and `Extensions/Concepts.md`.
- `Workflows/README.md` (line 65)
- `Workflows/WalletSetup.md` (line 25)
- `Workflows/ExtensionConfiguration.md` (lines 5, 25, 71)

The acronym _FCE_ is already used in `Operations/Actions.md`, `TeeManagement/State.md`, and `Extensions/SystemExtension.md` but is **never expanded anywhere in the spec**.
Introduce the expansion "Flare Compute Extension (FCE)" on first occurrence — most likely in `Extensions/Concepts.md` or `Terminology/Concepts.md` — before propagating the rename.

#### Standardize "emit" vs "produce" terminology

Cleaned docs (`Operations/Actions.md`, `Operations/Instructions.md`, `Components/RelayClient.md`, `Operations/Voting.md`) use _emit_ only for on-chain Solidity events (`TeeInstructionsSent`) and _produce_ for off-chain artifacts (instructions, signatures, actions, receipts).
Apply the same split when cleaning the remaining docs.

#### Standardize the verb for creating an instruction

Relay-client construction uses _build_ (`Operations/Instructions.md`, `Components/RelayClient.md`).
Spot-check the rest of the docs (`Commands/`, `Workflows/`, etc.) for inconsistent usage (_produce_, _assemble_, _construct_, _create_, _make_, ...) and converge on _build_.

#### Generalize Redis references to "key-value store"

Redis is the chosen backend for the proxy's persistent stores, but the spec only requires a key-value store that supports queues; any equivalent backend could replace it.
Sweep `Components/TeeProxy.md`, `Operations/Actions.md`, and any leaf docs that mention Redis by name and rewrite as "key-value store" (or similar) unless the reference is to a specific operational concern (e.g. a deployment-doc context outside the spec).
Section title `### Redis-Backed Stores` in `TeeProxy.md` should become `### Persistent Stores` or similar; keep TTLs and the keying schema because those are observable behavior.

#### Rewrite implementation-specific code snippets as equations

Specs should be implementation-agnostic.
Code snippets in implementation languages (Go, JavaScript, Python, etc.) that describe procedures should be rewritten as equations or language-agnostic pseudocode.
Solidity snippets are an exception — they are themselves the on-chain contract spec and remain as-is.

Examples to look for: Go function references (`accounts.TextHash`, `crypto.Keccak256Hash`, ...), JavaScript or CLI snippets, helper-function references in `flare-system-client`.

#### Refactor on-chain packed wire format details out of `Signing.md`

`Utilities/Signing.md`'s third Encoding-Conventions bullet enumerates the on-chain packed wire formats (`SignatureType1` and `ECDSASignatureWithIndex`) inline, with byte sizes, usage, and embedding sites.
This duplicates content that should live with each format's definition.
Consider:

- Pushing the byte-layout / size details back into `FSP/Encoding.md` (already the source of truth for these layouts) and leaving `Signing.md` with a one-sentence pointer.
- Or, if a dedicated FSP/FCC page emerges for the relay-format signatures (e.g. as part of `FSP/Relay.md`, see Outside FCC/), move the `ECDSASignatureWithIndex` discussion there and have `Signing.md` link to it.

The same refactor likely applies to the inbound FCC mentions of "relay format" in `Extensions/FDC2/Concepts.md` and `Types/Abi/Fdc2.md` — they should defer to the canonical layout doc instead of repeating "encoded in relay format using the signing policy".

`SignatureType0` is deprecated and should not be mentioned anywhere in the repo; this includes the `Signing.md` bullet referenced above. See the matching FSP-cleaning TODO for the full removal scope.

#### Sweep `Concepts.md` files for content fit

Concepts pages now exist at `Extensions/Concepts.md`, `Extensions/PMW/Concepts.md`, `Extensions/FDC2/Concepts.md`, and (outside FCC) `Terminology/Concepts.md`.
They were carved out of the corresponding READMEs by topic, but the splits were mechanical — review each in turn and ask:

- Does any section sit at the wrong level (e.g. an extension-framework concept in `PMW/Concepts.md` that belongs in `Extensions/Concepts.md`, or an FCC-wide concept in `Extensions/Concepts.md` that belongs in `Terminology/Concepts.md`)?
- Does any content overlap or duplicate across files that should be unified and cross-linked?
- Are there sections that read more like reference or how-to material than concept explanation, and should move into a dedicated spec page or a workflow?

Apply the moves during the corresponding file's Phase 1+2 pass.

#### Consider data-flow visualizations for multi-stage pages

Several FCC/ pages describe multi-stage off-chain flows entirely in prose and might be easier to grasp with a sequence or block diagram alongside the text:

- `Operations/Instructions.md` — the sending-instructions pipeline (user → instructions sender → `FlareTeeManager` → event → signers → TEE proxies → voting → action).
- `Operations/Voting.md` — proxy flow, vote-box lifecycle, threshold/end outcomes.
- `Operations/Rewarding.md` — the vote-hash chain extension and the verifier reconstruction procedure.
- `Components/TeeProxy.md` — the three processing queues and the action-result handling pipeline.

When each file is cleaned, evaluate whether a Mermaid diagram (or, where rendering support is uncertain, a labelled ASCII sketch) would improve clarity. Diagrams are optional; only add one if it materially helps over the prose.

## File-specific TODOs

Single-file fixes to apply when the listed FCC/ file is cleaned, or as one-off updates to already-cleaned files.

#### Document rate-limiting cap in `TeeProxy.md`

`TeeProxy.md:101-114` mentions the `429 Too Many Requests` response for `POST /instruction` but describes it as an API response, not as a security cap.
When `TeeProxy.md` is cleaned, surface the per-data-provider open-vote-box cap (`tee-proxy/internal/service/instruction/voting/limiter/limiter.go`) as a deliberate DoS protection: it prevents a single compromised data provider from exhausting the proxy's in-memory vote-box state.

#### Document `F_FDC2 PROVE` per-instruction threshold override

`Extensions/FDC2/Commands/Prove.md` does not currently mention that the request may override the data-provider voting threshold. The proxy reads `thresholdBIPS` from the FDC2 request header (`tee-proxy/pkg/instruction/meta/meta.go:179-194`); a value of $0$ falls back to the signing policy default.
`Operations/Voting.md` refers to this override without naming the field; the command doc should document it (location, units, fallback behaviour).

#### Consider specs or references for `C-chain indexer`, `Redis`, and the relay client's external signer

The C-chain indexer (mentioned in `Architecture.md`'s deployment topology and `Components/RelayClient.md`'s relay flow) and Redis (proxy state store) are operator-run dependencies with no dedicated spec.
Decide whether each warrants a `Components/` page documenting its observable surface (schemas, retention guarantees, endpoint shape) or remains a passing mention.
The external signer used by the relay client is currently only mentioned by name; if there is a stable HTTP contract for it (`POST /sign`, `POST /decrypt`, `GET /id` are observed in code), surface it explicitly — either as a section in `Components/RelayClient.md` or as a sibling `Components/ExternalSigner.md`.

#### Document `PMWMultisigAccountConfigured` `publicKeys` cap

`internal/api/types/pmw_multisig_account_configured.go` caps `publicKeys` at $32$ (XRPL `SignerList` maximum) and rejects empty entries, enforced on both the JSON and ABI-decoded request paths (`ValidatePublicKeys`).
Add this as a request-validation rule when `Extensions/FDC2/AttestationTypes/PMWMultisigAccountConfigured.md` is cleaned.

#### Fix inverted `ALLOW_TEE_DEBUG` description in `TeeAvailabilityCheck.md`

`Extensions/FDC2/AttestationTypes/TeeAvailabilityCheck.md:61` describes the pre-`027fbbf0` semantics, where `ALLOW_TEE_DEBUG=true` accepted only debug TEEs and rejected production ones. As of `go-verifier-api@027fbbf0` (2026-05-21), the flag is permissive: `false` (default) accepts only production TEEs (STABLE attribute checked, downgrades to OBSOLETE otherwise); `true` accepts both production AND debug TEEs (the debug path skips the STABLE check and logs a warning). Rewrite the note when the file is cleaned, and confirm against `internal/attestation/teeavailabilitycheck/verifier/claims.go` `ValidateClaims`.

#### Document async-result behavior in `F_XRP PAY` / `F_XRP REISSUE`

These two PMW commands are registered with `immediateResult=false` (`tee-node/internal/router/routers.go:49-50`), so their `ActionResult.status` flows `2` (in-progress) on `threshold` → `1` (success) on `end`. All other system commands return `status=1` directly on `threshold`. `Operations/Actions.md` keeps the `status=2` description generic; surface this command-specific behavior in `Extensions/PMW/Commands/Pay.md` and `Reissue.md` as part of the `Action result` section when those files are cleaned.

#### Document that extensions only handle `threshold` and `submit` actions

When the extension API spec is cleaned (`Extensions/README.md` or `Extensions/Concepts.md`), surface that a custom extension's `/action` endpoint only ever receives actions with `submissionTag` of `threshold` (instruction actions) or `submit` (direct actions). `end` instruction actions are built locally by the TEE machine without consulting the extension (`tee-node/internal/processors/instructions/default.go:57-72`; see also [`Operations/Actions.md#custom-extension-commands`](Operations/Actions.md#custom-extension-commands)).

#### Document the two extension → TEE machine result-delivery paths

The extension API spec should describe both ways an extension can deliver an [`ActionResult`](Operations/Actions.md#action-results) to the TEE machine:

1. **Synchronous** — always: the result returned as the HTTP response body to the TEE machine's `POST /action` call (`tee-node/internal/extension/extension.go:14-44`).
2. **Asynchronous** — for time-consuming actions: a further update posted later to the TEE machine's own `POST /result` endpoint (`tee-node/internal/extension/server/server.go:228-273`), which signs and forwards it to the proxy. This drives the `status=2` (in-progress) → final-status transition for async commands.

Surface this in `Extensions/README.md` or `Extensions/Concepts.md` when those are cleaned.

#### Document proxy result-storage override semantics in `TeeProxy.md`

`tee-proxy/internal/service/result/storage.go:54-63` enforces the following rule for the [action result store](Components/TeeProxy.md#redis-backed-stores), keyed by `(actionId, submissionTag)`:

- A stored final result (`status` `0` or `1`) is immutable: any subsequent write is rejected.
- A stored transient result (`status` `≥ 2`) can be overwritten only by a final result, or by a transient result with a strictly greater `status`. A write with a smaller-or-equal transient status is rejected.

Effectively, transient statuses are monotonically increasing (e.g. `2` → `3` is allowed; `3` → `2` is not) and final statuses are write-once. Document this in `Components/TeeProxy.md` "Action Result Handling" when that file is cleaned.

## Outside FCC/

These items concern files or behavior outside `FCC/`; recorded here for visibility until a cross-protocol or per-protocol cleaning pass picks them up.

### READMEs

- Rename `Introduction.md` → `README.md` in the other protocol roots (`src/FSP/`, `src/FDC/`, `src/FTSO/`). Each plays the same landing-page role that `FCC/README.md` now plays, and GitLab auto-renders `README.md` when browsing a directory. Inbound references to `Introduction.md` paths from across the repo would need updating in lockstep.
- Add `README.md` landing pages in `src/Terminology/` and `src/Utilities/`. These dirs have 2–3 files each; a one-paragraph intro + one-line table per file gives readers a directory-level entry point.

### Top-level README

The FCC section in the top-level `README.md` is a single heading link to `src/FCC/README.md`.
The FSP, FDC, and FTSO sections still list every file individually; once each protocol has its own landing page (per the READMEs item above), slim those sections to mirror the FCC pattern.
The Terminology and Utilities sections similarly duplicate per-dir READMEs once those exist.

### Repo-level security-model preamble

The honest-majority assumption (malicious actors hold less than the signing policy's threshold weight) is assumed throughout the specs but not stated anywhere.
Per-file `## Security` sections shouldn't restate it (it was removed from `Operations/Voting.md`).
Either add a repo-level intro page that establishes this assumption once, or extend `FCC/README.md` with a short threat-model section that subsequent docs can defer to.

### Broken links outside FCC/

Surfaced by the FCC link-check sweep:

- `FSP/SigningPolicy.md:37` — links to `Contracts/Daemon.md`; that file does not exist anywhere in the tree. Either create the page or rewrite the link (the same line already links to the `FlareSystemsManager.sol` source on GitHub).
- `FDC/Introduction.md:31` — links to `../FSP/DataAvailability.md`; that file does not exist. Either create the Data Availability Layer page in `FSP/` or rewrite the link to point to the canonical location of that concept.

### FSP cleaning

- **Update `FSP/SigningPolicy.md` threshold derivation.** Currently says the signing threshold is "one half of the sum of the normalized weights, rounded up". The actual derivation is `threshold = normalisedWeightsSum * signingPolicyThresholdPPM / PPM_MAX`, rounded up (`FlareSystemsManager.sol:916`), where `signingPolicyThresholdPPM` is a governance-set parameter on `FlareSystemsManager` (`updateSettings`, `onlyGovernance`, line 609). The on-chain `Relay.setSigningPolicy` further constrains the resulting threshold to $[50\%, 66\%]$ of total weight via `MIN_THRESHOLD_BIPS = 5000` and `MAX_THRESHOLD_BIPS = 6600` (`Relay.sol:67-68, 316-323`). `Operations/Voting.md` already links to `SigningPolicy.md#normalized-weights` for $t$; that link's target should explain all three layers.
- **Remove `SignatureType0` from the repo.** Deprecated in `FSP/Encoding.md:32` as of 2025-08-29 (commit `d553c37`). Delete the entry from `FSP/Encoding.md` and every inbound mention — at minimum `FSP/Submission.md:44` (rewrite to refer only to `SignatureType1`) and `Utilities/Signing.md:21` (drop the parenthetical and the link). Grep for `SignatureType0` repo-wide to catch the rest.
- **Document `SignatureType1` byte order.** `FSP/Encoding.md:51` says only "65 bytes — ECDSA signature" without naming the byte order. Verified against `flare-smart-contracts-v2/scripts/libs/protocol/{SignaturePayload,ECDSASignature}.ts`: the embedded 65-byte signature is laid out as $v \,\|\, r \,\|\, s$ with $v \in \{27, 28\}$ (same convention as `ECDSASignatureWithIndex`). Fill this in; once that lands, `Utilities/Signing.md`'s third Encoding-Conventions bullet no longer needs to mark `SignatureType1` as a layout exception.
- **Fix `FSP/Encoding.md:58` `ECDSASignatureWithIndex.v` description.** Currently says "Adjusted by subtracting `27`", implying the stored byte is $v \in \{0, 1\}$. The byte stored is $v \in \{27, 28\}$: `go-flare-common/pkg/encoding/signature.go:69` writes `rsv[64] + 27` into the packed form, and `Relay.sol`'s signature loop feeds that byte directly into the ecrecover precompile (which requires $v \in \{27, 28\}$). The description should be rewritten to "$v$ value of the ECDSA signature ($v \in \{27, 28\}$)" or similar.
- `FSP/Voters.md:53` claims the registration signature is over `keccak256(abi.encode(rewardEpochId, _voter))`, but `VoterRegistry.registerVoter` hashes `abi.encode(block.chainid, rewardEpochId, _voter)`. Spec is missing `block.chainid`.
- `FSP/Rewarding.md:315` says "A reward hash signature is generated using the Signing method" but does not document the actual signed message: `keccak256(abi.encode(_rewardEpochId, keccak256(abi.encode(_noOfWeightBasedClaims)), _rewardsHash))` (`FlareSystemsManager.signRewards`).
- **Create `FSP/Relay.md` documenting the `Relay` contract** (`flare-smart-contracts-v2/contracts/protocol/implementation/Relay.sol`). It is the FSP-side on-chain hub — the analog of FCC's `FlareTeeManager` diamond — but has no dedicated spec page. Surface to document: signing-policy management (`setSigningPolicy`, `toSigningPolicyHash`, `lastInitializedRewardEpochData`; emits `SigningPolicyInitialized`; `MIN_THRESHOLD_BIPS = 5000` / `MAX_THRESHOLD_BIPS = 6600` clamps), protocol-message finalization via `relay()`, Merkle-root storage and reads (`merkleRoots`, `verify`, `isFinalized`), randomness (`getRandomNumber`, `getRandomNumberHistorical`), voting-round time math (`getVotingRoundId`), and `verifyCustomSignature`. Used by FSP (finalization, signing-policy lifecycle, randomness, rewards), FDC (Merkle-root storage), and FCC/FDC2 (data-provider signature verification, `TeeAvailabilityCheck`). Currently referenced in passing from `FSP/{Finalization,SigningPolicy,RandomNumber,Rewarding}.md`, `FDC/Introduction.md`, and `FCC/Extensions/FDC2/README.md`; redirect those passing mentions to the new page once it exists.
