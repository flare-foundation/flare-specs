# F_POLICY INITIALIZE_POLICY

[Direct action](../../Actions.md#direct-actions) issued by the [TEE proxy](../../../Components/TeeProxy.md) at startup to seed the TEE machine's first [signing policy](../../../../FSP/SigningPolicy.md), using the current policy read from the Flare C-chain.

## Action message

[`InitializePolicyRequest`](../../../Types/Wire/Policy.md#initializepolicyrequest).

## Action result

Empty.

## Notes

- The machine rejects the action if a policy is already initialized.
- The supplied `publicKeys` must match the policy's signer addresses one-for-one and in order; any mismatch aborts initialization.
- See [`UPDATE_POLICY`](UpdatePolicy.md) for subsequent rotations.
