# F_WALLET KEY_GENERATE

## Description

Triggers generation of a key on a TEE machine. Smart contracts ensure that an instruction for the combination of `(walletId, keyId)` appears in one instruction only.

## Event message

The event message is formatted as the [`KeyGenerate`](../Types/Abi/Key.md#keygenerate) struct, which references [`KeyConfigConstants`](../Types/Abi/Key.md#keyconfigconstants) and [`PublicKey`](../Types/Abi/Common.md#publickey).

## Fixed message

/

## Variable message

/

## Additional action data

/

## Action result

- `keyExistence` — ABI encoded [`KeyExistence`](../Types/Abi/Key.md#keyexistence).

- `signature` — ECDSA [`Signature`](../Types/Abi/Common.md#signature) of the `keyExistence` hash by the TEE machine's identity key.

## Notes

- **Validation:** The TEE machine performs the following checks before generating a key:
  - The `teeId` in the instruction must match the machine's own identity.
  - The `adminsPublicKeys` list must be non-empty.
  - The `adminsThreshold` must be non-zero and not exceed the number of admins.
  - The `cosignersThreshold` must not exceed the number of cosigners.
  - The `signingAlgo` must be a supported algorithm (`keccak256-secp256k1-ecdsa`, `sha512half-secp256k1-ecdsa`, or `keccak256-secp256k1-vrf`).
  - The `(walletId, keyId)` pair must not already have a permanent record on the machine (prevents duplicate generation).
- **Signature format:** The `signature` field in the action result is the raw ECDSA signature bytes. Smart contracts decompose this into the `(v, r, s)` components of the `Signature` struct for on-chain verification.
- **Security considerations:** If data providers are malicious (50%+ attack), they can sign anything and send to any machine multiple times, which would result in generating different keys. From the smart contracts point of view, the first public key that gets confirmed (TeeKeyExistence attestation) on a key definition defines the validity of a key. Once a public key is set on a key definition, it cannot be changed.
