# Extension Instructions

## Overview

This workflow describes how a caller sends a custom instruction to a non-system extension and retrieves the result.
Canonical instruction, action, and extension-routing semantics belong to [Instructions](../Operations/Instructions.md), [Actions](../Operations/Actions.md), and [Extensions](../Extensions/README.md).
This page focuses on the procedural flow rather than the internal implementation of any specific extension.

## Prerequisites

- The extension must be registered and configured on-chain.
- At least one TEE machine for that extension must be in `PRODUCTION` status.
- An instruction sender contract, or another approved entry point, must be available for the extension.
- Any extension-specific wallet, account, or authorization prerequisites must already be satisfied.

## Steps

### Step 1: Build and Submit the Extension Instruction

The caller invokes the extension's instruction sender logic, which ultimately calls `FlareTeeManager.sendInstructions()`.
The instruction must define:

- the target `teeIds`,
- the custom `opType`,
- the custom `opCommand`,
- the encoded `message`,
- any required [`cosigners`](../Operations/Instructions.md#cosigners), and
- the `cosignersThreshold`.

The meaning of `opType`, `opCommand`, and `message` is owned by the extension itself and should be documented with the extension contracts or application documentation.

### Step 2: Providers and Cosigners Relay the Instruction

After the on-chain instruction is emitted, [data providers](../../Terminology/Roles.md#data-provider) and any required cosigners prepare the corresponding [instruction](../Operations/Instructions.md).
They sign and relay it to the target TEE proxies using the standard FCC instruction flow.

### Step 3: The Proxy Routes the Action to the Extension

Once the voting threshold is met, the proxy packages the instruction as an [action](../Operations/Actions.md).
Because the operation is not a system `F_*` command, the TEE node routes it to the configured extension logic instead of handling it with the built-in system processors.

### Step 4: The Extension Produces a Result

The extension processes the action and returns a standard action result.
Depending on the extension, the result may be:

- a final success result,
- a final error result, or
- a transient or in-progress result followed by a later final result.

The payload format of `result.data` is extension-specific.

### Step 5: Retrieve and Verify the Result

The caller polls `GET /action/result/<instructionId>` on the TEE proxy until the final result is available.
The proxy response includes the TEE-signed action result, which the caller then interprets according to the extension's own result schema and any verifying contract logic.

### Step 6: Optional Direct Actions

If an extension intentionally supports [direct actions](../Operations/Actions.md#direct-actions), the operator can submit them through the proxy's `POST /direct` endpoint instead of via `sendInstructions()`.
The resulting action still follows the standard action-response format.
Signature and authorization requirements for direct actions remain extension-specific.

## Notes

- Define the custom `opType`, `opCommand`, and payload encoding with the extension, not in the core FCC pages.
- Use [Actions](../Operations/Actions.md) as the owner page for `submissionTag`, `status`, and response semantics.
- Current implementation details such as ports, timeouts, and internal extension APIs are not canonical workflow rules and should stay in implementation-facing documentation.
