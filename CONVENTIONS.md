# Flare Specs Conventions

Structural and architectural conventions for the Flare Specs.
See [`STYLE_GUIDE.md`](STYLE_GUIDE.md) for writing-style rules.

## Roles Glossary

`src/Terminology/Roles.md` is the single cross-protocol "who's who". Protocol pages link rather than re-define a role; only the protocol-side mechanism (e.g. allowlist gating) lives outside `Roles.md`.

## Type Documentation

`Reference/Types/Abi/` and `Reference/Types/Wire/`:

- Schema (JSON-schema block) plus a one-line invariant per field — what the field always means.
- A field's _origin_ (how the value is set) lives next to its producer, not in the type doc. Pattern: the `### Event Field Origins` table in `Reference/Contracts/FlareTeeManager.md`.
- Universal origins (e.g. `teeId` = address recovered from the registration signature) may appear as part of the invariant; multi-producer fields stay schema-only.

Canonical term: _field origin_, not "field population" or "field source".

## Implementation-Agnostic Specs

- Backend: "key-value store" rather than a specific product (Redis, etc.). Specific products only in deployment docs.
- No implementation-language code: rewrite Go / JavaScript / Python / CLI snippets as equations or pseudocode. Solidity is the exception (it _is_ the on-chain spec).
