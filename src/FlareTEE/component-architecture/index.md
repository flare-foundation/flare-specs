# Component Architecture

This section documents the internal architecture of the main FlareTEE software components. Each document covers the component's modules, data flow, and key interfaces.

## Components

| Component | Description |
|-----------|-------------|
| [TEE Proxy](tee-proxy.md) | Controls access to the TEE node. Manages instruction voting, action queuing, result storage, signing-policy synchronization, and key backups. |
| [Relay Client](tee-relay-client.md) | Bridges the Flare blockchain and TEE proxy nodes. Monitors C-chain events, processes instructions by type, and relays signed instructions to TEE proxies. |
