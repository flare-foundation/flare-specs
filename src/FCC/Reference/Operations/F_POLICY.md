# F_POLICY

[Direct actions](../../Operations/Actions.md#direct-actions) issued by the [TEE proxy](../Components/Proxy.md) to install and rotate the active [signing policy](../../../FSP/SigningPolicy.md) on the machine.

## INITIALIZE_POLICY

Seeds the machine's first signing policy. Issued once per paired TEE machine, on first connection.

**Action message:** [`InitializePolicyRequest`](../Types/Wire/Policy.md#initializepolicyrequest).

**Action result:** empty.

**Notes.**

- The machine rejects the action if a policy is already initialized.
- The supplied `publicKeys` must match the policy's signer addresses one-for-one and in order; any mismatch aborts initialization.
- See [`UPDATE_POLICY`](#update_policy) for subsequent rotations.

## UPDATE_POLICY

Rotates to a new signing policy. Issued when a new signing policy becomes active on the Flare C-chain.
The proxy supplies the new policy together with enough signatures from the active policy's signers to authorize the rotation.

**Action message:** [`UpdatePolicyRequest`](../Types/Wire/Policy.md#updatepolicyrequest).

**Action result:** empty.

**Notes.**

- The machine accepts the request only if `newPolicy.rewardEpochId == active.rewardEpochId + 1`.
- Every signature in `signatures` must recover to an address in the active policy's voter set. A signature from any other address aborts the request.
- The combined [signing](../../../Utilities/Signing.md) weight of the recovered signers on `keccak256(policyBytes)` must strictly exceed the active policy's threshold.
- The supplied `publicKeys` must match the new policy's signer addresses one-for-one and in order.
- On success, the proxy's [result hooks](../Components/Proxy.md#result-hooks) enqueue a [`TEE_BACKUP`](F_GET.md#tee_backup) for every stored key, binding fresh backups to the new policy.
