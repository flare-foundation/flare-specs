# Architecture

![Architecture overview](Images/architecture-overview.svg)

## System Components

1. **Smart contracts**: Govern extension management, TEE machine registration and attestation, [instruction](Concepts/Instructions.md) issuance, and private key administration on the Flare blockchain.

2. **[Data providers](../Terminology/Roles.md#data-provider) and [cosigners](Concepts/Instructions.md#cosigners)**: Each run a [relay client](Reference/Components/RelayClient.md) that monitors the Flare C-chain for [instruction events](Concepts/Instructions.md#sending-instructions).
   The relay client signs each instruction with its operator's private key and forwards it to the destination [TEE proxies](Reference/Components/Proxy.md).
   For certain operations (such as FDC2 attestations and key restores), the relay client also [augments](Reference/Components/RelayClient.md#instruction-augmentation) the instruction with off-chain data before signing.
   Data providers may relay any instruction under the current signing policy; cosigners may only relay instructions in which their address appears in the `cosigners` list.

3. **TEE machines**: Receive [actions](Concepts/Actions.md) derived from relayed instructions or [direct actions](Concepts/Actions.md#direct-actions).
   For relayed instructions, the TEE proxy aggregates signatures from data providers until the [voting](Concepts/Voting.md) threshold defined by the current signing policy is met, then queues the resulting action for execution.
   If the instruction specifies cosigners, a separate cosigner threshold must also be reached.
   Upon processing an action, the TEE machine signs the result with either its identity key or a key held on the machine (see [Key Management](Concepts/Keys.md)) and returns it to the [TEE proxy](Reference/Components/Proxy.md).
   Results may include signed transactions for external blockchains, signed attestations, or other operation-specific outputs.
   See [Actions](Concepts/Actions.md) for the action structure.

## Deployment Topology

![Deployment topology](Images/deployment-topology.svg)

Each [TEE operator](../Terminology/Roles.md#tee-operator) deploys the following infrastructure:

1. **TEE machine**: A confidential VM hosting the TEE node on a platform such as Google Confidential Compute.
   When a custom [extension](FCE/README.md) is deployed, a separate extension app runs alongside the node app within the same VM, communicating over a local HTTP interface.

2. **TEE proxy**: A proxy server managing instruction [voting](Concepts/Voting.md), action queues, and API access.
   See [TEE Proxy](Reference/Components/Proxy.md) for details.

3. **C-chain indexer**: A database-backed indexer used by the TEE proxy to track signing policy updates.

4. **Key-value store with queues**: Persistent backing for the proxy's [stores](Reference/Components/Proxy.md#persistent-stores) (Redis in the reference deployment).

## Trust Model

### Delivery and Replay Semantics

[Relay clients](Reference/Components/RelayClient.md) deliver instructions _best effort_: delivery and ordering are not guaranteed; instructions may arrive duplicated or out of order.
The system does not enforce a global nonce, so any instruction can be relayed to a TEE machine multiple times.
Commands that alter TEE state — e.g. key deletion, key restoration, or stateful custom [extension](FCE/README.md) operations — must define their own replay protection (typically a per-command nonce that the TEE machine tracks).

### Untrusted Proxy

The [TEE proxy](Reference/Components/Proxy.md) is considered untrusted.
The TEE machine independently verifies that each instruction carries sufficient data provider and cosigner signatures before executing it.
A malicious proxy can censor, delay, or flood the processing queue, but cannot cause unauthorized execution.

### No Direct Chain Reads

The TEE machine does not query blockchain nodes directly.
It relies entirely on the consensus of data providers to learn about on-chain events.
