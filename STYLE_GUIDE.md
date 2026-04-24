# Flare Specs Consistency Guide

This document lists suggestions for formatting choices in the Flare Specs documentation.

## Labelling Contract and Function Calls

Objects should be formatted with backticks e.g. `smartContract`.
When introducing a function call in Solidity on a new line, a colon is required e.g. This is my function:

```solidity
…
```

## Formatting of Specific Words and Grammar

- Flare network has a lower case n but Flare Foundation has an upper case F.
- Off-chain and on-chain contain dashes (e.g. not offchain).
- ID should always be written in uppercase.
- Bit-vote and bit-vector contain dashes.
- Bit and byte lengths of numbers are written with dashes e.g. 32-bit and 32-byte.
- The FTSO feeds are called anchor and block-latency feeds (note these are typically uncapitalized).
- Names of phases within protocols are also typically uncapitalized as they are intended to be descriptive.
- abi-encoded is all lower case and contains a dash.
- uint should be formatted in $\mathrm{uint}$.
- Oxford commas should be used (e.g. "a, b, and c" not "a, b and c").
- Protocols should be introduced with a "the" e.g. "participation in the FSP" rather than "participation in FSP".
- Docker is always capitalized.

## Indexing

Indexes are used for various objects across the specs, for temporal numbering such as epoch numbers and round numbers, and provider number.
To avoid going beyond standard indexes ($i$, $j$), some inconsistency is allowed e.g. $i$ may refer to provider number in one document and round number in another.
Try to stick to the following convention where possible:

- Each individual file must be internally consistent.
- Only use $k$ if three indexes are needed in the same file.
- Providers are indexed by $i$.
- Voting rounds, epochs etc. are indexed by $j$; $i$ can be used if another object that is not data providers needs to be indexed or if voting rounds are the only object being enumerated in a given file.
- Occasionally, reward epochs and voting epochs are both enumerated in the same doc.
  Try to use very clear indexing for this e.g. $j$ for voting epochs and $r$ for reward epoch or similar; legibility should be more important than style.
  This rule is probably the hardest one to enforce; for this unusual case a certain amount of discretion in picking something that looks nice is better than global consistency.

## Bullet Points

- Bullet points consisting of sentences should all be ended with a full stop.
- Bullet point lists of things that are not sentences should not be ended with a full stop, except the final bullet point.
- Bullet points where each point has a name should be formatted so that the name is in bold, followed by a colon, and the list should be numbered, e.g. "1. **Name**:" with the next word capitalized.
- An exception is made for lists where the names are formatted in backticks or math mode (e.g. they are addresses, functions, variables etc.), in which case the required formatting does not need to be augmented with bold script so that it should be e.g. "1. `Address`:" or "1. $object$:".

## Emphasis

Emphasis should be done in _italics_ (rather than **bold**) and should be called with `_text_` (rather than `\textit{text}`).
This also applies to objects being informally defined during text.

## Math Formatting

- Equations that end a sentence should be proceeded by a full stop.
- Multiplication of text objects (e.g. $\mathrm{Variable Name}$) should always be formatted with a $*$, regardless of whether the other object(s) are text objects or variables, numbers, etc. Other multiplication can be formatted with $\cdot$ e.g. $a \cdot b$.
- The "$i$th reward epoch" should have $i$ formatted in math mode (rather than just writing ith).
- Numbers in text should be formatted in math mode e.g. $10$, with the following exceptions:
  - If a column of a table entirely consists of numbers without text (e.g. each entry is x%), this does not apply and the numbers should not be formatted in maths mode.
  - Another exception is made for giving the byte/bit length of integers e.g. "32-bit integer" is written without calling maths mode.
  - Very large and round numbers in text e.g. in the millions should be written as e.g. $1$ million.
  - When referring to an element of a numbered list e.g. "step 3 of the above algorithm" math mode is not used.
- $\dfrac{}{}$ is preferable to $\frac{}{}$ during text for legibility.
- We currently use a mix of `\mathrm` and `\text` in maths mode. Using `\mathrm` is preferable, but the output looks the same (except that `\mathrm` removes spaces) so this is of low importance.

## TEEs

- $\mathrm{TEE}_{\mathrm{ID}}$ is the standard formatting for TEE_ID.
- Functions using TEE in the name are called with tee all lower case at the start, e.g. `teeExistenceProof`.
