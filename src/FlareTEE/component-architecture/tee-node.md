# TEE Node Architecture

The TEE node runs inside a Trusted Execution Environment.
It manages wallet keys, cryptographic operations, signing-policy validation, and action execution on behalf of the TEE proxy.

![TEE Node architecture](images/tee-node.svg)

## Action Processing Pipeline

Per-worker loop:

1. **Fetch Action** — dequeue from the proxy.
2. **Normalize** — align variable messages.
3. **Extract OpID** — derive `(opType, opCommand)` hashes.
4. **Route** — if `(opType, opCommand)` is registered, execute the specific processor. Otherwise, forward to the default processor (extension).
5. **Sign Result** — Keccak256 + ECDSA by TEE key.
6. **Post Response** — return signed result to the proxy.

## Routers

### PMWRouter

Used for TEE machines on the system extension (ID $0$).
Registers dedicated processors for all system operations.
Unrecognized `(opType, opCommand)` pairs return an error.

### ForwardRouter

Used for TEE machines running custom extensions.
Registers the same system processors as `PMWRouter` plus two default processors that forward unrecognized operations to the extension service.

## Processors

### Direct Processors

Execute immediately, return a result.
No signature threshold checking.

| Processor | Op Type | Op Command | Description |
|---|---|---|---|
| `KeysInfo` | F_GET | [KEY_INFO](../commands/F_GET--KEY_INFO.md) | Returns signed key existence proofs for all stored keys |
| `TEEInfo` | F_GET | [TEE_INFO](../commands/F_GET--TEE_INFO.md) | Returns TEE attestation with challenge response |
| `TEEBackup` | F_GET | [TEE_BACKUP](../commands/F_GET--TEE_BACKUP.md) | Returns backup package for a specific key |
| `InitializePolicy` | F_POLICY | [INITIALIZE_POLICY](../commands/F_POLICY--INITIALIZE_POLICY.md) | Sets the initial signing policy |
| `UpdatePolicy` | F_POLICY | [UPDATE_POLICY](../commands/F_POLICY--UPDATE_POLICY.md) | Updates to the next signing policy |

### Instruction Processors

Multi-phase processors with signature threshold checking.
Preprocessing validates the signing policy, extracts signers, and checks weight thresholds.

| Processor | Op Type | Op Command | Immediate Result |
|---|---|---|---|
| `KeyGenerate` | F_WALLET | [KEY_GENERATE](../commands/F_WALLET--KEY_GENERATE.md) | Yes |
| `KeyDelete` | F_WALLET | [KEY_DELETE](../commands/F_WALLET--KEY_DELETE.md) | Yes |
| `KeyDataProviderRestore` | F_WALLET | [KEY_DATA_PROVIDER_RESTORE](../commands/F_WALLET--KEY_DATA_PROVIDER_RESTORE.md) | Yes |
| `VRF` | F_WALLET | [VRF](../commands/F_WALLET--VRF.md) | Yes |
| `TEEAttestation` | F_REG | [TEE_ATTESTATION](../commands/F_REG--TEE_ATTESTATION.md) | Yes |
| `SignXRPLPayment` | F_XRP | [PAY](../commands/F_XRP--PAY.md) / [REISSUE](../commands/F_XRP--REISSUE.md) | No |
| `FDC2Prove` | F_FDC2 | [PROVE](../commands/F_FDC2--PROVE.md) | Yes |

### Submission Tags

- `threshold` — emitted when the signing weight threshold is first reached. Most processors produce their main result here.
- `end` — emitted at the end of the voting period. Used for final accounting (e.g., reward data) or for restore operations that need maximum share collection time.
- `submit` — used for direct instruction actions.

### Result Status Codes

- $0$: Error/invalid.
- $1$: Success.
- $2$: In-progress (async operations like XRP payments).
- $3+$: Scheduled responses (XRP fee schedule progression).

## State Management

All state is held in memory.

### Node State

- $\mathrm{TEE}_{\mathrm{ID}}$ — Ethereum address derived from the identity key.
- Identity private key — ECDSA private key (never leaves the TEE).
- Initial owner — set once during configuration.
- Extension ID — set once during configuration.

### Wallet Storage

A map from `(walletId, keyId)` to wallet data:

- `Wallet` — private key bytes, signing algorithm, admin keys, cosigners, thresholds.
- `WalletStatus` (permanent) — nonce, pauseNonce, status, expiry. Retained even after key deletion for replay protection.

Three signing algorithms are supported: `keccak256-secp256k1-ecdsa` (EVM), `sha512half-secp256k1-ecdsa` (XRP), and `keccak256-secp256k1-vrf` (VRF).

### Policy Storage

- Current and initial signing policies with voter public keys.
- Map of reward epoch ID to signing policy for historical lookups.

## Communication with Proxy

Two endpoints connect the node to the proxy:

| Direction | Endpoint | Purpose |
|---|---|---|
| Node → Proxy | `POST /queue/<queueId>` | Dequeue next action from Main, Direct, or Backup queue |
| Node → Proxy | `POST /result` | Push signed action response back to proxy |

## Extension Integration

The TEE node exposes cryptographic capabilities to extension services via a sign server, and forwards unrecognized operations to the extension service.
Extensions can sign data, retrieve key information, decrypt data, and post results.

## Platform Attestation

Attestation token generation depends on deployment mode:

- **Production** — platform attestation (e.g., Google Cloud Confidential Space JWT).
- **Local/development** — test platform and code hash values.

Attestation is included in [TEE_INFO](../commands/F_GET--TEE_INFO.md) and [TEE_ATTESTATION](../commands/F_REG--TEE_ATTESTATION.md) responses for on-chain verification.

---

## Implementation Details

### Entry Point and Initialization

Startup sequence (`cmd/main.go`):

1. **Key generation** — an ECDSA private key is generated inside the TEE. The corresponding Ethereum address becomes $\mathrm{TEE}_{\mathrm{ID}}$.
2. **Storage initialization** — in-memory wallet storage and policy storage are created (empty).
3. **Config server** — an HTTP server on port $5500$ accepts configuration: proxy URL, initial owner address, and extension ID.
4. **Router creation** — either a `PMWRouter` or `ForwardRouter` is created and registered with all processors.
5. **Queue workers** — three goroutines are spawned, each continuously polling the proxy for actions on their respective queue (Main, Direct, Backup).

Workers sleep $100$ ms when the queue is empty and retry on errors.
State is protected by `sync.RWMutex`.

### Sign Server (port $8888$)

HTTP server exposing TEE cryptographic capabilities to extension services:

- `GET /key-info/<walletId>/<keyId>` — retrieve wallet key information.
- `POST /sign/<walletId>/<keyId>` — sign data with a wallet key.
- `POST /sign` — sign data with the TEE identity key.
- `POST /decrypt/<walletId>/<keyId>` — decrypt with a wallet key.
- `POST /decrypt` — decrypt with the TEE identity key.
- `POST /result` — post a signed result back to the proxy.

### Extension Forwarding

When the `ForwardRouter` encounters an unregistered operation, it forwards the full action as an HTTP POST to `http://localhost:<extensionPort>/action` (default port $8889$).
The extension service processes the action and returns an `ActionResult`.

### Configuration

| Variable | Default | Description |
|---|---|---|
| `MODE` | $0$ | $0$ = production, $1$ = local |
| `CONFIG_PORT` | $5500$ | Config server port |
| `SIGN_PORT` | $8888$ | Extension sign server port |
| `EXTENSION_PORT` | $8889$ | Extension service port |
| `PROXY_URL` | — | TEE proxy endpoint |
| `INITIAL_OWNER` | — | Initial owner address (hex) |
| `EXTENSION_ID` | — | Extension ID hash (hex) |
