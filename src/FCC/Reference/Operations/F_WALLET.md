# F_WALLET

[Instruction actions](../../Operations/Actions.md#instruction-actions) that manage wallet-stored private keys on TEE machines: generation, deletion, restoration from backup, and VRF proof production.

## KEY_GENERATE

Generates a key on a TEE machine.
The diamond ensures at most one `KEY_GENERATE` instruction is emitted per `(walletId, keyId)` pair.

**Event message:** [`KeyGenerate`](../Types/Abi/Key.md#keygenerate), referencing [`KeyConfigConstants`](../Types/Abi/Key.md#keyconfigconstants) and [`PublicKey`](../Types/Abi/Common.md#publickey).

**Action result:** [`SignedKeyExistenceProof`](../Types/Wire/Key.md#signedkeyexistenceproof) wrapping a [`KeyExistence`](../Types/Abi/Key.md#keyexistence) record.

**Validation.** The TEE machine rejects the instruction unless all of the following hold:

- `teeId` matches the machine's own identity.
- `adminsPublicKeys` is non-empty and contains no duplicate keys.
- $0 < \mathrm{adminsThreshold} \leq \lvert \mathrm{adminsPublicKeys} \rvert$.
- `cosigners` contains no duplicate addresses, and $\mathrm{cosignersThreshold} \leq \lvert \mathrm{cosigners} \rvert$.
- `signingAlgo` is one of `keccak256-secp256k1-ecdsa`, `sha512half-secp256k1-ecdsa`, or `keccak256-secp256k1-vrf`.
- No permanent record already exists for `(walletId, keyId)` on the machine.

**Notes.**

- On the `end` submission tag the machine re-checks that the key is still stored under `(walletId, keyId)`, so a missing or evicted record fails the end-tag action.
- On chain the first confirmed `KeyExistence` attestation fixes the key's public key; later attestations from other machines for the same `(walletId, keyId)` cannot change it. A malicious data provider majority that signs the same instruction to multiple machines can therefore cause different generated keys to attest, but only one survives on chain.

## KEY_DELETE

Deletes a key from the TEE machine's wallet store, if present.

Every key that was ever stored on the machine retains a nonce record that survives deletion.
A delete is valid if the nonce record exists and is strictly lower than the instruction's `nonce`; on success the key is removed (if present) and the nonce record is bumped to the instruction's `nonce`.
If the key is no longer present but the nonce check passes, the action result carries an `additionalResultStatus` of `"key not stored"`.

The retained nonce is reused if the same `(walletId, keyId)` is later restored via [`KEY_DATA_PROVIDER_RESTORE`](#key_data_provider_restore).

**Event message:** [`KeyDelete`](../Types/Abi/Key.md#keydelete).

**Action result:** JSON-encoded [`KeyIDPair`](../Types/Wire/Key.md#keyidpair) with the `(walletId, keyId)` of the deleted key.

**Validation.**

- A nonce record must already exist for `(walletId, keyId)` (the key must have been previously generated or restored on this machine).
- `nonce` must be strictly greater than the stored nonce.

**Notes.**

- On the `end` submission tag the machine re-checks that the key is gone and that its nonce record has been consumed, ensuring the `threshold` and `end` views agree.

## KEY_DATA_PROVIDER_RESTORE

Restores a previously backed-up key onto a target TEE machine.
Each [signer](../../Operations/Instructions.md#signers) ([data provider](../../../Terminology/Roles.md#data-provider) and/or [key admin](../../../Terminology/Roles.md#key-admin)) fetches the backup package, verifies it, and re-encrypts its [Shamir secret share](../../TeeManagement/Keys.md#backup-procedure) under the target TEE's public key (see [Augmentation](#augmentation)).
The TEE machine recovers the private key from these shares and returns a signed `KeyExistence` proof.

This is the proxy-level exception for [voting outcomes](../../Operations/Voting.md#outcomes): both the `threshold` and `end` actions are produced when the vote box closes, so the machine receives every share that arrived before close.

**Event message:** [`KeyDataProviderRestore`](../Types/Abi/Key.md#keydataproviderrestore), referencing [`BackupId`](../Types/Abi/Key.md#backupid) and [`PublicKey`](../Types/Abi/Common.md#publickey).

### Augmentation

During [backup](../../TeeManagement/Keys.md#backup-procedure), each holder (data provider or admin) receives a _holder backup package_: its Shamir share of the original private key, ECIES-encrypted under its own public key.
Before signing the instruction, the [relay client](../Components/RelayClient.md) re-encrypts that share for the target TEE:

1. Fetch the backup package from `backupUrl`. The instruction is dropped if the fetch fails.
2. Verify that the package's metadata matches every field of the instruction's [`BackupId`](../Types/Abi/Key.md#backupid); any mismatch drops the instruction.
3. Verify that the target TEE machine (identified by the `BackupId.teeId` recipient address) is registered, currently attested, and not running banned code.
4. Extract the holder backup package(s) addressed to the relay client's public key. The key may appear in the data-provider pool, the admin pool, or both; if in both, both packages are extracted. If in neither, the instruction is dropped.
5. Decrypt each extracted share with the relay client's private key.
6. Re-encrypt the share(s) under the target TEE's `teePublicKey` (from the instruction) using ECIES. When step 4 produced two shares, both are bundled into a single ciphertext.
7. Place the [backup metadata](../../TeeManagement/Keys.md#backup-data-and-metadata) into `additionalFixedMessage` and the ECIES ciphertext into `additionalVariableMessage`.

For the full TEE-side recovery procedure, see [key restoration](../../TeeManagement/Keys.md#key-restoration-procedure).

### Action result

[`SignedKeyExistenceProof`](../Types/Wire/Key.md#signedkeyexistenceproof) over a [`KeyExistence`](../Types/Abi/Key.md#keyexistence) record whose `restored` field is set.

`additionalResultStatus` reports per-share processing errors (decryption, signature, duplicate-share, or backup-ID mismatch).

### Validation

The TEE machine rejects the instruction unless all of the following hold:

- `teePublicKey` derives to the machine's own `teeId`.
- The `BackupId`'s `signingAlgo` is one of `keccak256-secp256k1-ecdsa`, `sha512half-secp256k1-ecdsa`, or `keccak256-secp256k1-vrf`.
- The `additionalFixedMessage` metadata's `WalletBackupID` matches the instruction's `BackupId`.
- The metadata's admin public keys derive to distinct admin addresses (no duplicates).
- The instruction's `cosigners` and `cosignersThreshold` agree with the admins and admin threshold recorded in the backup metadata.
- Every [signer](../../Operations/Instructions.md#signers) is in either the data-provider pool of the signing policy at backup time or the admin pool from the metadata; the admin threshold is reached.
- No active key for `(walletId, keyId)` is currently stored on the machine. If a nonce record from a previous lifecycle exists, the instruction's `nonce` must be strictly greater than the stored nonce.

### Notes

- The result is signed with the same `KeyExistence` format as [`KEY_GENERATE`](#key_generate), so on-chain `KeyExistence` attestations are interchangeable between fresh keys and restored ones.
- On the `end` submission tag the machine re-checks that the wallet now exists and that its nonce matches the one consumed at `threshold`.

## VRF

Produces a verifiable randomness proof using a stored VRF key.
The TEE machine loads the private key identified by `(walletId, keyId)` and computes an ECVRF proof over the supplied `nonce`.

The on-chain `VrfVerifier` contract verifies the proof using `ecrecover`; the four witness points (`u`, `cGamma`, `v`, `zInv`) in the response are pre-computed off-chain to avoid expensive secp256k1 scalar multiplications inside the EVM.
The final random value is $\mathrm{keccak256}(\gamma_x \,\|\, \gamma_y)$, where $\gamma_x, \gamma_y$ are 32-byte big-endian encodings of the `gamma` point coordinates.

**Event message:** [`VrfInstructionMessage`](../Types/Abi/Key.md#vrfinstructionmessage).

**Action result:** JSON object:

- `walletId`, `keyId`, `nonce`: copied from the request.
- `proof`: an object with the following fields ($G$ is the secp256k1 generator, $\mathrm{sk}$ the private key, $\mathrm{pk}$ the public key, $H = \mathrm{HashToCurve}(\mathrm{nonce})$, $N$ the curve order, $P$ the field prime):
  - `gamma`: a curve point $\gamma = \mathrm{sk} * H$ (the VRF output).
  - `c`: the challenge scalar.
  - `s`: the response scalar, $s = k - \mathrm{sk} * c \mod N$.
  - `u`: witness point $c * \mathrm{pk} + s * G$.
  - `cGamma`: witness point $c * \gamma$.
  - `v`: witness point $c * \gamma + s * H$.
  - `zInv`: field element $(\mathrm{cGamma}_x - v_x)^{-1} \mod P$.

**Validation.**

- The `(walletId, keyId)` must identify a key stored on the machine.
- That key's `signingAlgo` must be `keccak256-secp256k1-vrf`.
- `nonce` must be non-empty.
