# TEE Machine

A _TEE machine_ is a confidential-compute environment that runs an [FCE](../Extensions/README.md)'s code inside a hardware-attested enclave (Intel TDX, AMD SEV, etc.) on a cloud TEE platform.
Each machine has a unique identity key pair generated inside the enclave at boot; the public part — its $\mathrm{TEE}_{\mathrm{ID}}$ — is the machine's on-chain address.
Every machine is paired one-to-one with a [TEE proxy](TeeProxy.md) that owns its public-facing endpoint, queues work for it, and stores its results.

A TEE machine is admitted to an FCE through [registration](../TeeManagement/Registration.md), which binds its $\mathrm{TEE}_{\mathrm{ID}}$ to an extension and to a supported code version.
Once in `PRODUCTION` status, the machine repeatedly processes [actions](../Operations/Actions.md) until it is paused, replaced, or banned.

## Action Processing

For each action, the TEE machine:

1. Polls the proxy's [internal queue API](TeeProxy.md#internal-apis) for the next JSON [`Action`](../Types/Wire/Action.md#action) on one of the proxy's three [processing queues](TeeProxy.md#processing-queues).
2. [Validates](#validation) instruction actions (direct actions skip this step).
3. Dispatches `(opType, opCommand)` to a handler — built into the machine, or provided by an attached [FCE](../Extensions/README.md).
4. Posts the resulting [action response](../Operations/Actions.md#action-responses) back to the proxy.

### Validation

Before executing an instruction action, the TEE machine verifies:

1. `data.id` matches the `instructionId` inside the action's `message`.
2. `teeId` inside the action matches the machine's own identity.
3. `(opType, opCommand)` is a registered pair.
4. The instruction's [reward epoch](../../FSP/Epochs.md#reward-epoch) is no more than one epoch older than the machine's active signing policy. Future epochs (newer than the active one) are accepted; epochs older than the previous one are rejected as stale.
5. Each signature recovers to a distinct address that is in that signing policy, in the instruction's `cosigners` list, or both.
6. The [pass conditions](../Operations/Voting.md#pass-conditions) hold on the recovered signers.

### Cosigner Enforcement

To mitigate the [`cosigners`/`cosignersThreshold` strip threat](../Operations/Instructions.md#cosigners):

- **System actions that consume a [wallet key](../TeeManagement/Keys.md#wallet-private-key-data-structure)** compare the instruction's `cosigners`/`cosignersThreshold` against the values stored with that key (set at [key generation](../Operations/Commands/F_WALLET/KeyGenerate.md), not modifiable after); a mismatch rejects the action.
- **System actions that sign only with the $\mathrm{TEE}_{\mathrm{ID}}$ key** (e.g. [`F_FDC2 PROVE`](../Extensions/FDC2/Commands/Prove.md)) commit `cosigners` and `cosignersThreshold` into the signed result, so a downstream verifier can check them.
- **Custom FCE actions** must implement their own enforcement.

### Execution Guarantees

- Every fetched action receives an [action response](../Operations/Actions.md#action-responses) within a per-action timeout, even on internal failures.
- If the first delivery to the proxy fails, the machine retries once with a minimal unsigned error response.
