# PMWFeeProof

The `PMWFeeProof` attestation type provides accurate fee accounting for Protocol Managed Wallet payment operations across a range of nonces. It compares the estimated fees (from on-chain instruction events) with the actual fees (from executed transactions on the external chain), enabling protocols to verify fee expenditure and reconcile costs.

## Request

Attestation request body:

The request body is formatted as the [`PMWFeeProof.RequestBody`](../Types/Abi/AttestationType.md#requestbody-2) struct.

- `opType` — the wallet operation type, used to compute deterministic instruction IDs for event lookup.
- `senderAddress` — the sender address on the external chain (e.g., an XRP address).
- `fromNonce` — inclusive lower bound of the nonce range to query.
- `toNonce` — inclusive upper bound of the nonce range to query.
- `untilTimestamp` — Flare chain block timestamp defining the cutoff for fetching reissue events. Reissue events occurring after this timestamp are excluded from the calculation. The caller should first confirm that `toNonce` is complete (via `PMWPaymentStatus`) before requesting `PMWFeeProof`.

## Response

Attestation response body:

The response body is formatted as the [`PMWFeeProof.ResponseBody`](../Types/Abi/AttestationType.md#responsebody-2) struct.

- `actualFee` — the total fees actually spent on the external chain for all transactions in the nonce range, summed in minimal units (drops for XRP).
- `estimatedFee` — the total estimated fees based on the `maxFee` values from the on-chain pay and reissue instruction events, summed in minimal units.

## Chain Support

Currently, `PMWFeeProof` is only used for XRP. The nonces correspond to XRP sequence numbers, and fees are measured in drops.

## Verification

### Event Lookup

Events are fetched from the C-chain indexer:

- **Pay events**: Instruction IDs are deterministic (computed from `opType`, `PAY`, `sourceId`, `senderAddress`, `nonce`). All IDs for the nonce range can be computed upfront and batch-fetched.
- **Reissue events**: Instruction IDs include a `reissueNumber` (not known upfront). The verifier queries iteratively per nonce, incrementing the reissue number until no event is found. Since reissues are rare, most nonces require only the pay event lookup.
- Only events with block timestamp $\leq \mathrm{untilTimestamp}$ are included.

### Transaction Lookup

Actual transaction fees are fetched from the XRP indexer by querying for transactions matching `senderAddress` and the sequence numbers in the nonce range.

### Fee Computation

#### Actual Fee

For each nonce in the range $[\mathrm{fromNonce}, \mathrm{toNonce}]$:

1. Query the XRP indexer for the executed transaction matching `senderAddress` and the nonce (XRP sequence number).
2. Extract the transaction fee from the XRP transaction response.
3. Sum all transaction fees:

$$\mathrm{actualFee} = \sum_{n = \mathrm{fromNonce}}^{\mathrm{toNonce}} \mathrm{txFee}(n)$$

#### Estimated Fee

For each nonce $n$ in the range $[\mathrm{fromNonce}, \mathrm{toNonce}]$:

1. Find the `PAY` event with instruction ID:

$$\mathrm{instructionId}_{\mathrm{pay}} = \mathrm{keccak256}(\mathrm{abi.encode}(\mathrm{opType},\ \text{PAY},\ \mathrm{sourceId},\ \mathrm{senderAddress},\ n))$$

2. Extract $\mathrm{maxFee}_{\mathrm{pay}}$ from the pay event's `PaymentInstructionMessage`.
3. Find all `REISSUE` events for the same nonce (with reissue numbers $0, 1, 2, \dots$ until no more are found):

$$\mathrm{instructionId}_{\mathrm{reissue}} = \mathrm{keccak256}(\mathrm{abi.encode}(\mathrm{opType},\ \text{REISSUE},\ \mathrm{sourceId},\ \mathrm{senderAddress},\ n,\ \mathrm{reissueNumber}))$$

4. For each reissue, extract $\mathrm{maxFee}_{\mathrm{reissue}}$.
5. Compute the estimated fee for the nonce:

$$\mathrm{estimatedFee}(n) = \mathrm{maxFee}_{\mathrm{pay}} + \sum_{r} \max(0,\ \mathrm{maxFee}_{\mathrm{reissue}}(r) - \mathrm{maxFee}_{\mathrm{pay}})$$

6. Sum across all nonces:

$$\mathrm{estimatedFee} = \sum_{n = \mathrm{fromNonce}}^{\mathrm{toNonce}} \mathrm{estimatedFee}(n)$$

The residual-based formula ensures that reissues with a lower `maxFee` than the original pay do not reduce the estimated fee (clamped to $0$).

## Notes

- The caller should use `PMWPaymentStatus` to confirm that all nonces in the requested range are finalized before requesting `PMWFeeProof`. The `untilTimestamp` field prevents the verifier from attempting to include in-flight or incomplete reissue events.
- The `estimatedFee` calculation is designed for fee reconciliation use cases (e.g., FAsset fee tracking), where the difference between estimated and actual fees must be accounted for.
- **Error conditions:**

| Condition | HTTP Status | Description |
|---|---|---|
| Missing pay event for any nonce in the range | $422$ | Every nonce must have a corresponding pay event. |
| Missing XRP transaction for any nonce in the range | $422$ | Every nonce must have an executed transaction. |
| Nonce range exceeds maximum size | $400$ | The verifier enforces a cap on the nonce range (e.g., $100$ nonces). |
| Database infrastructure failure | $503$ | Connection timeout or transaction failure (retryable). |
| Unparseable transaction data | $500$ | Malformed or corrupted data in the indexer. |

- **Data retention:** The XRP indexer retains transaction data for a configurable period (typically approximately $2$ weeks in production). Callers must request `PMWFeeProof` within this retention window; otherwise, the verifier will return a $422$ error for missing transaction data.
