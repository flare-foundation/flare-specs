# Trust Model

The integrity of FCC rests on a small number of explicit assumptions about what can and cannot be trusted to behave correctly.

## Honest-Majority Assumption

Within any given [signing policy](../../FSP/SigningPolicy.md), malicious actors hold strictly less than the threshold weight needed to pass a vote.
Signed-instruction execution, attestation proofs, and signing-policy updates all rely on this — if a colluding super-threshold of data providers exists, they can pass arbitrary instructions, including ones that strip per-instruction safeguards such as the `cosigners` field; extensions that want defense in depth re-enforce cosigner thresholds at the TEE-machine layer (see [Cosigner Enforcement](../Reference/Components/Machine.md#cosigner-enforcement)).

## TEE Platform Trust

FCC trusts the TEE platform operator (Google for Intel TDX and AMD SEV) and its attestation chain to:

- bind the on-chain `codeHash` to the actual code running inside the enclave.
- enforce enclave isolation so the TEE secret key never leaves the hardware.

A platform compromise — leaked attestation signing keys, broken hardware isolation — collapses the spec's guarantees regardless of any on-chain controls.

## Untrusted Proxy

The [TEE proxy](../Reference/Components/Proxy.md) is considered untrusted.
The TEE machine independently verifies that each instruction carries sufficient data provider and cosigner signatures before executing it.
A malicious proxy can censor, delay, or flood the processing queue, but cannot cause unauthorized execution.

## No Direct Chain Reads

The TEE machine does not query blockchain nodes directly.
It relies entirely on the consensus of data providers to learn about on-chain events.

## Delivery and Replay Semantics

[Relay clients](../Reference/Components/RelayClient.md) deliver instructions _best effort_: delivery and ordering are not guaranteed; instructions may arrive duplicated or out of order.
The system does not enforce a global nonce, so any instruction can be relayed to a TEE machine multiple times.
Operations that alter TEE state — e.g. key deletion, key restoration, or stateful custom [extension](../FCE/README.md) operations — must define their own replay protection (typically a per-operation nonce that the TEE machine tracks).
