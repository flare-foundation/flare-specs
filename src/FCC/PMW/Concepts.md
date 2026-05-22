# PMW Concepts

A Protocol Managed Wallet (PMW) is an application on the [system extension](../FCE/System.md) that manages a wallet address on an external blockchain.
Wallet keys live inside [TEE machines](../Reference/Components/Machine.md) registered to the system extension; [data providers](../../Terminology/Roles.md#data-provider) bridge data between Flare, the TEE network, and the external chain.

## Wallet Ownership and Management

A PMW wallet corresponds to an address $W_C$ on an external blockchain $C$.
Its keys are held in TEE machines registered to the system extension, and the [project owner](../../Terminology/Roles.md#project-owner) submits transactions on $C$ by issuing instructions on Flare.
For the on-chain data model — projects, wallets, admins, cosigners, multisig thresholds, and the wallet lifecycle — see [Wallets](../TeeManagement/Wallets.md).

## Submitting Transactions

A PMW transaction is an [instruction](../Operations/Instructions.md) on the system extension:

1. The project owner submits a payment instruction on Flare, naming the TEE machines that hold the wallet's keys.
2. Each data provider builds and signs the corresponding instruction off-chain through its [relay client](../Reference/Components/RelayClient.md), then submits it to the targeted [TEE proxies](../Reference/Components/Proxy.md).
3. Once a TEE machine collects a sufficient weight of provider signatures, it signs the external-chain transaction with the wallet's key(s) and returns the result.
4. The signed transaction is served by the TEE proxy and may be submitted on $C$ by any party.

See [Payments](Transactions.md) for the on-chain `pay` and `reissue` calls, [batching](Transactions.md#batching), and [fee schedules](Transactions.md#fee-schedules).

## Key Management and Backups

Wallet private keys never leave the TEEs' secure memory: transactions are sent to the TEEs to be signed, and PMW security follows from the combination of the TEE machines and the system-extension [voting process](../Operations/Voting.md).
To prevent keys from being lost when a TEE is paused, banned, or permanently disabled, keys are [backed up](../TeeManagement/Keys.md#key-backup) using a two-layer secret-sharing scheme, with shares distributed to data providers and [key admins](../../Terminology/Roles.md#key-admin) so that secrets are recoverable only under the configured threshold.
TEE machines additionally serve [`SignedKeyExistenceProof`](../Reference/Types/Wire/Key.md#signedkeyexistenceproof) values that confirm the corresponding private keys still exist on the machine.

## Functionality

1. **Multisig account operations**: A wallet's key set across TEE machines can act as the signers of a native multisig account on the external chain (e.g. XRPL `SignerList`), giving $k$-of-$n$ control.
2. **Nonce management**: each payment instruction is bound to a specific transaction sequence number on $C$, so retries and reissues never double-spend.
3. **Reissue and nullification**: a stuck transaction can be re-signed with a higher fee, or its nonce consumed by a trivial `AccountSet` transaction (see [Nullification](Transactions.md#nullification)).
4. **Transaction-status proofs**: once a nonce is consumed, an FDC2 [`PMWPaymentStatus`](../FDC2/Reference/AttestationTypes/PMWPaymentStatus.md) attestation reports the outcome on-chain, letting protocols branch on success or revert.

> **Note:** BTC and EVM support is planned but not yet implemented.
