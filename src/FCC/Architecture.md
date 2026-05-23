# Architecture

## Participants

![Architecture overview](Images/architecture-overview.svg)

FCC has three kinds of participants:

1. **Smart contracts on Flare** — govern extension management, TEE machine registration and attestation, [instruction](Concepts/Instructions.md) issuance, and private key administration.
2. **[Data providers](../Terminology/Roles.md#data-provider)** — off-chain operators that run a [relay client](Reference/Components/RelayClient.md): they observe [instruction events](Concepts/Instructions.md#sending-instructions) on the Flare C-chain, sign them under the current signing policy, and forward them to the destination [TEE proxies](Reference/Components/Proxy.md).
3. **TEE machines** — confidential VMs that execute [actions](Concepts/Actions.md) derived from relayed instructions or from [direct actions](Concepts/Actions.md#direct-actions), and sign the result with either their identity key or a wallet key (see [Keys](Concepts/Keys.md)).

## Instruction Flow

1. A user issues an [instruction event](Concepts/Instructions.md#sending-instructions) on the Flare C-chain.
2. Subscribed data providers sign the event and submit it to the destination [TEE proxy](Reference/Components/Proxy.md); if the instruction specifies [cosigners](Concepts/Instructions.md#cosigners), they sign and submit too.
   For some operations — FDC2 attestations, key restores — the relay client also [augments](Reference/Components/RelayClient.md#instruction-augmentation) the instruction with off-chain data before signing.
3. The TEE proxy aggregates signatures until the data-provider [voting threshold](Concepts/Voting.md) is reached (plus the cosigner threshold if applicable), then queues the action for the TEE machine.
4. The TEE machine executes the action and signs the result; the proxy serves the [action response](Concepts/Actions.md#action-responses) publicly, and it may be relayed back on-chain.

Action side effects depend on the operation: a PMW action signs a transaction on an external blockchain; a custom [extension](FCE/README.md) action can interact with any external service.
Some TEE deployments also accept [_direct actions_](Concepts/Actions.md#direct-actions) that bypass the on-chain flow entirely while still executing on the same TEE machines.

For the integrity assumptions this flow relies on, see [Trust Model](Concepts/TrustModel.md).

## Deployment Topology

![Deployment topology](Images/deployment-topology.svg)

Each [TEE operator](../Terminology/Roles.md#tee-operator) deploys:

1. **TEE machine** — a confidential VM hosting the TEE node on a platform such as Google Confidential Compute.
   When a custom [extension](FCE/README.md) is deployed, a separate extension app runs alongside the node app within the same VM, communicating over a local HTTP interface.
2. **TEE proxy** — a proxy server managing instruction [voting](Concepts/Voting.md), action queues, and API access. See [TEE Proxy](Reference/Components/Proxy.md) for details.
3. **C-chain indexer** — a database-backed indexer used by the TEE proxy to track signing policy updates.
4. **Key-value store with queues** — persistent backing for the proxy's [stores](Reference/Components/Proxy.md#persistent-stores) (e.g. Redis).
