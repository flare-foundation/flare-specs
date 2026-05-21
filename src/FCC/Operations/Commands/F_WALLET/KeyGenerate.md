# F_WALLET KEY_GENERATE

[Instruction action](../../Actions.md#instruction-actions) that generates a key on a TEE machine.
The diamond ensures at most one `KEY_GENERATE` instruction is emitted per `(walletId, keyId)` pair.

## Event message

[`KeyGenerate`](../../../Types/Abi/Key.md#keygenerate), referencing [`KeyConfigConstants`](../../../Types/Abi/Key.md#keyconfigconstants) and [`PublicKey`](../../../Types/Abi/Common.md#publickey).

## Action result

[`SignedKeyExistenceProof`](../../../Types/Wire/Key.md#signedkeyexistenceproof) wrapping a [`KeyExistence`](../../../Types/Abi/Key.md#keyexistence) record.

## Validation

The TEE machine rejects the instruction unless all of the following hold:

- `teeId` matches the machine's own identity.
- `adminsPublicKeys` is non-empty and contains no duplicate keys.
- $0 < \mathrm{adminsThreshold} \leq \lvert \mathrm{adminsPublicKeys} \rvert$.
- `cosigners` contains no duplicate addresses, and $\mathrm{cosignersThreshold} \leq \lvert \mathrm{cosigners} \rvert$.
- `signingAlgo` is one of `keccak256-secp256k1-ecdsa`, `sha512half-secp256k1-ecdsa`, or `keccak256-secp256k1-vrf`.
- No permanent record already exists for `(walletId, keyId)` on the machine.

## Notes

- On chain the first confirmed `KeyExistence` attestation fixes the key's public key; later attestations from other machines for the same `(walletId, keyId)` cannot change it. A malicious data provider majority that signs the same instruction to multiple machines can therefore cause different generated keys to attest, but only one survives on chain.
