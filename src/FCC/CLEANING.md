# Cleaning Status

## Directory Renames

`src/FlareTEE/` → `src/FCC/` with PascalCase subdirectory and file names.

## Cleaned Files

Files that have completed both [phases](#cleaning-plan):

- [x] `Images/`
- [x] `Operations/Instructions.md`
- [x] `Operations/RelayClient.md`
- [x] `Architecture.md`
- [x] `Introduction.md`

## Not Yet Cleaned

All other files under `src/FCC/` have received only mechanical fixes — type reference updates, naming, event corrections, link fixes.

## Cleaning Plan

For each not-yet-cleaned file, work in two phases.

### Phase 1: Verify content

Verify factual claims against the latest code in:

- `~/flare/tee/*`
- `~/flare/fsp/flare-smart-contracts-v2`
- `~/flare/libs/go-flare-common`
- `~/flare/fdc/verifier-xrp-indexer`

Each working tree is checked out on the read ref listed in [Code-verification refs](#code-verification-refs).
Reads can hit the working tree directly, or `git show origin/<ref>:<path>` for an origin-pinned read.

### Phase 2: Improve style

1. Apply the [style guide](../../STYLE_GUIDE.md).
2. Make content as terse as possible without losing information.
3. Prefer lists to prose.
4. Prefer linking to other files over repeating their content.
5. Link any term, role, concept, type, contract, or command discussed elsewhere in the docs on its first occurrence in the file.
6. Do not document implementation details.
7. Treat each component as a black box: document only what crosses its boundary — HTTP requests/responses, on-chain calls and events, file artifacts handed to other parties, and externally observable timing or ordering guarantees (e.g. best-effort delivery, or that one queue's processing does not block another's).
   Do not document internal structs or formats that never leave the component.
   On-chain state and events count as external — document them.
8. Replace inline ABI and wire schemas with links into the canonical type docs (e.g. `Types/Abi/...` and `Types/Wire/...`); do not duplicate type definitions in prose.
9. Repair any broken inbound anchor links in other files when section anchors change.

### Order

1. `Operations/Instructions.md` — done.
2. `Operations/Voting.md` — pending. _Known corrections:_
   - Cosigner condition: existing text says "more cosigners than the cosigner threshold" must vote; the proxy actually requires `cosignerWeight >= cosignerThreshold` (`tee-proxy/internal/service/instruction/voting/box.go:281`).
     The data-provider condition (strict `>`) is correct.
   - Threshold minimum: existing `threshold` field claims a $30\%$ minimum; the actual lower bound is the signing policy's own threshold, constrained on-chain to $\geq 50\%$ by `MIN_THRESHOLD_BIPS = 5000` (`flare-smart-contracts-v2/contracts/protocol/implementation/Relay.sol:67`).
3. `Operations/Actions.md` — pending. Includes the `Redis` → `REDIS` casing fix on line 93.
4. `Operations/ProjectsAndConfiguration.md` — pending.
5. `Extensions/` — `Overview.md`, `FDC2.md`, `Fdc2VerifierServer.md`, `SystemExtension.md`, then `PMW/`.
6. `TeeManagement/` — `Registration.md`, `StateAndAttestation.md`, `KeyManagement.md`, `TeeProxy.md`.
7. `Commands/`, `Workflows/`, `AttestationTypes/` — leaf docs; pass last so they can defer to the now-canonical `Operations/`, `Extensions/`, and `TeeManagement/` pages.

### Cross-cutting renames and fixes

Apply as a batch once the prose passes are settled, since they touch many inbound links.

#### Rename `TeeExtensionRegistry.md` → `FlareTeeManager.md`

The contract emitting `TeeInstructionsSent`, `TeeExtensionRegistered`, `TeeExtensionContractsSet`, `NewOwnerProposed`, etc. is the `FlareTeeManager` diamond (`contracts/tee/diamond/FlareTeeManager.sol`); no contract named `TeeExtensionRegistry` exists in code.
Relevant facets:

- `InstructionsFacet` emits `TeeInstructionsSent` (`library/Instructions.sol:154`).
- `ExtensionManagerFacet` handles extension registration.

Rename `Types/Abi/Events/TeeExtensionRegistry.md` and update every inbound link across `Operations/`, `Extensions/`, `TeeManagement/`, `Commands/`, and `Workflows/`.
Sweep other event-doc filenames in `Types/Abi/Events/` for similar contract-name mismatches.

#### Standardize "instructions sender" terminology

Current docs mix _instruction sender_ (singular), _instructions sender_ (plural), `instructionsSender` (backticks), `_teeExtensionInstructionsSender` (Solidity arg), and _instructions-sender_ (hyphenated).
Canonical forms:

- `instructionsSender` in backticks for the literal Solidity struct field or function argument.
- "instructions sender" in plain prose for the role/concept — plural, no hyphen.
- _italic_ only on first occurrence in a doc, as informal definition.

Known files to fix: `Extensions/Overview.md`, `Workflows/ExtensionConfiguration.md`, and the inbound link from `Operations/Instructions.md` once `Extensions/Overview.md` gains a stable anchor.

A _system instructions sender_ (governance-registered, allowed to send `F_` op-types and to call `sendSystemInstructions`) is currently only mentioned in passing in `Extensions/Overview.md` (lines 34, 70, 78–79).
Give it a dedicated subsection with a stable anchor so it can be linked on first mention from `Operations/Instructions.md` and elsewhere.

#### Light sweep for `opType` / `opCommand` terminology

Variance is small. Canonical forms:

- `opType` and `opCommand` in backticks for the literal Solidity / Go field name.
- "operation type" and "operation command" in plain prose.
- "op-type" and "op-command" hyphenated only as compound modifiers (e.g. "op-type prefix").

Spot-check `Workflows/XrpPayment.md`, `AttestationTypes/PMW*.md`, and `Workflows/ExtensionInstructions.md`.

#### Disambiguate the term _operator_

`Terminology/Roles.md#tee-operator` defines a _TEE operator_ as the party deploying TEE machines, but `Operations/RelayClient.md:4` introduces a second meaning — the relay-client operator (a data provider or cosigner whose key signs relayed instructions).
Either rename one usage or add a relay-client-operator entry to `Roles.md` and cross-link from `RelayClient.md`.

#### Audit `Types/Abi/` and `Types/Wire/` for internal-only types

`Types/Wire/Instruction.md` is now in place (added during the Instructions / RelayClient refactor).
Still pending: audit the rest of `Types/Abi/` and `Types/Wire/` for types that are purely internal to one component (e.g. Go-only struct names like `DataFixed`, `Data`) and remove or rename them.

#### Reconcile `$id` / `$ref` casing in JSON-Schema docs

Schemas across `Types/Abi/` and `Types/Wire/` use PascalCase `$id` (e.g. `"Data"`, `"PublicKey"`, `"SignedKeyExistenceProof"`) but lowercase `$ref` (e.g. `"#data"`, `"#publickey"`).
The lowercase form mirrors the markdown anchor that the surrounding `## Heading` produces, so it works as a navigation hint, but a strict JSON-Schema validator would not resolve `#data` to a schema with `$id: "Data"`.
Settle on one of:

- Keep the existing convention (lowercase `$ref` aligned with markdown anchors) and accept that the `$ref` is for human navigation, not validator resolution.
- Switch to PascalCase `$ref` matching `$id`, breaking the markdown-anchor coincidence but yielding strictly valid JSON Schema.

Whichever is chosen, apply uniformly across all `Types/` files.

### Code-verification refs

| Repo | Read ref |
|------|----------|
| `tee/tee-node` | `origin/tee-diamond-cut` |
| `tee/tee-proxy` | `origin/tee-diamond-cut` |
| `tee/tee-relay-client` | `origin/tee-diamond-cut` |
| `tee/go-verifier-api` | `origin/tee-diamond-cut` |
| `fsp/flare-smart-contracts-v2` | `origin/tee-diamond-cut` |
| `libs/go-flare-common` | `origin/tee-diamond-cut` |
| `fdc/verifier-xrp-indexer` | `origin/main` |
