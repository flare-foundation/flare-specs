# F_GET TEE_INFO

## Description

Calculates TEE attestation for a given challenge and returns the attestation result. This is a direct [action](../Actions.md) triggered by the [TEE proxy](../Tee%20Proxies.md) without any signatures.

## Action message

```go
// Source: tee-node/pkg/types/tee.go
type TeeInfoRequest struct {
    Challenge common.Hash // random number selected by proxy; to follow the protocol this must be
                          // the hash of one of the recent blocks of the blockchain where the TEE
                          // package is registered
}
```

## Action result

```go
// Source: tee-node/pkg/types/tee.go
type TeeInfoResponse struct {
    TeeInfo       TeeInfo       `json:"teeInfo"`       // TEE attestation information
    MachineData   MachineData   `json:"machineData"`   // machine registration data
    DataSignature hexutil.Bytes `json:"dataSignature"` // ECDSA signature of keccak256(ABI(machineData))
    Attestation   hexutil.Bytes `json:"attestation"`   // platform attestation data (binary or JWT)
}

type TeeInfo struct {
    Challenge                common.Hash `json:"challenge"`                // challenge used for attestation
    PublicKey                PublicKey   `json:"publicKey"`                // identity public key
    InitialSigningPolicyID   uint32      `json:"initialSigningPolicyId"`   // initial signing policy id (never changes)
    InitialSigningPolicyHash common.Hash `json:"initialSigningPolicyHash"` // initial signing policy hash
    LastSigningPolicyID      uint32      `json:"lastSigningPolicyId"`      // last signing policy id
    LastSigningPolicyHash    common.Hash `json:"lastSigningPolicyHash"`    // last signing policy hash
    State                    TeeState    `json:"state"`                    // TEE machine state (ABI encoded)
    TeeTimestamp             uint64      `json:"teeTimestamp"`             // local TEE machine timestamp
}

type MachineData struct {
    ExtensionID  common.Hash    `json:"extensionId"`  // extension id the TEE belongs to
    InitialOwner common.Address `json:"initialOwner"` // address of initial owner
    CodeHash     common.Hash    `json:"codeHash"`     // digest of code running in TEE
    Platform     common.Hash    `json:"platform"`     // platform identifier
    PublicKey    PublicKey      `json:"publicKey"`     // identity public key (x, y)
}

type PublicKey struct {
    X common.Hash `json:"x"` // x coordinate
    Y common.Hash `json:"y"` // y coordinate
}

type TeeState struct {
    SystemState        hexutil.Bytes `json:"systemState"`        // system state bytes
    SystemStateVersion common.Hash   `json:"systemStateVersion"` // system state version hash
    State              hexutil.Bytes `json:"state"`              // application state bytes
    StateVersion       common.Hash   `json:"stateVersion"`       // application state version hash
}
```

**Proxy result hook:** Proxy stores the latest deserialized action result.
