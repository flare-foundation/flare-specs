# Flare Specs Consistency Guide

Suggestions for formatting and wording in the Flare Specs documentation.

## Labelling Contract and Function Calls

Objects use backticks (e.g. `smartContract`).
A Solidity block on a new line is introduced with a colon, e.g.:

```solidity
…
```

## Formatting of Specific Words and Grammar

- Flare network has a lower case n; Flare Foundation an upper case F.
- Off-chain and on-chain contain dashes (not offchain).
- ID is always uppercase.
- Bit-vote and bit-vector contain dashes.
- Bit and byte lengths use dashes (e.g. 32-bit, 32-byte).
- FTSO feeds (anchor, block-latency) are typically uncapitalized.
- Phase names within protocols are typically uncapitalized (descriptive labels).
- abi-encoded is all lower case and contains a dash.
- JSON-encoded uses uppercase JSON, a hyphen, and lowercase encoded.
- Data provider is two words without a hyphen, even as a compound modifier (e.g. "data provider weight", not "data-provider weight").
- uint is formatted as $\mathrm{uint}$.
- Oxford commas are used (e.g. "a, b, and c", not "a, b and c").
- Protocols take "the" (e.g. "the FSP", not "FSP").
- Avoid filler modifiers ("underlying", "relevant", "appropriate", "respective", "carrying X"); use a specific noun or drop the modifier when context establishes the referent (e.g. "destination TEE proxy", not "relevant TEE proxy").
- Docker is always capitalized.
- keccak256 is lowercase, no hyphen, no backticks in prose; $\mathrm{keccak256}$ in equations.
- secp256k1 is lowercase, no backticks.
- TEE_ID is formatted as $\mathrm{TEE}_{\mathrm{ID}}$.
- `instructionsSender`: "instructions sender" in prose (plural, no hyphen).
- `opType` / `opCommand`: "operation type" / "operation command" in prose; "op-type" / "op-command" as compound modifiers.

## Indexing

Indices use $i$, $j$ (and $k$ only when three are needed in one file). Some cross-document inconsistency is allowed (e.g. $i$ may refer to providers in one doc and rounds in another):

- Each file is internally consistent.
- Providers are indexed by $i$.
- Voting rounds and epochs by $j$ (or $i$ if no provider index is needed or rounds are the only enumerated object).
- When both reward and voting epochs appear in the same doc, use distinct letters (e.g. $j$ for voting epochs, $r$ for reward epochs) — clarity over consistency.

## Bullet Points

- Sentence bullets end with a full stop.
- Non-sentence bullets omit it, except the last.
- Named bullets: bold lead-in followed by a separator (colon, em-dash, or period) — e.g. `**Name**: Description.`, `**Name** — description.`, or `**Name.** Description.`.
- Exception: when the lead-in is in backticks or math mode (addresses, functions, variables), skip the bold — e.g. `` `Address`: ... `` or `$object$ — ...`.

## Line Breaks

Write one sentence per line.
Inside a bullet point, continue subsequent sentences on indented lines under the same bullet, e.g.:

- First sentence of the bullet.
  Second sentence of the same bullet.

## Emphasis

Emphasis uses _italics_, not **bold**; write `_text_`, not `\textit{text}`. Same for informal definitions of objects.

## Math Formatting

- Equations that end a sentence are followed by a full stop.
- Multiplication involving a text object (e.g. $\mathrm{VariableName}$) uses $*$; other multiplication uses $\cdot$ (e.g. $a \cdot b$).
- "$i$th reward epoch" has $i$ in math mode (not "ith").
- Numbers in text use math mode (e.g. $10$), except:
  - table columns that are entirely numbers (e.g. percentages),
  - bit/byte lengths of integers (e.g. "32-bit integer"),
  - very large round numbers (e.g. $1$ million),
  - references to numbered-list elements (e.g. "step 3 of the above algorithm").
- $\dfrac{}{}$ is preferable to $\frac{}{}$ in text for legibility.
- Prefer `\mathrm` over `\text` (output is nearly identical — `\mathrm` removes spaces — so the preference is mild).

## Wording Conventions

- _emit_: on-chain Solidity events only.
- _produce_: off-chain artifacts (signatures, actions, receipts).
- _build_: instructions.
- _field origin_ (not "field population" or "field source"): how a field's value is set; documented with the producer, not in the type doc.
