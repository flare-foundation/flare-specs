# Submission

Subprotocols use the Submission smart contract for messaging.
Submission contract has methods submit1, submit2, (submit3,) and submitSignatures.

The messages are used by entities for the off chain computation in protocols and rewarding.

## Submit1, submit2

Entities post messages to these functions from submitAddress.
The first submission in a voting round to a method from the submitAddress of an entity included in the active signing policy is subsidized (all the gas cost is refunded).
Only the messages from the submitSignatureAddress of an entity included in the active signing policy should be considered in the protocols.

The message is formed in the following way:
`tx_data = function_selector + concatenated_data`.

The concatenated data is a sequence of concatenated payload messages, where each payload message is of the form:

- protocolId (1 byte) - protocol ID
- votingRoundId (4 bytes) - ID of the voting round
- size (2 bytes) - number of bytes in the payload
- payload (size bytes) - protocol specific data encoded into bytes.
  Payload is formatted and should be encoded according to the specification of the protocol with protocolID.

Payload messages are used in protocols and to decide rewards eligibility

## SubmitSignatures

Signatures are used for a finalization of a voting round for a protocol.
For a [finalization](../Finalization.md), a Merkle root backed by the signatures of enough voter weight is required.

Entities post messages to the function from submitSignaturesAddress.
The first submission in a voting round to a function from the submitSignatureAddress of an entity included in the active signing policy is subsidized (all the gas cost is refunded).
Only the messages from the submitSignatureAddress of an entity included in the active signing policy should be considered in the protocols.
The message is formed in the following way:
`tx_data = function_selector + concatenated_data`.

The concatenated data is a sequence of concatenated signature payload messages, where each signature payload message is of the form:

- protocolId (1 byte) - protocol id.
- votingRoundId (4 bytes) - id of the voting round
  The protocol specifies which version is required.
- size (2 bytes) - number of bytes in the signaturePayload
- signaturePayload (size bytes) - protocol specific signatures needed for finalization.
  The protocol specifies which version is required.

### Signature payload

The signaturePayload is of the form

- type (1 byte) - Defines both type of message and signature.
- payloadMessage - Defined by type

#### Signing

Currently both types sign a message of the same form and use the same signature scheme.
The message that is signed is of the form:
message (38 bytes):

- protocolId (1 byte)
- votingRoundId (4 bytes)
- randomQualityScore (1 byte)
- merkleRoot (32 bytes)

Signing is done with the following steps:

1. The message is hashed with keccak256.
2. The hash is prepended with string
   `"\x19Ethereum Signed Message:\n32"`
   converted to bytes according to utf-8 encoding (note that `\x19` is converted to 0x19, `\n` is converted to 0x10).
3. The prepended hash is than hashed again with keccak256 (the prepending and hashing is implemented in go-ethereum function TextAndHash).
4. The last hash is signed by signingPolicyAddress using ECDSA producing a signature which is concatenation of
   - v (1 byte) - exacted to be $27$ or $28$ in decimal.
   - r (32 bytes)
   - s (32 bytes)

#### Type 0

PayloadMessage of type 0 includes message, its signature, and potentially an additional unsigned message.

- message (38 bytes)
- signature (65 bytes)
- unsignedMessage (unsignedMessageSize bytes) - additional protocol specific data.
  While type defines the length of message and signature, the unsignedMessage occupies the rest of the bytes.
  Since this payload is then packed into a payload message (see above) the payload is easily extractable.

Currently, type 0 is used for FTSO (protocol ID 100)

#### Type 1

PayloadMessage of type 1 consists of the signature of the message, and potentially an additional unsigned message but does not include the actual message.

- signature (65 bytes)
- unsignedMessage (unsignedMessageSize bytes) - additional protocol specific data. In FDC, this is a consensus bit vector.
  While type defines the length of message and signature, the unsignedMessage occupies the rest of the bytes.
  Since this payload is then packed into a payload message (see above) the unsignedMessage is easily extractable.

Currently, type 1 is used for FDC (protocol ID 200)
