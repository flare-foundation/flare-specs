# FSP Message Encoding Reference

## PayloadMessage

| **Field**     | **Size (bytes)** | **Description**                    |
| ------------- | ---------------- | ---------------------------------- |
| ProtocolId    | 1                | Protocol identifier.               |
| RoundId       | 4                | Round ID (big-endian).             |
| PayloadLength | 2                | Number of bytes in the payload     |
| Payload       | PayloadLength    | Encoded protocol-specific message. |

## ProtocolMerkleRoot
Contains the resulting data of a voting round, encoded into a Merkle tree root hash.

| **Field**    | **Size (bytes)** | **Description**                |
| ------------ | ---------------- | ------------------------------ |
| ProtocolId   | 1                | Protocol identifier.           |
| RoundId      | 4                | Round ID (big-endian).         |
| SecureRandom | 1                | Boolean (1 = true, 0 = false). |
| Hash         | 32               | Merkle root hash.              |

## Finalization

| **Field**                                 | **Size (bytes)**    | **Description**                                                                                                |
| ----------------------------------------- | ------------------- | -------------------------------------------------------------------------------------------------------------- |
| SigningPolicy                             | Variable            | Encoded signing policy.                                                                                        |
| ProtocolId                                | 1                   | Protocol identifier.                                                                                           |
| [ProtocolMerkleRoot](#protocolmerkleroot) | 38                  |                                                                                                                |
| SignatureCount                            | 2                   | Number of signatures (big-endian).                                                                             |
| Signatures                                | SignatureCount * 67 | Concatenated array of [ECDSASignatureWithIndex](#ecdsasignaturewithindex). Indices must be in ascending order. |

## SignatureType0

| **Field**                                 | **Size (bytes)** | **Description**                    |
| ----------------------------------------- | ---------------- | ---------------------------------- |
| Type                                      | 1                | Always `0`.                        |
| [ProtocolMerkleRoot](#protocolmerkleroot) | 38               |                                    |
| Signature                                 | 65               | ECDSA signature.                   |
| UnsignedMessage                           | Variable         | Additional protocol specific data. |

## SignatureType1

| **Field**       | **Size (bytes)** | **Description**                    |
| --------------- | ---------------- | ---------------------------------- |
| Type            | 1                | Always `1`.                        |
| Signature       | 65               | ECDSA signature.                   |
| UnsignedMessage | Variable         | Additional protocol specific data. |

## ECDSASignatureWithIndex

| **Field**   | **Size (bytes)** | **Description**                                    |
| ----------- | ---------------- | -------------------------------------------------- |
| `v`         | 1                | Adjusted by subtracting `27`.                      |
| `r`         | 32               | ECDSA `r` value.                                   |
| `s`         | 32               | ECDSA `s` value.                                   |
| SignerIndex | 2                | Index of the signer address in the signing policy. |

## SigningPolicy

| **Field**       | **Size (bytes)** | **Description**                                               |
| --------------- | ---------------- | ------------------------------------------------------------- |
| SignerCount     | 2                | Number of signers in the policy.                              |
| RewardEpochId   | 3                | Reward epoch identifier.                                      |
| StartingRoundId | 4                | Starting voting round ID (big-endian).                        |
| Threshold       | 2                | Minimum signing weight required for finalization.             |
| RandomSeed      | 32               | Used for randomizing the finalizer set selection for a round. |
| Signers         | SignerCount * 22 | Concatenated array of signers (see below).                    |

**Each signer entry:**

| **Field** | **Size (bytes)** | **Description** |
| --------- | ---------------- | --------------- |
| Address   | 20               | Signer address. |
| Weight    | 2                | Signer weight.  |
