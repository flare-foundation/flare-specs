# Protocol Managed Wallets (PMW)

A Protocol Managed Wallet is an application running on Flare that manages a wallet address on an external blockchain.
Users submit transactions from that wallet by issuing an instruction on Flare Confidential Compute; the wallet's keys live in TEE machines registered to the [system extension](../SystemExtension.md), and Flare's [data providers](../../../Terminology/Roles.md#data-provider) bridge information between Flare, the TEE network, and the external chain.

| Page | Contents |
|---|---|
| [Concepts](Concepts.md) | Wallet ownership, transaction flow, key management and backups, multisig and nonce semantics. |
| [Transactions](Transactions.md) | Per-chain transaction encoding, fee scheduling, and reissue/nullification mechanics. |
| [Commands](Commands/README.md) | `F_XRP PAY` and `F_XRP REISSUE` command references. |
