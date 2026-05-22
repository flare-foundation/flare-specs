# F_POLICY UPDATE_POLICY

[Direct action](../../Actions.md#direct-actions) issued by the [TEE proxy](../../../Components/TeeProxy.md) when a new [signing policy](../../../../FSP/SigningPolicy.md) becomes active on the Flare C-chain.
The proxy supplies the new policy together with enough signatures from the active policy's signers to authorize the rotation.

## Action message

[`UpdatePolicyRequest`](../../../Types/Wire/Policy.md#updatepolicyrequest).

## Action result

Empty.

## Notes

- The machine accepts the request only if `newPolicy.rewardEpochId == active.rewardEpochId + 1`.
- Every signature in `signatures` must recover to an address in the active policy's voter set. A signature from any other address aborts the request.
- The combined [signing](../../../../Utilities/Signing.md) weight of the recovered signers on `keccak256(policyBytes)` must strictly exceed the active policy's threshold.
- The supplied `publicKeys` must match the new policy's signer addresses one-for-one and in order.
- On success, the proxy's [result hooks](../../../Components/TeeProxy.md#result-hooks) enqueue a [`TEE_BACKUP`](../F_GET/TeeBackup.md) for every stored key, binding fresh backups to the new policy.
