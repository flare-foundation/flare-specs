## Signing

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