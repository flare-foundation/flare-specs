# Cleaning Status

## Cleaned Files

Phase 2 [cleaning](#cleaning-plan) status:

- [x] `Images/`
- [x] `Concepts/{Actions,Instructions,Voting,Rewarding,README,TrustModel}.md`
- [x] `Reference/Components/RelayClient.md`
- [x] `Architecture.md`
- [x] `README.md`
- [x] `../Utilities/Signing.md`
- [x] `../Terminology/`

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

Commit hashes captured on 2026-05-27 (refresh by re-fetching each remote and re-running the head log).
Refresh this table at the start of any new Phase 1 verification round if the snapshot is more than a few weeks stale; the verifications below reference specific commit hashes and will need re-checking against the new HEAD if behaviour has changed:

| Repo | Read ref | HEAD commit | Date |
|------|----------|-------------|------|
| `tee/tee-node` | `origin/main` | `4ba38512` | 2026-05-14 |
| `tee/tee-proxy` | `origin/main` | `3938b5d6` | 2026-05-27 |
| `tee/tee-relay-client` | `origin/tee-diamond-cut` | `3bfbb5d1` | 2026-05-25 |
| `tee/go-verifier-api` | `origin/main` | `d7efb89a` | 2026-05-22 |
| `fsp/flare-smart-contracts-v2` | `origin/tee-diamond-cut` | `7c943318` | 2026-05-27 |
| `libs/go-flare-common` | `origin/tee-diamond-cut` | `876c09e6` | 2026-04-24 |
| `fdc/verifier-xrp-indexer` | `origin/main` | `5506c431` | 2026-05-25 |

`tee-node` is the base TEE machine implementation; deployments may extend it by composing user-provided FCE repos on top.

### Phase 2: Improve style

**The two highest-leverage rules — apply aggressively, every pass:**

- **Terseness.** Cut every word that does not carry information. If the page didn't get shorter, the pass wasn't done.
- **Lists over prose.** If three or more items share a structure (definitions, fields, conditions, steps), they belong in a list. Reach for prose only when sentences genuinely flow.

The full checklist:

1. Apply the [style guide](../../STYLE_GUIDE.md).
2. Make content as terse as possible without losing information. _(See above — the primary goal of every pass.)_
3. Prefer lists to prose. _(See above — restructure aggressively.)_
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

## Remaining

Per-page leaf cleaning of `Reference/Components/{Machine,Proxy}.md`, `Reference/Operations/F_*.md`, `../PMW/Concepts.md`, `../PMW/Transactions.md`, `../FDC2/Concepts.md`, `../FDC2/Verifier.md`, `FCE/Concepts.md`, `FCE/System.md`.

## Cross-cutting renames and fixes

Apply as a batch once the prose passes are settled, since they touch many inbound links.

#### Standardize TEE substrate vocabulary (`enclave` / `hardware` / `Confidential VM` / `TEE machine`)

The repo uses four near-synonyms for "the thing running in a TEE" with an implicit, mostly-consistent split. Make it explicit and sweep the whole repo (`src/`) so each word carries one meaning:

- _enclave_ — the attested instance that boots, generates the identity key, runs the code, and registers. Use it for the **actor** (the thing that boots / generates keys / registers / is swapped on replication).
- _hardware_ — the **physical substrate** only ("the key never leaves the hardware", "hardware isolation", "hardware-attested"). Do not use it as the actor that registers or runs (hardware doesn't register; an enclave does).
- _Confidential VM_ — the concrete cloud deployment form of an enclave. Reserve for registration/deployment/platform contexts (`Workflows/MachineRegistration.md`, `FCE/Reference/Api.md`, `Components/README.md`).
- _TEE machine_ — the persistent logical entity / on-chain identity. Never use it for the swappable instance; that is what the enclave/Confidential-VM terms are for.

Known loose usage to reconcile: `Workflows/MachineReplication.md` frames replication as "replacing the **hardware** behind a TEE machine" with "hardware fields", "hardware fingerprint", and "hardware-refresh chain" — these mean the enclave/instance, not raw silicon (a new enclave may land on the same physical host). Decide whether to retitle these to "enclave" or keep "hardware fingerprint" as an accepted idiom, and apply the choice uniformly. Record the chosen split in `STYLE_GUIDE.md`.

#### Standardize "instructions sender" terminology

Current docs mix _instruction sender_ (singular), _instructions sender_ (plural), `instructionsSender` (backticks), `_teeExtensionInstructionsSender` (Solidity arg), and _instructions-sender_ (hyphenated).
Canonical forms:

- `instructionsSender` in backticks for the literal Solidity struct field or function argument.
- "instructions sender" in plain prose for the role/concept — plural, no hyphen.
- _italic_ only on first occurrence in a doc, as informal definition.

Known files to fix: `FCE/Concepts.md`, `FCE/Workflows/Configuration.md`, and the inbound link from `Operations/Instructions.md` once `FCE/Concepts.md` gains a stable anchor.

A _system instructions sender_ (governance-registered, allowed to send `F_` op-types and to call `sendSystemInstructions`) is currently only mentioned in passing in `FCE/Concepts.md`.
Give it a dedicated subsection with a stable anchor so it can be linked on first mention from `Operations/Instructions.md` and elsewhere.

Once those anchors exist, add links in `Operations/Instructions.md`'s `### Instructions Senders` bullets:

- _system instructions sender_ → its dedicated subsection in `FCE/Concepts.md` (where governance whitelisting via `registerSystemInstructionsSenders` is documented).
- an _extension's instructions sender_ → the `instructionsSender` field in `FCE/Concepts.md`'s extension data structure, and the registration call that sets it.

#### Light sweep for `opType` / `opCommand` terminology

Variance is small. Canonical forms:

- `opType` and `opCommand` in backticks for the literal Solidity / Go field name.
- "operation type" and "operation command" in plain prose.
- "op-type" and "op-command" hyphenated only as compound modifiers (e.g. "op-type prefix").

Spot-check `../PMW/Workflows/XrpPayment.md`, `../FDC2/Reference/AttestationTypes/PMW*.md`, and `FCE/Workflows/Instructions.md`.

#### Roles: single canonical glossary in `Terminology/Roles.md`

**Policy:** `Terminology/Roles.md` is the one cross-protocol "who's who". FCC-specific roles are **not** moved into `FCC/Concepts/`. Role _identity and responsibilities_ live in `Roles.md`; FCC pages link to it rather than re-defining a role, and document only the FCC _mechanism_ (e.g. the allowlist gating). Rationale: several roles are genuinely cross-protocol (data provider, delegator, governance, user) and even the "FCC" ones leak across layers, so a clean per-protocol split doesn't exist; splitting would also fragment the glossary and break many `Roles.md#…` inbound links.

Remaining sweep (apply on each file's pass):

- `Reference/Contracts/FlareTeeManager.md:84` re-italicizes _machine owner_ etc. when listing which contract functions each allowlist gates. That function-gating detail is legitimate reference content, but it should link the role to `Roles.md` instead of reading as a fresh definition.
- `Reference/Components/RelayClient.md:11` uses _Data provider_ as a config term; confirm it links `Roles.md#data-provider` on its cleaning pass.
- Sweep the remaining FCC concept/workflow pages (`Wallets.md`, `Instructions.md` cosigner/signer prose, `FCE/Concepts.md`) for any role re-definition and converge on links.
- Naming: `Concepts/Machines.md#owner-allowlist` is the canonical home for the _machine owner_ allowlist term; `Roles.md#tee-operator` is the actor. Settle the machine-owner ↔ TEE-operator relationship as part of the operator disambiguation below.

#### Disambiguate the term _operator_

`Terminology/Roles.md#tee-operator` defines a _TEE operator_ as the party deploying TEE machines, but `Components/RelayClient.md:4` introduces a second meaning — the relay-client operator (a data provider or cosigner whose key signs relayed instructions).
Either rename one usage or add a relay-client-operator entry to `Roles.md` and cross-link from `RelayClient.md`.

#### Audit `Reference/Types/Abi/` and `Reference/Types/Wire/` for internal-only types

Audit `Reference/Types/Abi/` and `Reference/Types/Wire/` for types that are purely internal to one component (e.g. Go-only struct names like `DataFixed`, `Data`) and remove or rename them.

#### Reconcile `$id` / `$ref` casing in JSON-Schema docs

Schemas across `Reference/Types/Abi/` and `Reference/Types/Wire/` use PascalCase `$id` (e.g. `"Data"`, `"PublicKey"`, `"SignedKeyExistenceProof"`) but lowercase `$ref` (e.g. `"#data"`, `"#publickey"`).
The lowercase form mirrors the markdown anchor that the surrounding `## Heading` produces, so it works as a navigation hint, but a strict JSON-Schema validator would not resolve `#data` to a schema with `$id: "Data"`.
Settle on one of:

- Keep the existing convention (lowercase `$ref` aligned with markdown anchors) and accept that the `$ref` is for human navigation, not validator resolution.
- Switch to PascalCase `$ref` matching `$id`, breaking the markdown-anchor coincidence but yielding strictly valid JSON Schema.

Whichever is chosen, apply uniformly across all `Types/` files.

#### Math-mode pass for variables, numbers, and set notation

Repo-wide sweep to align with the style guide rules that variables, numbers, and indexed identifiers belong in math mode.
Replace Unicode operators (`∈`, `≤`, `≥`, etc.) and plain-text variable/set notation (e.g. `` `v` ∈ {0, 1} ``) with math-mode equivalents (`$v \in \{0, 1\}$`).
Use the existing `$\,\|\,$` convention for byte concatenation.

#### Standardize key-pair notation: `pub` / `priv` over `pk` / `sk`

Use $\mathrm{TEE}_\mathrm{pub}$ / $\mathrm{TEE}_\mathrm{priv}$ for the TEE identity key pair (the alternative `pk` / `sk` is Go convention and not self-explanatory to spec readers). Apply the same convention everywhere a key pair is introduced:

- `Concepts/Keys.md:104, 106` — holder public keys ($\mathrm{pk}_i$) and the Shamir backup encryption.
- `Reference/Operations/F_WALLET.md:112-116` and `Workflows/VrfProof.md:46, 58` — VRF math (`sk`, `pk`).
- `Reference/Contracts/VrfVerifier.md:25, 28, 68-71, 87` — VRF verification equations.

In VRF math the variables come from RFC 9381 and academic crypto papers where `pk`/`sk` is conventional — keeping them there may be the right call. Decide which contexts truly benefit from the rename (TEE/wallet identity vs. equation-internal VRF variables) and document the chosen split in `STYLE_GUIDE.md`.

#### Backtick contract and code function names; leave math functions plain

Repo-wide sweep: ensure contract names, Solidity/Go function names, struct field names, and identifier-like literals are in backticks (e.g. `FlareTeeManager`, `sendInstructions`, `instructionHash`).
Mathematical function names — hash functions like keccak256, primitives like ECDSA — stay plain in prose (and use `\mathrm{...}` in equations).

#### Standardize encoding-convention terminology

The style guide specifies _abi-encoded_ (lowercase, hyphenated).
Apply the analogous form for JSON: _JSON-encoded_ (uppercase JSON, hyphen, lowercase _encoded_).

Current variants across the repo:

- _JSON-encoded_ — preferred.
- _JSON encoding_ — appears as a noun phrase in `Operations/Actions.md` lines 20, 47; rewrite as "JSON-encoded" wherever grammatically possible, or accept the noun form only where unavoidable.
- _JSON marshaled_, _marshalled_, _marshaled_ — Go-specific jargon; replace (`Reference/Components/Proxy.md` lines 164, 170; `Reference/Types/Wire/Action.md` line 73).

Add the convention to `STYLE_GUIDE.md` alongside the _abi-encoded_ entry.

#### Replace deprecated "TEE extension" / "TEE machine extension" with "FCE"

The terms "TEE extension" and "TEE machine extension" are deprecated; the canonical term is _FCE_ (Flare Compute Extension).
Known files using the deprecated terminology:

- `FCE/README.md` and `FCE/Concepts.md`.
- `Workflows/README.md` (line 65)
- `Workflows/WalletSetup.md` (line 25)
- `FCE/Workflows/Configuration.md` (lines 5, 25, 71)

The acronym _FCE_ is already used in `Operations/Actions.md`, `TeeManagement/State.md`, and `FCE/System.md` but is **never expanded anywhere in the spec**.
Introduce the expansion "Flare Compute Extension (FCE)" on first occurrence — most likely in `FCE/Concepts.md` or `Terminology/Concepts.md` — before propagating the rename.

#### Standardize "emit" vs "produce" terminology

Use _emit_ only for on-chain Solidity events (`TeeInstructionsSent`); _produce_ for off-chain artifacts (instructions, signatures, actions, receipts).
Apply this split when cleaning the remaining docs.

#### Standardize the verb for creating an instruction

Use _build_ for relay-client construction of instructions.
Spot-check the rest of the docs (`Workflows/`, etc.) for inconsistent usage (_produce_, _assemble_, _construct_, _create_, _make_, ...) and converge on _build_.

#### Generalize Redis references to "key-value store"

Redis is the chosen backend for the proxy's persistent stores, but the spec only requires a key-value store that supports queues; any equivalent backend could replace it.
Sweep `Reference/Components/Proxy.md`, `Operations/Actions.md`, and any leaf docs that mention Redis by name and rewrite as "key-value store" (or similar) unless the reference is to a specific operational concern (e.g. a deployment-doc context outside the spec).
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

The same refactor likely applies to the inbound FCC mentions of "relay format" in `../FDC2/Concepts.md` and `../FDC2/Reference/Types/Abi/Fdc2.md` — they should defer to the canonical layout doc instead of repeating "encoded in relay format using the signing policy".

`SignatureType0` is deprecated and should not be mentioned anywhere in the repo; this includes the `Signing.md` bullet referenced above. See the matching FSP-cleaning TODO for the full removal scope.

#### Extract reference content from `FCE/Concepts.md` into `Reference/Contracts/FlareTeeManager.md`

Pull the management-call list (the `register`, `setExtensionContracts`, `addTeeVersion`, `disableCodeHashPlatform`, `addSupportedKeyTypes`, `removeSupportedKeyTypes`, `proposeNewOwner`, `confirmOwnership`, `sendInstructions`, `sendSystemInstructions`, `addSystemSupportedPlatforms`, `addSystemSupportedKeyTypesAndSigningAlgos`, `registerSystemInstructionsSenders`, `unregisterSystemInstructionsSenders` entries) into a new "Extension Management" section under `Reference/Contracts/FlareTeeManager.md`.
Leave `FCE/Concepts.md` with the concept-level prose (extension data model, system-vs-custom distinction, lifecycle narrative, instructions-senders concept) and cross-links to the new Reference section.

#### Sweep `Concepts.md` files for content fit

Concepts pages exist at `FCE/Concepts.md`, `../PMW/Concepts.md`, `../FDC2/Concepts.md`, and (outside FCC) `Terminology/Concepts.md`.
Review each in turn:

- Does any section sit at the wrong level (e.g. an extension-framework concept in `../PMW/Concepts.md` that belongs in `FCE/Concepts.md`, or an FCC-wide concept in `FCE/Concepts.md` that belongs in `Terminology/Concepts.md`)?
- Does any content overlap or duplicate across files that should be unified and cross-linked?
- Are there sections that read more like reference or how-to material than concept explanation, and should move into a dedicated spec page or a workflow?

Apply the moves during the corresponding file's Phase 1+2 pass.

#### Consider data-flow visualizations for multi-stage pages

Several FCC/ pages describe multi-stage off-chain flows entirely in prose and might be easier to grasp with a sequence or block diagram alongside the text:

- `Operations/Instructions.md` — the sending-instructions pipeline (user → instructions sender → `FlareTeeManager` → event → signers → TEE proxies → voting → action).
- `Operations/Voting.md` — proxy flow, vote-box lifecycle, threshold/end outcomes.
- `Operations/Rewarding.md` — the vote-hash chain extension and the verifier reconstruction procedure.
- `Reference/Components/Proxy.md` — the three processing queues and the action-result handling pipeline.

When each file is cleaned, evaluate whether a Mermaid diagram (or, where rendering support is uncertain, a labelled ASCII sketch) would improve clarity. Diagrams are optional; only add one if it materially helps over the prose.

## File-specific TODOs

Single-file fixes to apply when the listed FCC/ file is cleaned, or as one-off updates to already-cleaned files.

#### Consider specs or references for `C-chain indexer`, `Redis`, and the relay client's external signer

The C-chain indexer (mentioned in `Architecture.md`'s deployment topology and `Reference/Components/RelayClient.md`'s relay flow) and Redis (proxy state store) are operator-run dependencies with no dedicated spec.
Decide whether each warrants a `Components/` page documenting its observable surface (schemas, retention guarantees, endpoint shape) or remains a passing mention.
The external signer used by the relay client is currently only mentioned by name; if there is a stable HTTP contract for it (`POST /sign`, `POST /decrypt`, `GET /id` are observed in code), surface it explicitly — either as a section in `Reference/Components/RelayClient.md` or as a sibling `Components/ExternalSigner.md`.

#### Document async-result behavior in `F_XRP PAY` / `F_XRP REISSUE`

These two PMW commands are registered with `immediateResult=false` (`tee-node/internal/router/routers.go:49-50`), so their `ActionResult.status` flows `2` (in-progress) on `threshold` → `1` (success) on `end`. All other system commands return `status=1` directly on `threshold`. `Operations/Actions.md` keeps the `status=2` description generic; surface this command-specific behavior in `../PMW/Reference/Operations/Pay.md` and `Reissue.md` as part of the `Action result` section when those files are cleaned.

#### Document MachinePathManager + direct backup/restore

`flare-smart-contracts-v2` `23a4d812` introduced `MachinePathManagerFacet` and a parallel direct path on `WalletBackupManagerFacet` (`directBackup` / `directRestore`, op commands `KEY_DIRECT_BACKUP` / `KEY_DIRECT_RESTORE`). Path lists are governance-signed `(sourceTeeIds[], destinationTeeIds[])` records gated by a strictly-increasing per-extension nonce, with multi-governance approval semantics analogous to `UpgradeManagerFacet`. The direct path is _not_ a replacement for the existing admin-cosigner `backupRestore` flow — both coexist.

`cd32db53` (2026-05-25) refined the payload: `destinationNonce` was dropped from `KeyDirectBackup`, so the backup blob is stateless w.r.t. the destination's per-key nonce and `directRestore` can be retried (each retry bumps the nonce) without re-issuing `directBackup`. Replay protection is preserved by the restore-side defenses: the `destinationNonce` attestation binding on `KeyDirectRestore`, `KeyAlreadyAvailable`/`InvalidPublicKey` checks, machine-path-list gating, and blob encryption to the destination TEE's public key.

Spec work to do:

- Surface `directBackup` / `directRestore` and the path-list authorization in `Reference/Contracts/FlareTeeManager.md`.
- Add `KEY_DIRECT_BACKUP` and `KEY_DIRECT_RESTORE` to `Reference/Operations/F_WALLET.md` alongside the existing key commands; reflect the post-`cd32db53` payload (no `destinationNonce` on backup; nonce binding only on restore).
- Decide whether [`Workflows/TeeBackup.md`](Workflows/TeeBackup.md) and [`Workflows/KeyRestore.md`](Workflows/KeyRestore.md) document the direct alternative inline, gain new sibling workflows (`KeyDirectBackup.md` / `KeyDirectRestore.md`), or both. Mirror in the [TLA+ formal models](#tla-formal-models).
- `WalletKeyManager.getKeyNonce(teeId, walletId, keyId)` and `UpgradeManager.getTeeUpgradeMessageHash(upgradeId)` views are new — surface alongside the existing key/upgrade reference material.

#### Document chain-id binding in TEE and FDC2 signed payloads

`flare-smart-contracts-v2` `0bc80b0b` (2026-05-25) binds `block.chainid` into every TEE-local and FDC2-attestation signed payload on the diamond, preventing cross-chain replay. Two shapes:

- TEE-local signatures (machine register, wallet key-existence confirm) and the existing TeeUpgrade / ExtensionPausing / MachinePathManager flows now hash as `keccak256(abi.encode(bytes32("<domain-tag>"), block.chainid, <payload>))` — per-flow `bytes32` domain tag plus `chainId` prepended.
- FDC2 attestation proofs (TEE availability check, PMW multisig configured, PMW payment status) gain `chainId` as a first-class leading field on `Fdc2ResponseHeader`; on-chain verifiers `require(header.chainId == block.chainid)` before recovering signers.
- `TeeStructs.Instruction` gains a leading `chainId` field so any future code recovering signers from an `Instruction` hash gets chain binding for free.

**Upstream state**: contracts are updated but `tee-node@4ba38512`, `tee-proxy@31bfb8e0`, and `tee-relay-client@3bfbb5d8` predate the change and have **not** been updated in lockstep. Do not write specs against the new layout until the off-chain side lands — track for re-verification.

Spec surfaces to touch when the off-chain catches up:

- `Reference/Types/Abi/Instruction.md` and `Reference/Types/Wire/Instruction.md` — add leading `chainId` to `Instruction`.
- `../FDC2/Reference/Types/Abi/Fdc2.md` (and `Wire/Fdc2.md`) — add leading `chainId` to `Fdc2ResponseHeader`; note the verifier requirement.
- `Reference/Operations/F_REG.md`, `Reference/Operations/F_WALLET.md` — describe the `(domain-tag, chainId, payload)` hashing shape on the relevant signatures (this is reference-level; `Concepts/Machines.md § Attestation` stays at concept level).
- `Workflows/MachineReplication.md` (TeeUpgrade flow), the TeeUpgrade event family in `FlareTeeManagerEvents.md`, and the upgrade-related parts of `Reference/Contracts/FlareTeeManager.md` — surface the new hash preimage.
- `Utilities/Signing.md` — consider a paragraph on the `(domain-tag, chainId, body)` convention now that it is shared across flows.

#### Document wallet project pauser/unpauser delegation

`flare-smart-contracts-v2` `4521efaa` (2026-05-25) added `WalletProjectPauseFacet`. Per-project _pauser_ and _unpauser_ address lists let the project owner delegate operational pause authority without handing over ownership. List members can `pauseWallets` (PRODUCTION → PAUSED) and `unpauseWallets` (PAUSED → PRODUCTION) batched across wallets, alongside the owner. Related changes:

- `enableWallet` narrowed to `INITIALIZED → PRODUCTION` only. The old `PAUSED → PRODUCTION` path is gone — unpause now goes through `unpauseWallets` exclusively, so unpause delegation cannot accidentally activate a wallet that never reached PRODUCTION.
- Singular `pauseWallet` removed in favour of batch `pauseWallets`.
- Set-membership errors (`InvalidAddress`, `AddressAlreadyInSet`, `AddressNotInSet`, `NotOwnerOrPauser`, `NotOwnerOrUnpauser`, `NoAddresses`) lifted into `ITeeCommonErrors`; `OwnerAllowlist` and `IWalletKeyManager` rewired to share them.

Spec work:

- Update `Concepts/Wallets.md` lifecycle to reflect the same model.
- Touch `Workflows/WalletSetup.md` (and any wallet-pause workflow that emerges).
- Optionally fold the WalletProjectPauseFacet management calls into a dedicated subsection of `FlareTeeManager.md` (the lifecycle line currently links them inline).

#### Document per-extension emergency pause overlay

`flare-smart-contracts-v2` `d7906df7` (on `origin/tee-diamond-cut`, captured at HEAD `7c943318`, 2026-05-27) added `MachineEmergencyPauseFacet` + `MachineEmergencyPause` library (`IMachineEmergencyPause` public; governance-only grace setter on `IIMachineEmergencyPause`). A per-extension boolean overlay, **distinct from** the per-project wallet pause in [Document wallet project pauser/unpauser delegation](#document-wallet-project-pauserunpauser-delegation): it gates _instruction dispatch_, not wallet state, and uses its own per-extension pauser/unpauser lists.

Behavior:

- While set, `Instructions.sendInstructions` rejects every dispatch (regular **and** system op-types) to machines in that extension with `EmergencyPauseActive(extensionId)`. Machine statuses, active sets, and the read getters (`getActiveTeeMachines`, `getRandomTeeIds`, …) are **not** mutated — off-chain "is this usable now" checks must also call `isExtensionEmergencyPaused`. Clearing the flag instantly restores dispatch.
- After unpause, a governance-tunable grace window (bounds $30\,\mathrm{min}$–$24\,\mathrm{h}$, default $\sim 2\,\mathrm{h}$ / `7200 s`) blocks **only** the third-party expired-availability branch of `MachineManagerFacet.pause(teeId)`, so owners can refresh attestations before strangers suspend still-`PRODUCTION` machines. The window combines the machine's own extension and the system extension (id 0), since availability refresh needs `requestTeeAttestation` (own extension) **and** FDC2 attestation routed to extension-0 TEEs.

Spec work remaining: optionally a fuller treatment in `Concepts/Instructions.md`'s dispatch path.

**Upstream state**: contracts only. `tee-node@4ba38512`/`tee-proxy@3938b5d6` predate it; the overlay is an on-chain dispatch gate so off-chain may need only to surface `isExtensionEmergencyPaused`. Confirm before speccing the off-chain side.

#### Cross-check FCC pages against the contract-repo spec-alignment audit

`flare-smart-contracts-v2` `7c943318` (2026-05-27, `docs(specs)`) is an audit that corrected contract↔doc drift in **that repo's** `docs/specs/`. Its findings name the same factual areas to re-verify in our specs on each page's next pass: governance / upgrade-manager flow (`create` / `addPaths` / `finalize` / `sign`; note there is **no** `transferGovernance` / `claimGovernance`), `WalletManager` lifecycle/state machine, `Replication`, `Verification` (attestation), `Instructions`, `OperationFees`, `Extensions`, and entity counts. Diff against `git show 7c943318 -- docs/specs/FCC/<page>.md` when cleaning the matching page. The contract refactor `4d3cbeff` in the same range is behavior-preserving — `Attestation` struct and the `TEE_ATTESTATION` hash preimage are unchanged — so no attestation-spec change is needed.

#### Fold tee-proxy observable-surface changes into the `Proxy.md` pass

`tee-proxy` advanced `31bfb8e0 → 3938b5d6` (2026-05-27, large batch). Most is internal (storage/redis/firestore lifecycle, voting-lock discipline, config validation), but a few items touch the observable surface `Reference/Components/Proxy.md` documents — reconcile them when that page gets its Phase 1+2 pass (table HEAD now points there):

- Expanded HTTP status mapping (`409` / `410` / `413`, one-wrap rule) alongside the existing `429`; check the External APIs status-code list.
- Bootstrap + periodic attestation self-verification with a sticky liveness signal (Confidential Space attestation + TEE-info challenge round-trip at startup); a periodic trigger worth a $\sim$cadence cue.
- `/direct` accepted without an API key (warn-only) and a queue-depth-threshold warning.
- Storage TTLs consolidated under a `[storage]` config block — keep the documented TTLs/keying (observable), drop config-shape detail.
- `publicKey` JSON tag typo fixed in code (`publicKye → publicKey`); our wire-type docs already use `publicKey`, so no change — just confirm on the pass.

#### Add `domainID` check to XRP `transactionStatus` validation note

`verifier-xrp-indexer@5506c431` (2026-05-25) added a `domainID` check to the XRP `transactionStatus` validation path (`internal/xrp/transaction.go`). When PMW Payment / XRP-related attestation-type pages are cleaned, confirm whether the spec already mentions the domain-tag check or whether it needs to be added; current `FDC/AttestationTypes/Payment.md` only mentions `transactionStatus` in passing (line 115) and may not need the level of detail.

## Forward-looking

These items are not yet on the critical path but anchor the longer-term spec direction; record them so they are not lost.

### TLA+ formal models

The state-machine shape that `Workflows/Conventions.md` prescribes is intended to translate near-mechanically into TLA+ (the chosen formal language; TEE-spec readers natively read TLA+ math notation, so the ergonomic case for Quint does not apply here). Initial TLA+ files for workflows and concept-level state machines live under `Formal/` on the `formal` branch. Open items:

- **Canonical home:** per-protocol `<root>/Formal/` dirs. FCC's models plus the shared harness (`Common`, `Voting`, the `verify-*.sh` scripts, `Formal/README.md`) live at `src/FCC/Formal/`; protocols that extend FCC keep their models with their own dirs (`src/FDC2/Formal/Workflows/`, `src/PMW/Formal/Workflows/`) and reuse the shared modules, mirroring the markdown dependency direction. The verify scripts flatten every `.tla`/`.qnt` under `src/` so cross-protocol `EXTENDS Common` / `import Common.*` resolves by module name.
- Add a CI job that runs SANY (syntax) on every `.tla`; TLC/Apalache model checking as a slower optional job.
- Cross-reference each `.tla` file from the matching markdown page once the conventions stabilize.

### RewardDistribution workflow (FSP scope)

The reward-distribution flow — how participation in TEE voting and signing is attributed and reconstructed off-chain into per-data-provider rewards — was considered for `FCC/Workflows/` but rejected: the mechanism lives in the FSP, and the FCC side already documents the per-vote receipt structure in [`Concepts/Rewarding.md`](Concepts/Rewarding.md). Cover the full reward-distribution workflow in `src/FSP/` rather than `FCC/` when the FSP cleaning pass picks it up.

### Drive-by Phase 1 verification of `Reference/Operations/F_*.md`

The `F_*` operation pages were assembled and verified in the consolidation pass but no single sweep has cross-checked every assertion against `tee-node` HEAD. Do one targeted Phase 1 pass per file (`F_GET.md`, `F_POLICY.md`, `F_REG.md`, `F_WALLET.md`) and reconcile against `tee-node/internal/processors/`. Pair with a refresh of the commit-hash table.

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
- **Create `FSP/Relay.md` documenting the `Relay` contract** (`flare-smart-contracts-v2/contracts/protocol/implementation/Relay.sol`). It is the FSP-side on-chain hub — the analog of FCC's `FlareTeeManager` diamond — but has no dedicated spec page. Surface to document: signing-policy management (`setSigningPolicy`, `toSigningPolicyHash`, `lastInitializedRewardEpochData`; emits `SigningPolicyInitialized`; `MIN_THRESHOLD_BIPS = 5000` / `MAX_THRESHOLD_BIPS = 6600` clamps), protocol-message finalization via `relay()`, Merkle-root storage and reads (`merkleRoots`, `verify`, `isFinalized`), randomness (`getRandomNumber`, `getRandomNumberHistorical`), voting-round time math (`getVotingRoundId`), and `verifyCustomSignature`. Used by FSP (finalization, signing-policy lifecycle, randomness, rewards), FDC (Merkle-root storage), and FCC/FDC2 (data-provider signature verification, `TeeAvailabilityCheck`). Currently referenced in passing from `FSP/{Finalization,SigningPolicy,RandomNumber,Rewarding}.md`, `FDC/Introduction.md`, and `../FDC2/README.md`; redirect those passing mentions to the new page once it exists.
