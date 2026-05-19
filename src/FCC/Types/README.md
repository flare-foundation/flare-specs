# Types

Data structures used across the FCC specification, organized into two categories:

- **[ABI types](Abi/)** — Solidity struct definitions used for ABI encoding, hash computation, and on-chain verification.
- **[Wire types](Wire/)** — JSON types as communicated over HTTP between TEE components (proxy APIs, TEE node actions).

Both categories are documented as JSON schemas; see [Format Glossary](Glossary.md) for the custom `format` values used in those schemas and their JSON wire representations.
Where a type appears in both contexts, the ABI page defines the canonical struct and the wire page documents any differences in representation or wrapping.

## ABI Types

### Common

- [PublicKey](Abi/Common.md#publickey) — Elliptic curve public key $(x, y)$ coordinates.
- [Signature](Abi/Common.md#signature) — ECDSA signature $(v, r, s)$ components (on-chain form).
- [TeeIdKeyIdPair](Abi/Common.md#teeidkeyidpair) — Associates a TEE machine with a key ID.

### Instructions

- [TeeInstruction](Abi/Instruction.md#teeinstruction) — Signed instruction data, ABI-encoded for `instructionHash`.

### Voting

- [VoteSequenceInit](Abi/Voting.md#votesequenceinit) — Initial vote hash struct.
- [VoteSequenceNext](Abi/Voting.md#votesequencenext) — Subsequent vote hash struct.
- [VoteReceipt](Abi/Voting.md#votereceipt) — Vote receipt struct.

### Key Management

- [KeyGenerate](Abi/Key.md#keygenerate) — Key generation instruction message.
- [KeyConfigConstants](Abi/Key.md#keyconfigconstants) — Immutable wallet configuration constants.
- [KeyExistence](Abi/Key.md#keyexistence) — Proof of key existence (ABI-encoded; see [wire form](Wire/Key.md#signedkeyexistenceproof)).
- [KeyDelete](Abi/Key.md#keydelete) — Key deletion instruction message.
- [BackupId](Abi/Key.md#backupid) — Key backup identifier.
- [VrfInstructionMessage](Abi/Key.md#vrfinstructionmessage) — VRF proof generation instruction.

### FDC2

- [Fdc2AttestationRequest](Abi/Fdc2.md#fdc2attestationrequest) — Attestation request wrapper.
- [Fdc2RequestHeader](Abi/Fdc2.md#fdc2requestheader) — Request header.
- [Fdc2ResponseHeader](Abi/Fdc2.md#fdc2responseheader) — Response header.
- [Fdc2Signatures](Abi/Fdc2.md#fdc2signatures) — Bundled signature types for on-chain verification.
- [Proof](Abi/Fdc2.md#proof) — On-chain proof structure.

### TEE Machine

- [TeeMachine](Abi/TeeMachine.md#teemachine) — Destination record carried in the `TeeInstructionsSent` event's `teeMachines` field.
- [TeeState](Abi/TeeMachine.md#teestate) — TEE machine state encoding.
- [Attestation](Abi/TeeMachine.md#attestation) — Attestation challenge struct.
- [TeeAttestation](Abi/TeeMachine.md#teeattestation) — Attestation instruction message.
- [TeeMachineWithAttestationData](Abi/TeeMachine.md#teemachinewithattestationdata) — Machine registration data.

### Payments

- [PaymentInstructionMessage](Abi/Payment.md#paymentinstructionmessage) — Payment instruction for external chains.

### Attestation Types

- [TeeAvailabilityCheck.RequestBody](Abi/AttestationType.md#requestbody) — Availability check request.
- [TeeAvailabilityCheck.AvailabilityCheckStatus](Abi/AttestationType.md#availabilitycheckstatus) — Availability check status enum.
- [TeeAvailabilityCheck.ResponseBody](Abi/AttestationType.md#responsebody) — Availability check response.
- [PMWPaymentStatus.RequestBody](Abi/AttestationType.md#requestbody-1) — Payment status request.
- [PMWPaymentStatus.ResponseBody](Abi/AttestationType.md#responsebody-1) — Payment status response.
- [PMWFeeProof.RequestBody](Abi/AttestationType.md#requestbody-2) — Fee proof request.
- [PMWFeeProof.ResponseBody](Abi/AttestationType.md#responsebody-2) — Fee proof response.
- [PMWMultisigAccountConfigured.RequestBody](Abi/AttestationType.md#requestbody-3) — Multisig account configuration request.
- [PMWMultisigAccountConfigured.PMWMultisigAccountStatus](Abi/AttestationType.md#pmwmultisigaccountstatus) — Multisig account status enum.
- [PMWMultisigAccountConfigured.ResponseBody](Abi/AttestationType.md#responsebody-3) — Multisig account configuration response.

### Events

Smart contract events, organized by contract: [Events index](Abi/Events/README.md).

## Wire Types

### Common

- [PublicKey](Wire/Common.md#publickey) — Public key JSON object (same structure as ABI).
- [Signature](Wire/Common.md#signature) — ECDSA signature as $65$-byte hex blob ($r \mathbin\| s \mathbin\| v$).

### Instructions

- [Instruction](Wire/Instruction.md#instruction) — Signed instruction envelope posted at `POST /instruction`.
- [Data](Wire/Instruction.md#data) — Instruction payload: `TeeInstruction` fields plus `additionalVariableMessage`.
- [DirectInstruction](Wire/Instruction.md#directinstruction) — Payload submitted at `POST /direct` to create a [direct action](../Operations/Actions.md#direct-actions).

### Actions

- [Action](Wire/Action.md#action) — Body served by the proxy on `POST /queue/{queueID}`.
- [ActionData](Wire/Action.md#actiondata) — Sub-struct of `Action`.
- [ActionResponse](Wire/Action.md#actionresponse) — TEE machine's response posted to the proxy.
- [ActionResult](Wire/Action.md#actionresult) — Sub-struct of `ActionResponse`.
- [RewardingData](Wire/Action.md#rewardingdata) — Marshalled into `ActionResult.data` for `end` results.
- [VoteSequence](Wire/Action.md#votesequence) — Reward-attribution state for the carrying instruction.

### TEE Machine

- [TeeInfoRequest](Wire/TeeMachine.md#teeinforequest) — Direct action requesting TEE info.
- [TeeInfoResponse](Wire/TeeMachine.md#teeinforesponse) — TEE info action result.
- [TeeInfo](Wire/TeeMachine.md#teeinfo) — TEE attestation information.
- [TeeState](Wire/TeeMachine.md#teestate) — TEE machine state.
- [MachineData](Wire/TeeMachine.md#machinedata) — Machine registration data.

### Key Management

- [SignedKeyExistenceProof](Wire/Key.md#signedkeyexistenceproof) — ABI-encoded `KeyExistence` wrapped with TEE signature.
- [KeyIDPair](Wire/Key.md#keyidpair) — Wallet and key ID pair.
- [WalletBackupID](Wire/Key.md#walletbackupid) — Key backup identifier (wire form).

### FDC2

- [ProveResponse](Wire/Fdc2.md#proveresponse) — Action result for `PROVE` command.
