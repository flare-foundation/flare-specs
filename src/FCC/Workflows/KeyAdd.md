# KeyAdd

State machine for adding one wallet key on one TEE machine.
The workflow takes a wallet that is being configured and lands the key in the on-chain `Confirmed` state so a wallet can later be `enabled` ([WalletSetup](WalletSetup.md)).

## Preconditions

- The wallet's project exists; the [project owner](../../Terminology/Roles.md#project-owner) holds the project's `owner` address.
- `wallet.status = INITIALIZED`.
- The target TEE machine is in `PRODUCTION` and is registered to the wallet's project's `extensionId`.

For the underlying [key custody concepts](../Concepts/Keys.md) and the [wallet bookkeeping](../Concepts/Wallets.md#wallet-keys), see the linked pages.

## States

- `NotExists` — no on-chain record for the prospective `(walletId, keyId)`.
- `Generated` — `addKey` has emitted `KEY_GENERATE`; the TEE machine has not yet returned a confirmed [`KeyExistence`](../Reference/Types/Abi/Key.md#keyexistence) proof.
- `Confirmed` — the public key is recorded on chain; `teeId` appears in the key's `teeIds` list.

## Initial State

`NotExists` for the next sequential `keyId` of the wallet.

## Transitions

### addKey: NotExists → Generated

- **Action**: [`FlareTeeManager.addKey(walletId, teeId, claimBackAddress)`](../Reference/Contracts/FlareTeeManager.md#key-custody) — payable.
- **Caller**: project owner.
- **Guards**:
  - `wallet.status = INITIALIZED`
  - `teeMachine.status = PRODUCTION`
  - `teeMachine.extensionId = project.extensionId`
  - `msg.value ≥ fee(F_WALLET, KEY_GENERATE)`
- **Effects**:
  - Assigns the next sequential `keyId` for the wallet.
  - Sends a [`F_WALLET KEY_GENERATE`](../Reference/Operations/F_WALLET.md#key_generate) instruction to `teeId`.
  - Emits [`WalletKeyAdded`](../Reference/Contracts/FlareTeeManagerEvents.md#walletkeyadded) and [`TeeInstructionsSent`](../Reference/Contracts/FlareTeeManagerEvents.md#teeinstructionssent).
  - Off-chain: the TEE machine generates a key pair inside the enclave, associates it with the wallet, and queues an automatic [key backup](../Concepts/Keys.md#key-backup).

### confirmKey: Generated → Confirmed

- **Action**: [`FlareTeeManager.confirmKey(proof, teeSignature)`](../Reference/Contracts/FlareTeeManager.md#key-custody) — non-payable.
- **Caller**: project owner.
- **Guards**:
  - `wallet.status = INITIALIZED`
  - `teeMachine.status = PRODUCTION`
  - `proof` references the previously-assigned `(walletId, keyId)`
  - `proof` is consistent with the wallet's on-chain admins/cosigners ([cosigner enforcement](../Reference/Components/Machine.md#cosigner-enforcement))
  - `proof` is consistent with project's signing algorithms and key types
  - `proof` settings and settings versions are empty
  - `proof.extensionID` matches the TEE machine's extension ID.
  - `proof.restored = FALSE`
  - `proof.nonce = 0`
  - `teeSignature` recovers to `teeMachine.publicKey`
- **Effects**:
  - On the first valid confirmation, stores `proof.publicKey` as the key's canonical `publicKey`.
  - Adds `teeId` to the key's `teeIds` list.
  - Emits [`WalletKeyConfirmed`](../Reference/Contracts/FlareTeeManagerEvents.md#walletkeyconfirmed).

## Invariants

- A key reaches `Confirmed` only after both transitions have succeeded; no transition skips `Generated`.
- A key's `publicKey` is fixed at first confirmation; later confirmations from other TEE machines for the same `(walletId, keyId)` cannot change it.
- The TEE machines listed in the key's `teeIds` are a subset of `PRODUCTION` machines of the wallet's project's extension.

## Terminal States

`Confirmed`. From here:

- [WalletSetup](WalletSetup.md) can `enableWallet` once `multisigThreshold` confirmed keys exist.
- [KeyDelete](KeyDelete.md) and [KeyRestore](KeyRestore.md) take this workflow's output as their starting state.
- The key is usable by [`F_WALLET`](../Reference/Operations/F_WALLET.md) operations (e.g. PMW signing, VRF).

## Notes

- `addKey` can be repeated on different TEE machines for the same wallet; each invocation assigns its own `keyId`, and the keys are independent state machines.
- The TEE-machine-side execution of `KEY_GENERATE` is asynchronous from the chain's view: between `Generated` and `Confirmed` the chain has no observable change. A project owner who never collects a `KeyExistence` proof will leave the workflow stuck in `Generated` indefinitely.
