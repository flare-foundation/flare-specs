# Architecture

![Architecture overview](Images/architecture-overview.svg)

## System Components

1. **Smart contracts**: Govern extension management, TEE machine registration and attestation, [instruction](Operations/Instructions.md) issuance, and private key administration on the Flare blockchain.

2. **[Data providers](../Terminology/Roles.md#data-provider) and [cosigners](../Terminology/Roles.md#cosigner)**: Each run a [relay client](Operations/RelayClient.md) that monitors the Flare C-chain for [instruction events](Operations/Instructions.md#instruction-events).
   The relay client signs each instruction with its operator's private key and forwards it to the relevant [TEE proxies](TeeManagement/TeeProxy.md).
   For certain operations (such as FDC2 attestations and key restores), the relay client also [augments](Operations/RelayClient.md#instruction-augmentation) the instruction with off-chain data before signing.
   Data providers may relay any instruction under the current signing policy; cosigners may only relay instructions in which their address appears in the `cosigners` list.

3. **TEE machines**: Receive [actions](Operations/Actions.md) derived from relayed instructions or [direct instructions](Operations/Instructions.md#direct-instructions).
   For relayed instructions, the TEE proxy aggregates signatures from data providers until the [voting](Operations/Voting.md) threshold defined by the current signing policy is met, then queues the resulting action for execution.
   If the instruction specifies cosigners, a separate cosigner threshold must also be reached.
   Upon processing an action, the TEE machine signs the result with a relevant private key (either the machine's identity key or a key held on the machine, as described in [Key Management](TeeManagement/KeyManagement.md)) and returns it to the [TEE proxy](TeeManagement/TeeProxy.md).
   Results may include signed transactions for external blockchains, signed attestations, or other operation-specific outputs.
   See [Actions](Operations/Actions.md) for the action structure.

## Deployment Topology

![Deployment topology](Images/deployment-topology.svg)

Each [TEE operator](../Terminology/Roles.md#tee-operator) deploys the following infrastructure:

1. **TEE machine**: A confidential VM hosting the TEE node on a platform such as Google Confidential Compute.
   When a custom [extension](Extensions/Overview.md) is deployed, a separate extension app runs alongside the node app within the same VM, communicating over a local HTTP interface.

2. **TEE proxy**: A proxy server managing instruction [voting](Operations/Voting.md), action queues, and API access.
   See [TEE Proxy](TeeManagement/TeeProxy.md) for details.

3. **C-chain indexer**: A database-backed indexer used by the TEE proxy to track signing policy updates.

4. **REDIS**: Persistent storage for proxy state including voting processes, action queues, and key data.

## Trust Model

### Best-Effort Relay

The relay layer is _best effort_: delivery and ordering are not guaranteed.
Instructions may arrive duplicated or out of order.

1. **Default replayability**: The system does not enforce a global nonce.
   Any instruction can be relayed to a TEE machine multiple times.

2. **State-changing operations**: Commands that alter TEE state (e.g., key deletion, key restoration, or stateful custom [extension](Extensions/Overview.md) operations) must implement replay protection internally (e.g., via nonces).

### TEE Isolation

1. **Untrusted proxies**: The [TEE proxy](TeeManagement/TeeProxy.md) is considered untrusted.
   The TEE machine independently verifies that each instruction carries sufficient data provider and cosigner signatures before executing it.
   A malicious proxy can censor, delay, or flood the processing queue, but cannot cause unauthorized execution.

2. **Consensus-based verification**: The TEE machine does not query blockchain nodes directly.
   It relies entirely on the consensus of data providers to learn about on-chain events.
