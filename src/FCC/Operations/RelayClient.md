# Relay Client

A _relay client_ is an off-chain component that transforms [instruction events](Instructions.md#instruction-events) into signed [TEE instructions](Instructions.md#tee-instructions) and submits them to [TEE proxies](../TeeManagement/TeeProxy.md).
Each relay client is configured with a private key whose corresponding address identifies its _operator_.
It runs in one of two modes: _[data provider](../../Terminology/Roles.md#data-provider)_ or _[cosigner](../../Terminology/Roles.md#cosigner)_.

## Relay Flow

1. Observe an instruction event in a C-chain indexer database.
   The operator is responsible for providing access to a C-chain indexer.
2. Filter the event based on mode:
   - _Data provider_ mode: accept all instructions.
   - _Cosigner_ mode: accept only instructions whose [`cosigners` list](Instructions.md#cosigners) includes the operator's address.
3. For [augmented instructions](#instruction-augmentation), prepare the required data.
4. Construct one [TEE instruction](Instructions.md#tee-instructions) per destination TEE machine in the event's `teeMachines` field.
   Each TEE instruction includes the destination $\mathrm{TEE}_{\mathrm{ID}}$ in its [data payload](Instructions.md#data-format), binding it to a specific machine.
5. Sign each instruction and submit it to the corresponding TEE proxy via [`POST /instruction`](../TeeManagement/TeeProxy.md#external-write-apis).
   - The [signature](Instructions.md#signature-format) covers the $\mathrm{TEE}_{\mathrm{ID}}$, preventing a compromised proxy from replaying an instruction to a different machine.
   - The proxy URL for each destination is included in `teeMachines`.

## Behavior

The relay path is _best effort_: delivery and ordering are not guaranteed.
The same instruction may be submitted more than once or arrive in different orders at different proxies.
This is compatible with proxy [voting](Voting.md) and, where required, replay protection inside the TEE machine.
Instructions are processed concurrently; one slow or failing instruction does not block others.

### Startup

On startup, the relay client begins observing events from a recent block height rather than from genesis.
Instructions emitted while the relay client is offline may not be relayed.

### Error Handling

- The relay client retries submission on transient failures (network errors, HTTP $429$, HTTP $403$).
- Instructions that fail permanently (HTTP $400$) or after retry exhaustion are dropped.
- Undelivered instructions are not persisted across restarts.
- The proxy returns a signed receipt on successful submission; the relay client does not act on it.

## Instruction Augmentation

Certain instructions require the relay client to augment the instruction with off-chain data before signing, using the `additionalFixedMessage` and `additionalVariableMessage` fields of the [TEE instruction](Instructions.md#data-format).
The relay client selects the augmentation based on the event's `opType` and `opCommand` fields.
All other valid instructions are relayed without augmentation.

### FDC2

For [`PROVE`](../Commands/F_FDC2--PROVE.md) instructions on the [FDC2](../Extensions/FDC2.md) extension:

1. Send the attestation request to an [FDC2 verifier server](../Extensions/Fdc2VerifierServer.md) and obtain the response body.
2. Place the response body into `additionalFixedMessage`.
3. Compute the [attestation response hash](../Extensions/FDC2.md#signature-computation) and sign it with the operator's private key.
4. Place the signature into `additionalVariableMessage`.

FDC2 instructions are queued by attestation type and source before submission to the verifier, with configurable rate limits and concurrency per queue.
If the verifier rejects the request (HTTP $400$, $422$), the instruction is dropped.
If the verifier returns a transient error (HTTP $503$) or a network failure, the relay client retries.

See the [FDC2 instruction format](../Extensions/FDC2.md#instruction-format) for the full field specification.

### Key Restoration

During the [backup procedure](../TeeManagement/KeyManagement.md#backup-procedure), each data provider and [key admin](../../Terminology/Roles.md#key-admin) receives a _holder backup package_ — their [Shamir secret share](../TeeManagement/KeyManagement.md#backup-procedure) of the backed-up private key, encrypted under the holder's public key using ECIES.
For [`KEY_DATA_PROVIDER_RESTORE`](../Commands/F_WALLET--KEY_DATA_PROVIDER_RESTORE.md) instructions, the relay client re-encrypts its share:

1. Fetch the backup package from `backupUrl` in the instruction.
   The package is subject to a size limit; if the response exceeds it or the server returns an error, the instruction is dropped.
2. Validate that the package metadata matches all [`BackupId`](../Types/Abi/Key.md#backupid) fields: `teeId`, `walletId`, `keyId`, `keyType`, `signingAlgo`, `publicKey`, `rewardEpochId`, and `randomNonce`.
   If any field does not match, the instruction is dropped.
3. Extract the holder backup package corresponding to the operator's public key.
   If the operator holds shares in both the data provider and key admin pools, both are included.
   If the operator's key does not appear in either pool, the instruction is dropped.
4. Decrypt the share using the operator's private key.
5. Re-encrypt the share under the target TEE machine's public key ([`TeePublicKey`](../Types/Abi/Common.md#publickey) in the instruction) using ECIES.
6. Place the [backup metadata](../TeeManagement/KeyManagement.md#backup-data-and-metadata) into `additionalFixedMessage`.
7. Place the ECIES ciphertext into `additionalVariableMessage`.

See [key restoration procedure](../TeeManagement/KeyManagement.md#key-restoration-procedure) for the full process including TEE-side recovery.
