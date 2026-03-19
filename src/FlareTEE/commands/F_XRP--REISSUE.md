# F_XRP REISSUE

## Description

Used to reissue already issued transactions. The message and the process are the same as with the [PAY](F_XRP--PAY.md) command.

## Event message

Same as [PAY](F_XRP--PAY.md).

```solidity
// Source: ITeePayments.sol
struct PaymentInstructionMessage {
    bytes32 walletId;
    TeeIdKeyIdPair[] teeIdKeyIdPairs;
    bytes32 sourceId;
    string senderAddress;
    string recipientAddress;
    bytes32 tokenId;
    uint256 amount;
    uint256 fee;
    bytes32 paymentReference;
    uint64 nonce;
    uint64 subNonce;
    uint64 batchEndTs;
}
```

## Fixed message

/

## Variable message

/

## Additional action data

/

## Action result

Same as [PAY](F_XRP--PAY.md) -- JSON of the XRP Ledger transaction with filled `Signers` field.
