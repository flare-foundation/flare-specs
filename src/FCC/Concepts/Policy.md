# Signing Policy

The _signing policy_ defines the FSP's voter set and per-voter weights for a [reward epoch](../../FSP/Epochs.md#reward-epoch).
[FSP documentation](../../FSP/SigningPolicy.md) gives details on how it is derived, its [normalized weights](../../FSP/SigningPolicy.md#normalized-weights), and its thresholds.
This page covers only the FCC-specific view, such as how a [TEE machine](Machines.md) learns the active policy and what that policy governs.

A machine cannot verify or accept [signed instructions](Instructions.md) without the signing policy.
Each machine tracks two policies, both reported in every [attestation](Machines.md#attestation):

- **initial policy**: the first signing policy the machine held, installed at registration.
-**active policy**: the most recent policy the machine holds, advanced once per reward epoch.

## Installation

The TEE machine's corresponding [TEE proxy](../Reference/Components/Proxy.md) seeds a machine's initial policy on first connection via [`INITIALIZE_POLICY`](../Reference/Operations/F_POLICY.md#initialize_policy) as part of the registration [attestation](Machines.md#attestation).
Thus, anyone verifying that attestation also confirms the correct policy was installed.
Further initializations after the first are rejected.

## Rotation

At the end of each reward epoch, the proxy advances the active policy on the TEE machine with [`UPDATE_POLICY`](../Reference/Operations/F_POLICY.md#update_policy); [SigningPolicyTransition](../Workflows/SigningPolicyTransition.md) is the per-machine state machine.
As in the FSP, the new policy is authorized by the _prior_ policy's signers: the machine adopts a new policy only if it is signed by a sufficient weight of providers on the current policy and if it is for the next consecutive epoch.
Because each policy is chained to its predecessor this way, [`UPDATE_POLICY`](../Reference/Operations/F_POLICY.md#update_policy) is a [direct action](Actions.md#direct-actions) and needs no [instruction vote](Voting.md).

## Gating Votes

The active policy's signing threshold defines the weight of data provider signatures that a TEE machine requires before an [instruction vote](Voting.md) passes; only [`F_FDC2 PROVE`](../../FDC2/Reference/Operations/Prove.md) may carry a per-instruction override.
Each instruction has a `rewardEpochId` stating what epoch it was issued in: an instruction whose `rewardEpochId` falls more than one epoch behind the active policy is [rejected as stale](../Workflows/InstructionLifecycle.md).

## Backup Binding

Every [wallet key](Keys.md) is backed up at generation and re-backed up on each succesful [`UPDATE_POLICY`](../Reference/Operations/F_POLICY.md#update_policy).
In this case, the proxy queues a [`TEE_BACKUP`](../Reference/Operations/F_GET.md#tee_backup) for every stored key.
A backup's [data-provider share](Keys.md#backup-procedure) is Shamir-split over the policy active at backup time, weighted by voter weight, and records that policy's reward epoch, fixing which providers can later reconstruct it.