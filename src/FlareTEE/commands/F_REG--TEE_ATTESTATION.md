# F_REG TEE_ATTESTATION

## Description

Calculates TEE attestation for a given challenge and returns the attestation result. In terms of TEE machine processing it behaves exactly the same as the [TEE_INFO](F_GET--TEE_INFO.md) direct instruction.

## Event message

The instruction event is decoded into a `TeeAttestation` struct wrapping the machine data and challenge:

```solidity
// Source: ITeeVerification.sol
struct TeeAttestation {
    TeeMachineWithAttestationData teeMachine; // TEE machine data
    bytes32 challenge;                         // random challenge
}

// Source: ITeeMachineRegistry.sol
struct TeeMachineWithAttestationData {
    address teeId;        // TEE machine id
    address initialTeeId; // initial TEE machine id
    string url;           // TEE machine URL
    bytes32 codeHash;     // code hash of the TEE
    bytes32 platform;     // platform of the TEE
}
```

> **Note:** The command only produces a result on the `Threshold` submission tag. On the `End` submission tag, no result is returned.

## Fixed message

/

## Variable message

/

## Additional action data

/

## Action result

TEE attestation response as provided by the platform, serialized under the result message. The result structure is the same as [TEE_INFO](F_GET--TEE_INFO.md):

```go
// Source: tee-node/pkg/types/tee.go
type TeeInfoResponse struct {
    TeeInfo       TeeInfo       `json:"teeInfo"`
    MachineData   MachineData   `json:"machineData"`
    DataSignature hexutil.Bytes `json:"dataSignature"`
    Attestation   hexutil.Bytes `json:"attestation"`
}
```

See [TEE_INFO](F_GET--TEE_INFO.md) for full field descriptions.
