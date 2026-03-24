# TEE Proxy Architecture

The TEE proxy controls access to the TEE node.
It manages instruction voting, action queuing, result storage, signing-policy synchronization, wallet tracking, and key backups.
External clients interact with the proxy, not the TEE node directly.

![TEE Proxy architecture](images/tee-proxy.svg)

For the full proxy specification including APIs, state stores, processing queues, and security model, see [TEE Proxies](../TEE%20Management/Tee%20Proxies.md).

## Voting System

Threshold-based voting for TEE instructions.
For general voting concepts, see [Voting](../Operations/Voting.md).

### Cosigner and Threshold Resolution

Cosigners and custom thresholds are resolved per instruction type:

- **XRP payments** (`PAY`, `REISSUE`): cosigners fetched from the wallet configuration.
- **Key restore** ([`KEY_DATA_PROVIDER_RESTORE`](../commands/F_WALLET--KEY_DATA_PROVIDER_RESTORE.md)): cosigners extracted from backup metadata (admin keys and threshold).
- **FDC2** (`PROVE`): custom threshold from the FDC request header (`thresholdBIPS`); $0$ means use the signing policy default.
- **Other instructions**: cosigners and threshold from the instruction event itself.

### Voting Constraints

| Field | Default Limit | Restore Limit |
|---|---|---|
| Original message | $50$ KiB | $50$ KiB |
| Additional fixed message | $100$ KiB | $100$ KiB |
| Additional variable message | $50$ KiB | $1$ MiB |

System operations ([`KEY_INFO`](../commands/F_GET--KEY_INFO.md), [`TEE_INFO`](../commands/F_GET--TEE_INFO.md), [`TEE_BACKUP`](../commands/F_GET--TEE_BACKUP.md), [`INITIALIZE_POLICY`](../commands/F_POLICY--INITIALIZE_POLICY.md), [`UPDATE_POLICY`](../commands/F_POLICY--UPDATE_POLICY.md)) cannot be submitted as instructions — they are direct-only.

## Signing Policy Management

The policy service reads `SigningPolicyInitialized` events from the Relay contract.
On startup, it creates an [`INITIALIZE_POLICY`](../commands/F_POLICY--INITIALIZE_POLICY.md) action with the current signing policy and voter public keys.
When new policies appear, it creates [`UPDATE_POLICY`](../commands/F_POLICY--UPDATE_POLICY.md) actions and broadcasts to the instruction service, which creates new voting rounds.

---

## Implementation Details

### Initialization Flow

1. Parse TOML configuration and initialize logging.
2. Connect to the C-chain indexer database (MySQL) and wait for it to sync.
3. Connect to Redis.
4. Create action queues (Main, Direct, Backup) and result storage in Redis.
5. Create the wallet service (in-memory key cache + Redis backup storage).
6. Start the internal server (port $6661$).
7. Start the info service — sends an [`INITIALIZE_POLICY`](../commands/F_POLICY--INITIALIZE_POLICY.md) action and a [`TEE_INFO`](../commands/F_GET--TEE_INFO.md) action via the direct queue, waits for responses to establish the TEE's identity.
8. Start the policy service — listens for `SigningPolicyInitialized` events from the Relay contract and creates [`UPDATE_POLICY`](../commands/F_POLICY--UPDATE_POLICY.md) actions when new policies appear.
9. Start the instruction service — creates voting rounds for the current signing policy.
10. Start the external server (port $6662$).

### Voting Data Structure

```
Storage (cyclic buffer by rewardEpochID)
└── Round (one per signing policy)
    ├── Limiter (per-voter request limits)
    └── Voting (instruction voting map)
        └── map[instructionID] → voteBoxes
            └── map[instructionHash] → voteBox
                ├── proposal (instruction + thresholds)
                ├── votes (map[signer → vote])
                ├── weight (accumulated)
                ├── cosignerWeight (accumulated)
                └── finalized (bool)
```

### Voting Flow

1. A data provider submits a signed instruction via `POST /instruction`.
2. The proxy validates the TEE ID, operation pair, and signer identity.
3. The instruction is hashed. A vote box is created (or an existing one is matched) for the `(instructionID, instructionHash)` pair.
4. The signer's weight (from the signing policy) is accumulated.
5. If cosigners are required, cosigner signatures are tracked separately.
6. When both the data provider weight threshold and cosigner threshold are met, the vote box is *finalized*:
   - A `threshold` action is created and enqueued to the Main queue immediately.
   - An `end` action is scheduled for when the voting window expires (default $120$ seconds).
7. The proxy returns a signed receipt to the data provider.

### Result Event Routing

When the TEE node posts a result via `POST /result`, the proxy:

1. Validates the TEE signature (recovers signer address, checks against stored TEE ID).
2. Stores the result in Redis.
3. Routes events to internal channels:
   - **WalletSync** channel — for [`KEY_GENERATE`](../commands/F_WALLET--KEY_GENERATE.md), [`KEY_DELETE`](../commands/F_WALLET--KEY_DELETE.md), [`KEY_DATA_PROVIDER_RESTORE`](../commands/F_WALLET--KEY_DATA_PROVIDER_RESTORE.md) results (updates in-memory key cache).
   - **Backups** channel — for [`TEE_BACKUP`](../commands/F_GET--TEE_BACKUP.md) results (stores backup in Redis with $8$-day TTL).
   - **BackupTrigger** channel — for [`UPDATE_POLICY`](../commands/F_POLICY--UPDATE_POLICY.md) results (triggers re-backup of all keys).

### Configuration

Configuration fields (`config.toml`):

```toml
chain_id = 14              # Required: Flare chain ID (14 = mainnet, 16 = Coston)
redis_port = ":6379"
private_key_variable = "PRIVATE_KEY"
db_sync_max_sleep_time = "10m"  # Optional: max sleep between DB sync retries on startup

[db]                    # C-chain indexer DB
[addresses]             # Relay, VoterRegistry, FlareSystemsManager
[ports]
internal = "6661"
external = "6662"

[voting]
proposal_expiration = "120s"
max_pending_request = 100

[info_timing]
cycle_internal = "10s"
```
