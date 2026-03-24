# Component Architecture

This section documents the internal architecture of the main FlareTEE software components. Each document covers the component's modules, data flow, and key interfaces.

## Components

| Component | Description |
|-----------|-------------|
| [TEE Node](tee-node.md) | Runs inside the Trusted Execution Environment. Manages wallet keys, cryptographic operations, signing-policy validation, and action execution. |
| [TEE Proxy](tee-proxy.md) | Controls access to the TEE node. Manages instruction voting, action queuing, result storage, signing-policy synchronization, and key backups. |
| [FDC2 Verifier Server](fdc2-verifier.md) | FDC2 verifier server that validates attestation requests. Each attestation type is loaded as a module with its own verification logic. |
| [Relay Client](tee-relay-client.md) | Bridges the Flare blockchain and TEE proxy nodes. Monitors C-chain events, processes instructions by type, and relays signed instructions to TEE proxies. |
