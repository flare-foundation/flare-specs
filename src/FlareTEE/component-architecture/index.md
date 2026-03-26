# Component Architecture

This section documents the internal architecture of the main FlareTEE software components.
These pages describe the current implementation and support the consolidated specification, but they are not the canonical owners of protocol semantics.
Each document covers the component's modules, data flow, and key interfaces.

## Components

| Component | Description |
|-----------|-------------|
| [TEE Proxy](tee-proxy.md) | Controls access to the TEE node. Manages instruction voting, action queuing, result storage, signing-policy synchronization, and key backups. |
