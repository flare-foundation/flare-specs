# F_XRP PAY

## Description

Indicates signing a multisig payment transaction with the specified private key(s).

If the amount is 0 and the source address equals the recipient address, a nullification transaction (empty AccountSet transaction) is signed. The payment reference is still included in the transaction.

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
    bytes32 tokenId;                  // currently unused
    uint256 amount;                   // amount of the token transferred
    uint256 fee;                      // fee for the transaction
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

## Fixed message

/

## Variable message

/

## Additional action data

/

## Action result

JSON of the XRP Ledger transaction with filled `Signers` field. The transaction is a standard XRPL multisig payment or AccountSet (for nullification).
