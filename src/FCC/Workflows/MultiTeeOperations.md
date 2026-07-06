# MultiTeeOperations

A multi-TEE deployment runs $N$ independent instances of the single-TEE workflows in parallel, with synchronisation at a handful of points. This page does not redefine the per-machine state machines; instead it specifies the _composition rules_ that bind $N$ machine-, wallet-, and key-level state machines into one coherent application.

For canonical per-machine behaviour, follow the base workflows: [MachineRegistration](MachineRegistration.md), [WalletSetup](WalletSetup.md), [KeyAdd](KeyAdd.md), [KeyDelete](KeyDelete.md), [KeyRestore](KeyRestore.md), [XrplMultisigConfiguration](../../PMW/Workflows/XrplMultisigConfiguration.md), [XrpPayment](../../PMW/Workflows/XrpPayment.md). For the concepts, [Concepts/Machines](../Concepts/Machines.md), [Concepts/Wallets](../Concepts/Wallets.md), [Concepts/Keys](../Concepts/Keys.md).

## Preconditions

- The $N$ TEE machines that will participate share one `extensionId`.
- The wallet's `multisigThreshold` matches the intended signing quorum.
- The wallet's `adminsPublicKeys` / `adminsThreshold` and (where used) `cosigners` / `cosignersThreshold` are sized for the $N$-machine deployment, not a single-machine one.

## Composition Points

Each composition point is a synchronisation barrier across the per-machine workflows.

### CP-1: machine registration (parallel)

- **Base workflow per machine**: [MachineRegistration](MachineRegistration.md). Each machine reaches `PRODUCTION` independently.
- **Synchronisation**: none required between machines — registrations are independent.
- **Postcondition**: $N$ machines have status `PRODUCTION` and `extensionId = project.extensionId`.

### CP-2: wallet creation (once)

- **Base workflow**: [WalletSetup](WalletSetup.md), through `INITIALIZED`.
- **Synchronisation**: a single project owner runs this once; the resulting `walletId` is shared.
- **Postcondition**: `wallet.status = INITIALIZED`, `multisigThreshold` set to the intended quorum $k$, admins/cosigners sized for $N$.

### CP-3: key distribution (fan-out then fan-in)

- **Base workflow per machine**: [KeyAdd](KeyAdd.md). One `(walletId, keyId_i)` per machine $i \in \{1, …, N\}$.
- **Synchronisation**: confirmations may interleave in any order. The wallet stays in `INITIALIZED` until all desired `keyId_i` are `Confirmed` (or until at least `multisigThreshold` are, depending on whether the operator plans to add more keys later).
- **Postcondition**: at least $k$ keys exist in `Confirmed` state on chain, each pinned to one machine via `key.teeIds`.

### CP-4: wallet enable (once)

- Run `enableWallet` from [WalletSetup](WalletSetup.md).
- **Guard**: $\geq$ `multisigThreshold` confirmed keys exist (CP-3 postcondition).
- **Postcondition**: `wallet.status = PRODUCTION`.

### CP-5: external multisig binding (once)

- **Base workflow**: [XrplMultisigConfiguration](../../PMW/Workflows/XrplMultisigConfiguration.md).
- **Synchronisation**: the external signer set is built from the public keys produced at CP-3; the on-chain quorum must equal the wallet's `multisigThreshold`.
- **Postcondition**: external account is multisig-configured with the $N$ TEE-controlled keys.

### CP-6: payments (parallel sign, single submit)

- **Base workflow**: [XrpPayment](../../PMW/Workflows/XrpPayment.md). The `pay` call dispatches the same `F_XRP PAY` instruction to all $N$ machines (via `FlareTeeManager.receivingTeesAndKeys`).
- **Synchronisation**:
  - Each machine signs its share independently; results land in each machine's proxy.
  - The submitter collects $\geq$ `multisigThreshold` partial signatures from those proxies, assembles the multisigned transaction, and submits it once on the external chain.
- **Postcondition**: a single external transaction carries threshold signatures from distinct machines.

### CP-7: lifecycle (per machine, decoupled)

- **Base workflow per machine**: [MachineLifecycle](MachineLifecycle.md) — pause, suspend, resume, ban, ownership change. Each machine runs its own lifecycle state machine; the wallet remains healthy as long as $\geq$ `multisigThreshold` machines retain `PRODUCTION` and hold a `Confirmed` key.
- **Synchronisation**: when a machine becomes permanently unavailable, run [KeyRestore](KeyRestore.md) on a replacement before [KeyDelete](KeyDelete.md) on the failed one, so the in-service count never drops below `multisigThreshold`.

## Invariants

- Across CP-3 → CP-6, the count of `Confirmed` keys whose owning machine is in `PRODUCTION` is at least `multisigThreshold` whenever the wallet is in `PRODUCTION`.
- All participating machines share the wallet's `extensionId`.
- The external multisig quorum equals the wallet's `multisigThreshold` (CP-5 enforces this at setup; CP-7 must preserve it through restores).

## Terminal Composition

`Operational`: $N$ machines in `PRODUCTION`, $\geq k$ confirmed keys, wallet in `PRODUCTION`, external multisig bound. From here CP-6 (payments) and CP-7 (lifecycle) repeat indefinitely.

## Notes

- Recovery and decommissioning sequences should preserve the in-service signer count throughout the migration; never run `KeyDelete` before the replacement's `KeyRestore` has reached its `Confirmed` state.
- Each proxy is treated as an independent result source at CP-6; do not assume any shared state between proxies.
- For attestation-driven lifecycle transitions (pause-with-proof, confirm-availability), see [Fdc2Attestation](../../FDC2/Workflows/Fdc2Attestation.md).
