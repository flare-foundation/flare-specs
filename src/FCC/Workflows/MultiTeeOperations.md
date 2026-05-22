# Distributed Multi-TEE Workflows

## Overview

This page describes the parts of a deployment that change when a wallet or application is operated across multiple TEE machines.
It does not repeat the full single-TEE procedures.
Use [MachineRegistration.md](MachineRegistration.md), [WalletSetup.md](WalletSetup.md), [XrplMultisigConfiguration.md](../PMW/Workflows/XrplMultisigConfiguration.md), and [XrpPayment.md](../PMW/Workflows/XrpPayment.md) as the base workflows, and apply the deltas below.

For canonical ownership, state, and key semantics, see [Registration](../Concepts/Machines.md), [State](../Concepts/Machines.md) and [Attestation](../Concepts/Machines.md), and [Key Management](../Concepts/Keys.md).

## When Multi-TEE Operation Changes the Flow

Multi-TEE operation matters when:

- keys are distributed across several machines,
- a wallet uses a threshold greater than one,
- signatures must be gathered from multiple proxies, or
- a machine can be replaced without taking the whole wallet offline.

## Delta Workflow

### Step 1: Register Each Machine Independently

Repeat [MachineRegistration.md](MachineRegistration.md) for each TEE machine.
Each machine has its own identity, proxy, availability proof, lifecycle, and status transitions.
All machines that will participate in the same workflow must be registered to the same extension.

### Step 2: Create One Wallet and Distribute Keys Across TEEs

Follow [WalletSetup.md](WalletSetup.md) once to create the project, wallet, admins, cosigners, and multisig threshold.
Then add and confirm keys on multiple TEEs instead of stopping after the first key:

- issue one `addKey()` call per target TEE,
- confirm each key individually with its own key-existence proof, and
- ensure the wallet threshold matches the intended multi-TEE signing model.

If a machine must be replaced, restore the key on the replacement TEE first, confirm it, and only then remove the old copy.
Use [KeyRestore.md](KeyRestore.md) and [KeyDelete.md](KeyDelete.md) for that sequence.

### Step 3: Configure the External Multisig Account from All Confirmed Keys

When the wallet is used for PMW, gather the confirmed public keys from all participating TEEs and follow [XrplMultisigConfiguration.md](../PMW/Workflows/XrplMultisigConfiguration.md).
The external signer set and quorum must match the wallet's confirmed keys and threshold, not just a single machine.

### Step 4: Collect Results from Multiple Proxies

For workflows that produce one result per participating TEE, retrieve the result from each relevant proxy.
In the PMW payment case, this means collecting partial signatures from multiple proxies, aggregating them into the final multisigned transaction, and then submitting that final transaction on the external chain.
Follow [XrpPayment.md](../PMW/Workflows/XrpPayment.md) for the base payment flow, and [Fdc2Attestation.md](../FDC2/Workflows/Fdc2Attestation.md) when post-submission proof verification is needed.

### Step 5: Operate the Lifecycle Per Machine

Availability checks, pauses, upgrades, settings updates, and ownership changes remain per-machine actions.
The wallet or application remains healthy only while enough machines remain available to satisfy the configured threshold.
If a machine drops out of service, restore or replace the missing key material before the available signer set falls below the required threshold.

## Practical Checks

- All participating TEEs must belong to the same extension as the wallet or application.
- The wallet threshold, external multisig quorum, and available key count must stay aligned.
- Each proxy should be treated as an independent result source.
- Recovery and decommissioning should preserve signing availability throughout the migration.

## Notes

- Single-TEE workflows remain the primary procedural references.
- This page should only document the distributed-operation delta, not restate the full single-TEE setup.
