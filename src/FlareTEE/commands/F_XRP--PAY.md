# F_XRP PAY

## Description

Signs an XRP Ledger multisig payment transaction using the specified TEE-managed private key(s).

If the amount is $0$ and the source address equals the recipient address, a nullification transaction (empty `AccountSet` transaction) is signed. The payment reference is still included in the transaction.

If the `tokenId` is zero-valued, the transaction is a direct XRP payment. Other cases: TBD.

The `sourceId` should be `XRP` or `testXRP`.

## Event message

```solidity
// Source: ITeePayments.sol
struct PaymentInstructionMessage {
    bytes32 walletId;                 // wallet id on which the payment is done
    TeeIdKeyIdPair[] teeIdKeyIdPairs; // pairs of TEE id and key id
    bytes32 sourceId;                 // id of the chain where the transaction is to be performed
    string senderAddress;             // address sending
    string recipientAddress;          // address receiving
    bytes tokenId;                    // token identifier (variable length); zero-valued for native XRP
    uint256 amount;                   // amount of the token transferred
    uint256 maxFee;                   // maximum fee for the transaction
    bytes feeSchedule;               // encoded fee schedule for progressive fee escalation
    bytes32 paymentReference;         // payment reference of the transaction
    uint64 nonce;                     // nonce of the transaction
    uint64 subNonce;                  // unused
    uint64 batchEndTs;                // unused
}

// Source: ITeeIdKeyIdPair.sol
struct TeeIdKeyIdPair {
    address teeId; // TEE machine id
    uint64 keyId;  // key id
}
```

### Fee Schedule

The `feeSchedule` field encodes a list of fee entries for progressive fee escalation. Each entry specifies a fee amount and a time delay. The TEE machine signs all fee schedule entries upfront and returns the results progressively — each result is posted back to the proxy after the specified delay. This mechanism allows automatic fee escalation if earlier transactions are not confirmed on the XRP Ledger.

The `feeSchedule` must not be empty; an empty fee schedule causes an error.

## Fixed message

/

## Variable message

/

## Additional action data

/

## Action result

The `SignXRPLPayment` processor returns empty data on the `Threshold` submission tag.
Signed transactions are posted asynchronously to the proxy via a background goroutine — one result per fee schedule entry, each delayed according to the entry's time offset.
Intermediate results use status $3$, $4$, $5$, etc. (one per fee entry).
The final result uses status $1$.

Each result contains JSON of an XRP Ledger transaction with filled `Signers` field.

## Notes

- **Validation:** The TEE machine performs the following validations before signing:
  - The fee schedule must not be empty.
  - The TEE ID must appear in the `teeIdKeyIdPairs` list.
  - The key type must be `XRP`.
  - The signing algorithm for the key must be `sha512half-secp256k1-ecdsa`.
  - Cosigner signatures are verified per key (when cosigners are configured on the wallet).
  - The key must exist on the machine and be in active status.
