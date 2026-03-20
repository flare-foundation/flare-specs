# Extension Instructions

## Overview

Custom [extensions](../Extensions/Extensions.md) receive and process instructions through the Flare Confidential Compute infrastructure. When an instruction is sent to an extension, it flows from the blockchain through the TEE proxy to the TEE node, which forwards non-system actions to the compute extension app for processing. The extension can use the FCC node app's internal endpoints to sign data, retrieve key information, and post results back.

This document covers sending instructions to custom extensions, processing them, and retrieving the results. Two concrete examples are demonstrated: EVM transaction signing and random number generation.

## Prerequisites

- Extension registered and configured (see [Extension Configuration](extension-configuration.md))
- TEE machine registered and in `PRODUCTION` status (see [Machine Registration](machine-registration.md))
- Wallet created with appropriate key type and keys confirmed (see [Wallet Setup](wallet-setup.md))
  - For EVM signing: key type `"EVM"` with signing algorithm `keccak256-secp256k1-ecdsa`
  - Wallet must be in `PRODUCTION` status (status code `2`)
- Instruction sender contract deployed and its extension ID set via `setExtensionId()`
- TEE proxy running with connection to the TEE node

## Architecture

The following diagram shows the data flow for extension instruction processing:

```
Blockchain (C-chain)
  |
  |  User calls instruction sender contract
  |  (e.g., signTransaction() or generateRandomUint64())
  v
TeeExtensionRegistry.sendInstructions()
  |
  |  Emits TeeInstructionsSent event
  v
TEE Relay Client (polls C-chain indexer DB, signs instruction, routes to proxy)
  |
  v
TEE Proxy (port 6662 external / port 6661 internal)
  |  Collects threshold of data provider signatures
  |  Packages instruction into an Action
  v
TEE Node -- FCC Node App (ForwardRouter)
  |  Checks opType: non-system opTypes (not starting with F_)
  |  are forwarded to the compute extension
  v
Compute Extension App (port 8889)
  |  POST /action receives the action
  |  Extension processes the action:
  |    - May call /sign/<walletId>/<keyId> on port 8888
  |    - May call /key-info/<walletId>/<keyId> on port 8888
  |  Returns ActionResult (final or transient)
  v
FCC Node App (port 8888)
  |  POST /result receives final results from extension
  |  Signs the result with the TEE identity key
  v
TEE Proxy
  |  Stores ActionResponse for retrieval (30 minutes)
  v
Caller retrieves result via GET /action/result/<actionId>
```

The FCC node app serves actions with system `opTypes` (`F_GET`, `F_POLICY`, `F_WALLET`, `F_REG`) internally. Actions with other valid `opTypes` are forwarded to the compute extension via `POST /action`. An `opType` is valid if it does not start with `F_`.

---

## Step 1: EVM Transaction Signing via Extension -- `signTransaction()`

This step demonstrates sending a sign instruction through the instruction sender contract, which the TEE extension processes by signing an EVM transaction with wallet keys.

**Who can call:** The wallet project's authorization address

**Parameters (on the instruction sender contract):**
- `_walletId` (`bytes32`): The ID of the wallet containing the signing keys
- `_transaction` (`Transaction`): The EVM transaction to sign, containing:
  - `nonce` (`uint256`): Transaction nonce
  - `chainId` (`uint256`): Target chain ID
  - `to` (`address`): Destination address
  - `data` (`bytes`): Transaction calldata
  - `value` (`uint256`): ETH value to transfer
  - `gasPrice` (`uint256`): Gas price (legacy transactions)
  - `maxFeePerGas` (`uint256`): Max fee per gas (EIP-1559)
  - `maxPriorityFeePerGas` (`uint256`): Max priority fee (EIP-1559)
  - `gas` (`uint256`): Gas limit

**Requirements:**
- Caller must be the wallet project's authorization address
- Wallet key type must be `"EVM"`
- Wallet must be in `PRODUCTION` status
- Sufficient fee must be attached to the transaction (`msg.value`)

**What happens:**
1. The instruction sender contract validates the wallet status and retrieves the list of `TeeIdKeyIdPair` entries (TEE machine IDs and key IDs) from `TeeWalletKeyManager.receivingTeesAndKeys()`.
2. It also retrieves cosigner addresses and threshold from `TeeWalletManager.getWalletCosignersAndThreshold()`.
3. The contract encodes a `RequestSignedTransaction` struct containing the `walletId`, `teeIdKeyIdPairs`, and `transaction`.
4. It calls `TeeExtensionRegistry.sendInstructions()` with:
   - `teeIds`: Extracted from the `TeeIdKeyIdPair` list
   - `opType`: `"DEMO_EVM"` (custom extension opType, UTF-8 encoded as `bytes32`)
   - `opCommand`: `"SIGN"`
   - `message`: ABI-encoded `RequestSignedTransaction`
   - `cosigners` and `cosignerThreshold`: From the wallet configuration
5. The `TeeInstructionsSent` event is emitted with a unique `instructionId`.
6. Data providers pick up the instruction, sign it, and relay it to the TEE proxy.
7. Once the proxy collects a threshold of signatures, it packages the instruction as an Action and sends it to the TEE node.
8. The FCC node app's ForwardRouter detects the non-system `opType` (`DEMO_EVM`) and forwards the action to the compute extension at `POST /action` on port 8889.
9. The extension decodes the `RequestSignedTransaction` from the action's `DataFixed.OriginalMessage`.
10. For each `TeeIdKeyIdPair`, the extension:
    a. Calls `GET /key-info/<walletId>/<keyId>` on port 8888 to verify the key's signing algorithm is `keccak256-secp256k1-ecdsa`.
    b. RLP-encodes the transaction as `[nonce, gasPrice, gasLimit, to, value, data, chainId, 0, 0]`.
    c. Calls `POST /sign/<walletId>/<keyId>` on port 8888 with the RLP-encoded message.
    d. Receives the signed message and ECDSA signature in RSV format.
11. The extension returns a transient result (status `2`, indicating processing is in progress) immediately and continues signing in the background.
12. Once all signatures are collected, the extension constructs a `DataEVM` struct:
    - `instructionId` (`bytes32`): The instruction ID
    - `message` (`bytes`): The signed message (RLP-encoded transaction)
    - `signatures` (`bytes[]`): Array of ECDSA signatures, one per key
    - `teeIdKeyIdPairs` (`TeeIdKeyIdPair[]`): The TEE ID and key ID pairs used
13. The extension ABI-encodes the `DataEVM` struct and posts the final result to `POST /result` on port 8888 with status `1` (success).
14. The FCC node app signs the result with the TEE identity key and forwards it to the proxy.

**Events emitted:**
- `TeeInstructionsSent(instructionId, extensionId, teeMachines, ...)` on `TeeExtensionRegistry`

---

## Step 2: Random Number Generation via Extension -- `generateRandomUint64()`

This step demonstrates sending a random number generation instruction, which the TEE extension processes using cryptographically secure randomness inside the TEE.

**Who can call:** Any address (in the coin-flip game example, players who have deposited)

**Parameters (on the instruction sender contract):**
- `_walletId` (`bytes32`): A wallet ID (used for TEE machine selection in the sign variant; the RNG contract uses `TeeMachineRegistry.getRandomTeeIds()` for machine selection)

**Requirements:**
- Extension must have at least one TEE machine in `PRODUCTION` status
- Sufficient fee may need to be attached depending on the instruction sender logic

**What happens:**
1. The instruction sender contract calls `TeeExtensionRegistry.sendInstructions()` with:
   - `teeIds`: One or more TEE machine addresses (selected via `TeeMachineRegistry.getRandomTeeIds()` or from wallet key pairs)
   - `opType`: `"DEMO_RNG"` (custom extension opType)
   - `opCommand`: `"BOOL"` (generates a random 0 or 1) or `"BYTES32"` (generates 32 random bytes)
   - `message`: Empty bytes (no additional parameters needed)
   - `cosigners`: Empty array
   - `cosignerThreshold`: `0`
2. The `TeeInstructionsSent` event is emitted with a unique `instructionId`.
3. Data providers pick up the instruction, sign it, and relay it to the TEE proxy.
4. The FCC node app forwards the action to the compute extension at `POST /action` on port 8889.
5. The extension checks the `opCommand`:
   - `"BOOL"`: Generates 1 cryptographically secure random byte, masked to `0x00` or `0x01`.
   - `"BYTES32"`: Generates 32 cryptographically secure random bytes.
6. The extension returns the random bytes as the action result data with status `1` (success).
7. The result is also posted to `POST /result` on port 8888 and cached locally by the extension.
8. The FCC node app signs the result with the TEE identity key and forwards it to the proxy.

**Events emitted:**
- `TeeInstructionsSent(instructionId, extensionId, teeMachines, ...)` on `TeeExtensionRegistry`

---

## Step 3: Retrieving and Verifying Extension Action Results

After an instruction has been processed, the action result is stored on the TEE proxy and can be retrieved by the caller.

**Who can call:** Any address with access to the TEE proxy's external endpoint

**Endpoint:** `GET /action/result/<instructionId>` on the TEE proxy (port 6662)

**What happens:**
1. The caller polls the proxy's `/action/result/<instructionId>` endpoint using the `instructionId` returned when the instruction was sent.
2. The proxy returns an `ActionResponse` containing:
   - `result` (`ActionResult`):
     - `id` (`bytes32`): The action ID
     - `submissionTag` (`string`): Submission context (e.g., `"threshold"`, `"end"`, `"submit"`)
     - `status` (`uint8`): `0` = error, `1` = success, `2`+ = transient/pending
     - `log` (`string`): Error message if status is `0`, otherwise empty or informational
     - `opType` (`bytes32`): The operation type (e.g., `"DEMO_EVM"`, `"DEMO_RNG"`)
     - `opCommand` (`bytes32`): The operation command (e.g., `"SIGN"`, `"BOOL"`)
     - `version` (`string`): Result encoding version
     - `data` (`bytes`): The result payload, encoding depends on the opType and opCommand
   - `signature` (`bytes`): Signature by the TEE machine's identity key over `hash(hash(data), id, hash(submissionTag), status)`
   - `proxySignature` (`bytes`): Signature by the TEE proxy

### Verifying EVM Signatures

For `DEMO_EVM` / `SIGN` results, the `data` field contains an ABI-encoded `DataEVM` struct. To verify:

1. ABI-decode the `DataEVM` from `result.data`:
   - `instructionId` (`bytes32`)
   - `message` (`bytes`): The RLP-encoded transaction that was signed
   - `signatures` (`bytes[]`): One ECDSA signature per key
   - `teeIdKeyIdPairs` (`TeeIdKeyIdPair[]`)
2. For each signature, recover the public key using Keccak256-Secp256k1 ECDSA recovery:
   - Compute `hash = keccak256(message)`
   - Recover the public key from `(hash, signature)`
3. Compare the recovered public key against the expected public key from `GET /wallet/<walletId>/<keyId>` on the proxy.
4. If all recovered public keys match their expected values, the signatures are valid.

### Verifying Random Number Results

For `DEMO_RNG` results, the `data` field contains the raw random bytes:
- For `BOOL`: 1 byte (`0x00` or `0x01`)
- For `BYTES32`: 32 bytes

The TEE identity signature on the `ActionResponse` confirms the result originated from a legitimate TEE machine.

---

## Step 4: Extension SDK Interface Reference

The FCC SDK (SDK and Development -- not yet published) defines two sets of internal HTTP endpoints for communication between the FCC node app and the compute extension app.

### FCC Node App Internal Endpoints (port 8888)

These endpoints are exposed by the FCC node app for use by the compute extension:

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/key-info/<walletId>/<keyId>` | Returns metadata of the private key identified by `walletId` and `keyId`, including key type, signing algorithm, public key, and cosigner configuration. |
| `POST` | `/sign/<walletId>/<keyId>` | Signs the message (hex-encoded in request body) with the private key identified by `walletId` and `keyId`. Signing algorithm is determined by the key's configuration. Returns `{message, signature}` in ECDSA RSV format. |
| `POST` | `/sign` | Signs the message with the TEE identity (`teeId`) private key. The message (must be 32 bytes, hex-encoded) is prefixed with `"\x19Ethereum Signed Message:\n" + len(m) + m` before hashing with keccak256. Returns `{message, signature}`. |
| `POST` | `/result` | Posts a final or additional transient action result to the proxy. The request body contains the `ActionResult` struct. |
| `POST` | `/decrypt/<walletId>/<keyId>` | Decrypts a message (hex-encoded) using the key identified by `walletId` and `keyId`. Returns `{message}` with the decrypted content. |
| `POST` | `/decrypt` | Decrypts a message (hex-encoded) using the TEE identity key. Returns `{message}` with the decrypted content. |

For all endpoints, a 200 response uses `Content-Type: application/json`. Non-200 responses use `Content-Type: text/plain; charset=utf-8` with an error message in the body.

### Compute Extension App Endpoints (port 8889)

These endpoints must be implemented by the compute extension app:

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/action` | Receives action data from the FCC node app. The extension must respond with a result that is either final (status 0 or 1) or transient (status 2-7). If the result is transient, the final result must be posted to `/result` on port 8888. |
| `GET` | `/state` | Returns the ABI-encoded state of the compute extension. Response includes `stateVersion` (`bytes32`, hex string) and `state` (`bytes`, ABI-encoded custom state). |

### Action Processing Flow

When the FCC node app receives an action:

1. If the `opType` starts with `F_` (system command), it is processed internally by the node app.
2. Otherwise, the action is forwarded to the compute extension via `POST /action` on port 8889.
3. The extension has 2 seconds to respond. If the timeout is reached, one retry is attempted.
4. If both attempts fail, an error result with status `2` (timeout) is returned to the proxy.
5. For instruction-type actions, the FCC node app verifies that enough data provider and cosigner signatures are present before forwarding.
6. For direct-type actions, no signature verification is performed -- the extension implicitly trusts direct actions forwarded by the proxy.

---

## Step 5: Direct Actions to Extension -- `POST /direct`

Instructions can be sent to the compute extension directly without smart contract events, bypassing the data provider signing process. This is useful for administrative operations, queries, or actions where the legitimacy is proven by the action data itself.

**Who can call:** Any address with access to the TEE proxy's external endpoint

**Requirements:**
- The TEE proxy must have `direct_extension` set to `true` in its configuration
- The `opType` must not start with `F_` (system opTypes are rejected)

**Endpoint:** `POST /direct` on the TEE proxy (port 6662)

**Request body:**
```json
{
  "directInstruction": {
    "opType": "0x....",
    "opCommand": "0x....",
    "message": "0x...."
  }
}
```

- `opType` (`bytes32`): UTF-8 encoded opType as 32-byte hex string
- `opCommand` (`bytes32`): UTF-8 encoded opCommand as 32-byte hex string
- `message` (`bytes`): Hex-encoded bytes. Encoding depends on the opType and opCommand.

**What happens:**
1. The caller prepares a direct instruction with the message formatted according to the rules of the `(opType, opCommand)` pair.
2. The proxy validates that the opType is not a system type (does not start with `F_`).
3. The proxy assigns a random action ID and creates an Action of type "Direct" with submission tag `"submit"`.
4. The action is enqueued and forwarded to the TEE node.
5. The FCC node app forwards the action to the compute extension via `POST /action` on port 8889 without additional signature checks.
6. The proxy returns the prepared action (including the action ID) to the caller.
7. Once the TEE processes the action, the response is stored on the proxy for 30 minutes.
8. The caller retrieves the result using `GET /action/result/<actionId>` on the proxy's external endpoint.

**Response:**
```json
{
  "action": { ... }
}
```

The returned `action` object includes the assigned action ID needed to retrieve results later.

> **Note:** Direct actions do not go through the data provider signing process. The compute extension is responsible for validating the legitimacy of direct actions based on the action data itself. See Key Access Authorization (SDK and Development -- not yet published) for guidance on enforcing cosigner requirements within extensions.

---

## Cross-References

- [Extensions](../Extensions/Extensions.md) -- Extension lifecycle and management functions
- [System Extension](../Extensions/System%20Extension.md) -- System extension (ID 0) with PMW and FTDC
- SDK and Development -- Full SDK documentation, deployment procedures, and GCP setup (not yet published)
- TEE Configuration API -- Configuration endpoints on port 5500 (not yet published)
- [Actions](../Operations/Actions.md) -- Action structure, processing queues, and response format
- [Instructions](../Operations/Instructions.md) -- Instruction event format, TEE instructions, and thresholds
- [Extension Configuration](extension-configuration.md) -- Registering and configuring an extension
- [Machine Registration](machine-registration.md) -- Registering TEE machines and moving to production
- [Wallet Setup](wallet-setup.md) -- Creating wallet projects, wallets, and keys

