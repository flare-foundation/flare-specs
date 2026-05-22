# Components

Off-chain participants in the FCC network.
Each [TEE operator](../../../Terminology/Roles.md#tee-operator) runs one TEE machine paired with one TEE proxy; each [data provider](../../../Terminology/Roles.md#data-provider) or [cosigner](../../Operations/Instructions.md#cosigners) runs a relay client.

| Page | Role |
|---|---|
| [TEE Machine](Machine.md) | The confidential VM that processes actions and signs results. |
| [TEE Proxy](Proxy.md) | The proxy server in front of the TEE machine; collects votes, queues actions, exposes the external API. |
| [Relay Client](RelayClient.md) | The client run by a data provider or cosigner that observes instruction events and submits signed instructions to proxies. |

For the on-chain hub these components interact with, see [`FlareTeeManager`](../../TeeManagement/FlareTeeManager.md) and the rest of [TEE Management](../../TeeManagement/README.md).
