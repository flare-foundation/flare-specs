# Cleaning Status

Status of changes on `e/cleaning` relative to `alen/AI-changes`.

## Directory Renames

`src/FlareTEE/` → `src/FCC/` with PascalCase subdirectory and file names:

| Old | New |
|-----|-----|
| `attestation-types/` | `AttestationTypes/` |
| `commands/` | `Commands/` |
| `workflows/` | `Workflows/` |
| `images/` | `Images/` |
| `TEE Management/` | `TeeManagement/` |
| `Extensions/Extensions.md` | `Extensions/Overview.md` |
| `Extensions/FTDC.md` | `Extensions/FDC2.md` |
| `Extensions/FDC2 Verifier Server.md` | `Extensions/Fdc2VerifierServer.md` |
| `Extensions/System Extension.md` | `Extensions/SystemExtension.md` |
| `TEE Management/Ownership.md` | `TeeManagement/Registration.md` |
| `TEE Management/State and Status.md` | `TeeManagement/StateAndAttestation.md` |
| `TEE Management/Tee Proxies.md` | `TeeManagement/TeeProxy.md` |
| `TEE Management/Key Management.md` | `TeeManagement/KeyManagement.md` |
| `Operations/Projects and Ownership.md` | `Operations/ProjectsAndConfiguration.md` |
| `Relay Client.md` | `Operations/RelayClient.md` |

## New Directories

- `src/FCC/Types/` — centralized ABI and wire type specifications, extracted from inline definitions across the spec files. Includes per-contract event files under `Types/Abi/Events/`.
- `src/Terminology/` — `Roles.md` and `Concepts.md`, referenced across the spec.

## New Root Files

- `STYLE_GUIDE.md` — formatting and style conventions for the spec.

## Removed Files

- `Organization.md` — content merged into other pages.
- `Events.md` — split into per-contract files under `Types/Abi/Events/`.

## Cleaned Files

Files that have received a thorough content review, style-guide compliance pass, and terseness pass:

- [x] `Introduction.md`
- [x] `Architecture.md`
- [x] `Operations/RelayClient.md`

## Not Yet Cleaned

All other files have received mechanical fixes (type reference updates, cosignerThreshold naming, event corrections, link fixes) but have not had a dedicated content review, style, or terseness pass.
