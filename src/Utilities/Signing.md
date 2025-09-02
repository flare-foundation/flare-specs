## Signing

The signing process for a `message` by an entity with `signingPolicyAddress` is as follows:
1. Hash the `message` using `keccak256`.
2. Prepend the hash with the string `"\x19Ethereum Signed Message:\n32"`, converted to bytes using UTF-8 encoding (where `\x19` becomes 0x19 and `\n` becomes 0x0A).
3. Hash the prepended result again with `keccak256` (this prepending and hashing is implemented in the go-ethereum `TextAndHash` function).
4. Sign the final hash using the `signingPolicyAddress` with ECDSA, producing a signature that is the concatenation of:
    - v (1 byte) - expected to be 27 or 28 in decimal
    - r (32 bytes)
    - s (32 bytes)

See [flare-system-client](https://github.com/flare-foundation/flare-system-client/blob/main/client/epoch/system_manager_utils.go#L107-L116) for an example implementation in Go.