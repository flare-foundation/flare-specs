# Signing

Given a 32-byte input `h` and a secp256k1 private key `privKey`, the signature is

$$
\mathrm{ECDSA}(\mathrm{keccak256}(\mathrm{prefix} \,\|\, h),\ \mathrm{privKey}),
$$

where $\mathrm{prefix}$ is the byte sequence `\x19Ethereum Signed Message:\n32` (`\x19` is `0x19`, `\n` is `0x0A`; the rest is ASCII).
This is [EIP-191](https://eips.ethereum.org/EIPS/eip-191) with version byte `0x45`.

In Flare protocols, `h` is always the keccak256 digest of the underlying message.

## Encoding Conventions

The signature has three components — a 32-byte $r$, a 32-byte $s$, and a 1-byte recovery ID $v$ — packaged in one of three conventions depending on context:

- **Off-chain** — every signature produced or consumed off-chain (HTTP payloads, file artifacts, persistent off-chain state) is the 65-byte concatenation $r \,\|\, s \,\|\, v$ with $v \in \{0, 1\}$.
- **On-chain struct** — every signature consumed on-chain as a Solidity tuple is `{v, r, s}` with $v \in \{27, 28\}$.
- **On-chain packed wire format** — several FSP-defined formats pack the same components into raw `bytes` for cheap calldata parsing:
  - FSP [`SignatureType0`](../FSP/Encoding.md#signaturetype0) (deprecated) and [`SignatureType1`](../FSP/Encoding.md#signaturetype1) — submission payloads, each wrapping a single 65-byte ECDSA signature inside a [`PayloadMessage`](../FSP/Encoding.md#payloadmessage).
  - FSP [`ECDSASignatureWithIndex`](../FSP/Encoding.md#ecdsasignaturewithindex) — 67-byte $v \,\|\, r \,\|\, s \,\|\, \mathit{signerIndex}$ entry, used by the `Relay` contract in finalization payloads and embedded in FDC2 [`Fdc2Signatures.signingPolicySignatures`](../FCC/FDC2/Reference/Types/Abi/Fdc2.md#fdc2signatures).

Off-chain ↔ on-chain-struct conversion at the boundary is trivial: $r$ and $s$ are identical; $v_{\mathrm{onchain}} = v_{\mathrm{offchain}} + 27$.
