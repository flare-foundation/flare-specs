# F_POLICY UPDATE_POLICY

[Direct action](../../Actions.md#direct-actions) issued by the [TEE proxy](../../../Components/TeeProxy.md) when a new [signing policy](../../../../FSP/SigningPolicy.md) becomes active on the Flare C-chain.
The proxy supplies the new policy together with enough signatures from the active policy's signers to authorize the rotation.

## Action message

[`UpdatePolicyRequest`](../../../Types/Wire/Policy.md#updatepolicyrequest).

## Action result

Empty.

## Notes

- The machine accepts the request only if `newPolicy.rewardEpochId == active.rewardEpochId + 1`.
- The accumulated [signing](../../../../Utilities/Signing.md) weight of valid signatures on `keccak256(policyBytes)` must exceed the active policy's threshold; signers outside the active policy are ignored.
- The supplied `publicKeys` must match the new policy's signer addresses one-for-one and in order.
- A successful update triggers [`TEE_BACKUP`](../F_GET/TeeBackup.md) for every stored key, binding fresh backups to the new policy.
