# F_WALLET KEY_DATA_PROVIDER_RESTORE

[Instruction action](../../Actions.md#instruction-actions) that restores a previously backed-up key onto a target TEE machine.
Each [signer](../../Instructions.md#signers) ([data provider](../../../../Terminology/Roles.md#data-provider) and/or [key admin](../../../../Terminology/Roles.md#key-admin)) fetches the backup package, verifies it, and re-encrypts its [Shamir secret share](../../../TeeManagement/Keys.md#backup-procedure) under the target TEE's public key (see [Augmentation](#augmentation)).
The TEE machine recovers the private key from these shares and returns a signed `KeyExistence` proof.

This is the proxy-level exception for [voting outcomes](../../Voting.md#outcomes): both the `threshold` and `end` actions are produced when the vote box closes, so the machine receives every share that arrived before close.

## Event message

[`KeyDataProviderRestore`](../../../Types/Abi/Key.md#keydataproviderrestore), referencing [`BackupId`](../../../Types/Abi/Key.md#backupid) and [`PublicKey`](../../../Types/Abi/Common.md#publickey).

## Augmentation

During [backup](../../../TeeManagement/Keys.md#backup-procedure), each holder (data provider or admin) receives a _holder backup package_: its Shamir share of the original private key, ECIES-encrypted under its own public key.
Before signing the instruction, the [relay client](../../../Components/RelayClient.md) re-encrypts that share for the target TEE:

1. Fetch the backup package from `backupUrl`. The instruction is dropped if the fetch fails.
2. Verify that the package's metadata matches every field of the instruction's [`BackupId`](../../../Types/Abi/Key.md#backupid); any mismatch drops the instruction.
3. Verify that the target TEE machine (identified by the `BackupId.teeId` recipient address) is registered, currently attested, and not running banned code.
4. Extract the holder backup package(s) addressed to the relay client's public key. The key may appear in the data-provider pool, the admin pool, or both; if in both, both packages are extracted. If in neither, the instruction is dropped.
5. Decrypt each extracted share with the relay client's private key.
6. Re-encrypt the share(s) under the target TEE's `teePublicKey` (from the instruction) using ECIES. When step 4 produced two shares, both are bundled into a single ciphertext.
7. Place the [backup metadata](../../../TeeManagement/Keys.md#backup-data-and-metadata) into `additionalFixedMessage` and the ECIES ciphertext into `additionalVariableMessage`.

For the full TEE-side recovery procedure, see [key restoration](../../../TeeManagement/Keys.md#key-restoration-procedure).

## Action result

[`SignedKeyExistenceProof`](../../../Types/Wire/Key.md#signedkeyexistenceproof) over a [`KeyExistence`](../../../Types/Abi/Key.md#keyexistence) record whose `restored` field is set.

`additionalResultStatus` reports per-share processing errors (decryption, signature, duplicate-share, or backup-ID mismatch).

## Validation

The TEE machine rejects the instruction unless all of the following hold:

- `teePublicKey` derives to the machine's own `teeId`.
- The `BackupId`'s `signingAlgo` is one of `keccak256-secp256k1-ecdsa`, `sha512half-secp256k1-ecdsa`, or `keccak256-secp256k1-vrf`.
- The `additionalFixedMessage` metadata's `WalletBackupID` matches the instruction's `BackupId`.
- The metadata's admin public keys derive to distinct admin addresses (no duplicates).
- The instruction's `cosigners` and `cosignersThreshold` agree with the admins and admin threshold recorded in the backup metadata.
- Every [signer](../../Instructions.md#signers) is in either the data-provider pool of the signing policy at backup time or the admin pool from the metadata; the admin threshold is reached.
- No active key for `(walletId, keyId)` is currently stored on the machine. If a nonce record from a previous lifecycle exists, the instruction's `nonce` must be strictly greater than the stored nonce.

## Notes

- The result is signed with the same `KeyExistence` format as [`KEY_GENERATE`](KeyGenerate.md), so on-chain `KeyExistence` attestations are interchangeable between fresh keys and restored ones.
- On the `end` submission tag the machine re-checks that the wallet now exists and that its nonce matches the one consumed at `threshold`.
