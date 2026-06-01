# Trust Model

FCC's integrity rests on a small number of explicit assumptions about what can and cannot be trusted.

## Honest-Majority Assumption

Within any given [signing policy](../../FSP/SigningPolicy.md), malicious actors hold strictly less than the threshold weight needed to pass a vote.
A super-threshold of colluding data providers could pass arbitrary instructions, including ones with stripped or rewritten `cosigners` fields.
Wallet-key operations are protected regardless: [cosigner enforcement](../Reference/Components/Machine.md#cosigner-enforcement) inside the TEE machine binds each action against the cosigner set committed at key generation, catching mismatches from any path — colluding majority, malicious [proxy](#untrusted-proxy), or buggy instructions-sender contract.

## TEE Platform Trust

FCC trusts the TEE platform operator (Google for Intel TDX and AMD SEV) and its attestation chain to:

- bind the on-chain `codeHash` to the actual code running inside the enclave.
- enforce enclave isolation so the TEE secret key is never exposed outside an attested enclave.

A platform compromise — leaked attestation signing keys, broken hardware isolation — collapses the spec's guarantees regardless of any on-chain controls.

## Untrusted Proxy

The [TEE proxy](../Reference/Components/Proxy.md) is untrusted: the TEE machine independently verifies signatures before executing any instruction.
A malicious proxy can censor, delay, or flood the queue, but cannot cause unauthorized execution.

## No Direct Chain Reads

The TEE machine does not query blockchain nodes directly; it learns about on-chain events only through the consensus of data providers.

## Delivery and Replay Semantics

[Relay clients](../Reference/Components/RelayClient.md) deliver instructions best-effort — duplicates and out-of-order arrivals are possible, and no global nonce protects against replay.
Operations that mutate TEE state (key deletion, key restoration, stateful custom [extension](../FCE/README.md) operations) must define their own replay protection — e.g. a per-operation nonce tracked by the machine.
