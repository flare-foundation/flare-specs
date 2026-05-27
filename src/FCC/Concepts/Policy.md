# Signing Policy

The _signing policy_ is the FSP's voter set and per-voter weights for one [reward epoch](../../FSP/Epochs.md#reward-epoch). [`FSP § SigningPolicy`](../../FSP/SigningPolicy.md) is the source of truth for how it is derived, its [normalized weights](../../FSP/SigningPolicy.md#normalized-weights), and its threshold; this page covers only the FCC-specific view — how a [TEE machine](Machines.md) learns the active policy and what that policy governs.

A machine cannot verify or accept [signed instructions](Instructions.md) without it. Each machine tracks two policies, both reported in every [attestation](Machines.md#attestation):

- _initial policy_ — the first the machine held, installed at registration.
- _active policy_ — the most recent, advanced once per reward epoch.

## Installation

The [TEE proxy](../Reference/Components/Proxy.md) seeds a machine's first policy on first connection via [`INITIALIZE_POLICY`](../Reference/Operations/F_POLICY.md#initialize_policy), as part of the registration [attestation](Machines.md#attestation) — so anyone verifying that attestation also confirms the correct policy was installed. A second initialization is rejected.

## Rotation

At each reward-epoch boundary the proxy advances the active policy with [`UPDATE_POLICY`](../Reference/Operations/F_POLICY.md#update_policy); [SigningPolicyTransition](../Workflows/SigningPolicyTransition.md) is the per-machine state machine. The defining FCC property is that a new policy is authorized by the _prior_ policy's signers: the machine adopts it only when signatures recovering to the active voter set exceed the active threshold, and only for the next consecutive epoch. Because each policy is chained to its predecessor this way, [`UPDATE_POLICY`](../Reference/Operations/F_POLICY.md#update_policy) is a [direct action](Actions.md#direct-actions) and needs no [instruction vote](Voting.md).

On [replication](../Workflows/MachineReplication.md) the successor inherits the active policy with the rest of the [state](Machines.md#tee-state), so no rotation is needed mid-replication.

## Gating Votes

The active policy's threshold is the weight a machine requires before an [instruction vote](Voting.md) passes; only [`F_FDC2 PROVE`](../../FDC2/Reference/Operations/Prove.md) may carry a per-instruction override. An instruction whose `rewardEpochId` falls more than one epoch behind the active policy is [rejected as stale](../Workflows/InstructionLifecycle.md).

## Backup Binding

Every [wallet key](Keys.md) is backed up at generation and re-backed up on each rotation — when [`UPDATE_POLICY`](../Reference/Operations/F_POLICY.md#update_policy) succeeds the proxy enqueues a [`TEE_BACKUP`](../Reference/Operations/F_GET.md#tee_backup) for every stored key. A backup's [data-provider share](Keys.md#backup-procedure) is Shamir-split over the policy active at backup time, weighted by voter weight, and records that policy's reward epoch — fixing which providers can later reconstruct it.
