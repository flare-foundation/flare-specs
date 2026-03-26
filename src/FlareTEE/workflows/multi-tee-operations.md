# Distributed Multi-TEE Workflows

## Overview

This page describes the parts of a deployment that change when a wallet or application is operated across multiple TEE machines.
It does not repeat the full single-TEE procedures.
Use [machine-registration.md](machine-registration.md), [wallet-setup.md](wallet-setup.md), [xrpl-multisig-configuration.md](xrpl-multisig-configuration.md), and [xrp-payment.md](xrp-payment.md) as the base workflows, and apply the deltas below.

For canonical ownership, state, and key semantics, see [Ownership](../TEE Management/Ownership.md), [State and Status](../TEE Management/State and Status.md), and [Key Management](../TEE Management/Key Management.md).

## When Multi-TEE Operation Changes the Flow

Multi-TEE operation matters when:

- keys are distributed across several machines,
- a wallet uses a threshold greater than one,
- signatures must be gathered from multiple proxies, or
- a machine can be replaced without taking the whole wallet offline.

## Delta Workflow

### Step 1: Register Each Machine Independently

Repeat [machine-registration.md](machine-registration.md) for each TEE machine.
Each machine has its own identity, proxy, availability proof, lifecycle, and status transitions.
All machines that will participate in the same workflow must be registered to the same extension.

### Step 2: Create One Wallet and Distribute Keys Across TEEs

Follow [wallet-setup.md](wallet-setup.md) once to create the project, wallet, admins, cosigners, and multisig threshold.
Then add and confirm keys on multiple TEEs instead of stopping after the first key:

- issue one `addKey()` call per target TEE,
- confirm each key individually with its own key-existence proof, and
- ensure the wallet threshold matches the intended multi-TEE signing model.

If a machine must be replaced, restore the key on the replacement TEE first, confirm it, and only then remove the old copy.
Use [key-restore.md](key-restore.md) and [key-delete.md](key-delete.md) for that sequence.

### Step 3: Configure the External Multisig Account from All Confirmed Keys

When the wallet is used for PMW, gather the confirmed public keys from all participating TEEs and follow [xrpl-multisig-configuration.md](xrpl-multisig-configuration.md).
The external signer set and quorum must match the wallet's confirmed keys and threshold, not just a single machine.

### Step 4: Collect Results from Multiple Proxies

For workflows that produce one result per participating TEE, retrieve the result from each relevant proxy.
In the PMW payment case, this means collecting partial signatures from multiple proxies, aggregating them into the final multisigned transaction, and then submitting that final transaction on the external chain.
Follow [xrp-payment.md](xrp-payment.md) for the base payment flow, and [fdc2-attestation.md](fdc2-attestation.md) when post-submission proof verification is needed.

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
