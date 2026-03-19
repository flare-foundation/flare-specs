# F_POLICY INITIALIZE_POLICY

## Description

A direct instruction used to initialize the signing policy on the TEE machine. This instruction is triggered by the TEE proxy on initialization, which typically obtains the current signing policy from the blockchain using the C-chain indexer.

## Action message

```go
// Source: tee-node/pkg/types/policy.go
type InitializePolicyRequest struct {
    InitialPolicyBytes []byte    // bytes encoded signing policy as emitted in the
                                 // SigningPolicyInitialized event
    PublicKeys         []PublicKey // public keys corresponding to the signing policy
                                 // addresses of data providers; order must match
                                 // the order of signers
}

type PublicKey struct {
    X common.Hash `json:"x"`
    Y common.Hash `json:"y"`
}
```

## Action result

/
