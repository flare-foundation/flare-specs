# Type Reference

Data structures used across the FCC specification, organized into two categories:

- **[ABI types](abi/)** — Solidity struct definitions used for ABI encoding, hash computation, and on-chain verification.
  Documented as JSON schemas following the [format glossary](#format-glossary).
- **[Wire types](wire/)** — JSON types as communicated over HTTP between TEE components (proxy APIs, TEE node actions).
  Documented as JSON schemas matching their actual JSON wire representation.

Where a type appears in both contexts, the ABI page defines the canonical struct and the wire page documents any differences in representation or wrapping.

## Format Glossary

The schemas use custom `format` values to describe Solidity and EVM types.
The table below defines each format and its JSON wire representation.

| Format | Solidity type | JSON representation | Example |
|--------|--------------|---------------------|---------|
| `address` | `address` | 0x-prefixed hex string, $20$ bytes | `"0x1234...5678"` |
| `bytes32` | `bytes32` | 0x-prefixed hex string, $32$ bytes | `"0xabcd...ef01"` |
| `bytes` | `bytes` | 0x-prefixed hex string, variable length | `"0xdeadbeef"` |
| `uint256` | `uint256` | Decimal integer or decimal string | `999` or `"999"` |
| `uint64` | `uint64` | JSON number | `12345` |
| `uint32` | `uint32` | JSON number | `42` |
| `uint16` | `uint16` | JSON number | `4000` |
| `uint8` | `uint8` | JSON number | `1` |

All byte and hash values use lowercase hex with a `0x` prefix.
Integer types up to $64$ bits are represented as JSON numbers.
The `uint256` type may appear as either a JSON number or a decimal string depending on context.

---

## ABI Types

### Common

- [PublicKey](abi/Common.md#publickey) — Elliptic curve public key $(x, y)$ coordinates.
- [Signature](abi/Common.md#signature) — ECDSA signature $(v, r, s)$ components (on-chain form).
- [TeeIdKeyIdPair](abi/Common.md#teeidkeyidpair) — Associates a TEE machine with a key ID.

### Instructions

- [TeeInstruction](abi/Instruction.md#teeinstruction) — Signed instruction data, ABI-encoded for `instructionHash`.

### Voting

- [VoteSequenceInit](abi/Voting.md#votesequenceinit) — Initial vote hash struct.
- [VoteSequenceNext](abi/Voting.md#votesequencenext) — Subsequent vote hash struct.
- [VoteReceipt](abi/Voting.md#votereceipt) — Vote receipt struct.

### Key Management

- [KeyGenerate](abi/Key.md#keygenerate) — Key generation instruction message.
- [KeyConfigConstants](abi/Key.md#keyconfigconstants) — Immutable wallet configuration constants.
- [KeyExistence](abi/Key.md#keyexistence) — Proof of key existence (ABI-encoded; see [wire form](wire/Key.md#signedkeyexistenceproof)).
- [KeyDelete](abi/Key.md#keydelete) — Key deletion instruction message.
- [BackupId](abi/Key.md#backupid) — Key backup identifier.
- [VrfInstructionMessage](abi/Key.md#vrfinstructionmessage) — VRF proof generation instruction.

### FDC2

- [Fdc2AttestationRequest](abi/Fdc2.md#fdc2attestationrequest) — Attestation request wrapper.
- [Fdc2RequestHeader](abi/Fdc2.md#fdc2requestheader) — Request header.
- [Fdc2ResponseHeader](abi/Fdc2.md#fdc2responseheader) — Response header.
- [Fdc2Signatures](abi/Fdc2.md#fdc2signatures) — Bundled signature types for on-chain verification.
- [Proof](abi/Fdc2.md#proof) — On-chain proof structure.

### TEE Machine

- [TeeState](abi/TeeMachine.md#teestate) — TEE machine state encoding.
- [Attestation](abi/TeeMachine.md#attestation) — Attestation challenge struct.
- [TeeAttestation](abi/TeeMachine.md#teeattestation) — Attestation instruction message.
- [TeeMachineWithAttestationData](abi/TeeMachine.md#teemachinewithattestationdata) — Machine registration data.

### Payments

- [PaymentInstructionMessage](abi/Payment.md#paymentinstructionmessage) — Payment instruction for external chains.

### Attestation Types

- [TeeAvailabilityCheck.RequestBody](abi/AttestationType.md#requestbody) — Availability check request.
- [TeeAvailabilityCheck.ResponseBody](abi/AttestationType.md#responsebody) — Availability check response.
- [PMWPaymentStatus.RequestBody](abi/AttestationType.md#requestbody-1) — Payment status request.
- [PMWPaymentStatus.ResponseBody](abi/AttestationType.md#responsebody-1) — Payment status response.
- [PMWFeeProof.RequestBody](abi/AttestationType.md#requestbody-2) — Fee proof request.
- [PMWFeeProof.ResponseBody](abi/AttestationType.md#responsebody-2) — Fee proof response.
- [PMWMultisigAccountConfigured.RequestBody](abi/AttestationType.md#requestbody-3) — Multisig account configuration request.
- [PMWMultisigAccountConfigured.ResponseBody](abi/AttestationType.md#responsebody-3) — Multisig account configuration response.

### Events

Smart contract events, organized by contract: [Events index](abi/Events/index.md).

---

## Wire Types

### Common

- [PublicKey](wire/Common.md#publickey) — Public key JSON object (same structure as ABI).
- [Signature](wire/Common.md#signature) — ECDSA signature as $65$-byte hex blob ($r \mathbin\| s \mathbin\| v$).

### TEE Machine

- [TeeInfoRequest](wire/TeeMachine.md#teeinforequest) — Direct action requesting TEE info.
- [TeeInfoResponse](wire/TeeMachine.md#teeinforesponse) — TEE info action result.
- [TeeInfo](wire/TeeMachine.md#teeinfo) — TEE attestation information.
- [TeeState](wire/TeeMachine.md#teestate) — TEE machine state.
- [MachineData](wire/TeeMachine.md#machinedata) — Machine registration data.

### Key Management

- [SignedKeyExistenceProof](wire/Key.md#signedkeyexistenceproof) — ABI-encoded KeyExistence wrapped with TEE signature.
- [KeyData](wire/Key.md#signedkeyexistenceproof) — Decoded key data with raw proof.
- [KeyIDPair](wire/Key.md#keyidpair) — Wallet and key ID pair.
- [WalletBackupID](wire/Key.md#walletbackupid) — Key backup identifier (wire form).

### FDC2

- [ProveResponse](wire/Fdc2.md#proveresponse) — Action result for `PROVE` command.
