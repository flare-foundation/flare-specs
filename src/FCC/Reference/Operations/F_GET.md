# F_GET

[Direct actions](../../Operations/Actions.md#direct-actions) issued by the [TEE proxy](../Components/Proxy.md) to poll the TEE machine for state and proofs.

## TEE_INFO

Liveness and state polling.
The proxy issues it periodically (every $\sim 10$ seconds), with a challenge derived from the latest C-chain block hash; the result feeds the [last-attestation cache](../Components/Proxy.md#in-memory-stores) served at `GET /info`.
The TEE machine signs an [`Attestation`](../Types/Abi/TeeMachine.md#attestation) struct over the supplied challenge and returns it together with platform attestation data.

**Action message:** [`TeeInfoRequest`](../Types/Wire/TeeMachine.md#teeinforequest).

**Action result:** [`TeeInfoResponse`](../Types/Wire/TeeMachine.md#teeinforesponse).

## KEY_INFO

Enumerates the keys stored on the TEE machine; returns one [`KeyInfo`](../Types/Wire/Key.md#keyinfo) entry per stored key.
The proxy issues it periodically (every $\sim 60$ minutes) to drive the [key data store](../Components/Proxy.md#in-memory-stores) sync; each refresh follows up with [`KEY_PROOF`](#key_proof) for any pair whose nonce changed.

**Action message:** empty.

**Action result:** a JSON array of [`KeyInfo`](../Types/Wire/Key.md#keyinfo).

## KEY_PROOF

Fetches signed key-existence proofs for a list of `(walletId, keyId)` pairs; returns one proof per requested pair, in the same order as the request.
Issued during the proxy's periodic [`KEY_INFO`](#key_info) sync, batched for pairs whose nonce changed since the last sync.

**Action message:** a JSON array of [`KeyIDPair`](../Types/Wire/Key.md#keyidpair).

**Action result:** a JSON array of [`SignedKeyExistenceProof`](../Types/Wire/Key.md#signedkeyexistenceproof), in the same order as the request.

**Validation.** The TEE machine rejects the request if any requested `(walletId, keyId)` is not currently stored on the machine.

## TEE_BACKUP

Obtains a fresh backup of one stored key.
The TEE machine constructs the backup from current state and the active [signing policy](../../../FSP/SigningPolicy.md), signs it with its identity key, and returns it.

The proxy schedules `TEE_BACKUP` via its [result hooks](../Components/Proxy.md#result-hooks) — once per new key and once per stored key after each successful [`UPDATE_POLICY`](F_POLICY.md#update_policy), to bind backups to the active signing policy's signer set and weights.

**Action message:** [`TeeBackupRequest`](../Types/Wire/Key.md#teebackuprequest).

**Action result:** [`TeeBackupResponse`](../Types/Wire/Key.md#teebackupresponse).

**Validation.** The TEE machine rejects the request unless:

- the `(walletId, keyId)` is currently stored on the machine; and
- the machine has an active [signing policy](../../../FSP/SigningPolicy.md) (it determines the data-provider weights the backup shares are split against).

See [Key backup](../../TeeManagement/Keys.md#backup-procedure) for the cryptographic construction of the backup package.
