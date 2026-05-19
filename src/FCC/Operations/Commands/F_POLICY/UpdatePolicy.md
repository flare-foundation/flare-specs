# F_POLICY UPDATE_POLICY

## Description

A direct action used to update the policy on the TEE machine. It is triggered by the TEE proxy, which obtains signed policies and signatures from the blockchain using the C-chain indexer.

## Action message

```go
type UpdatePolicyRequest struct {
    NewPolicy  MultiSignedPolicy // new policy with signatures
    PublicKeys []PublicKey        // public keys corresponding to the signing policy
                                 // addresses of data providers; order must match
                                 // the order of signers
}

type MultiSignedPolicy struct {
    PolicyBytes []byte   // bytes encoded signing policy as emitted in the
                         // SigningPolicyInitialized event
    Signatures  [][]byte // signatures of hash of signing policy; each formatted
                         // as [R | S | V] where V is 0 or 1; accumulated weight
                         // must reach threshold according to previous signing policy
}

type PublicKey struct {
    X common.Hash `json:"x"`
    Y common.Hash `json:"y"`
}
```

## Fixed message

/

## Variable message

/

## Additional action data

/

## Action result

/
