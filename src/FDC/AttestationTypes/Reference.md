# Reference

This section includes concepts that are reused across many attestation types.

## Standard Address Hash

Each blockchain has its own specifications for address formats.
In most cases, the address is represented by a unique case-sensitive string.
When there are more ways of representing an address, some rules are added to make it unique.

On Bitcoin and Dogecoin, base58 encoded addresses have only one valid form.
For bech32(m) encoded addresses on Bitcoin, lowercase address is standard.
On XRPL, addresses have only one valid form.

The Solidity code that computes the standard address hash is:

```Solidity
keccak256(bytes(standardAddress));
```

or

```Solidity
keccak256(abi.encodePacked(standardAddress));
```

where standardAddress is of type string.

## Source Addresses Root

Source Addresses Root of a transaction is the Root of [Merkle tree](../../Utilities/MerkleTree.md) of the double keccak256 hashes of all addresses (in standard form) that have provided funds in the transaction.
If any account without an address has provided funds, a single zero byte32 string is added to the Merkle tree.

In Solidity, double keccak256 hashes of an address is computed by

```Solidity
keccak256(abi.encodePacked(keccak256(bytes(standardAddress))));
```

where standardAddress is of type string.

## Standard Payment Reference

Standard payment reference is defined as a 32-byte hex string, that can be added to a payment transaction.

### Bitcoin and Dogecoin

Each unspent transaction output (UTXO) has a pkscript that determines who and how it can be spent.
The `OP_RETURN` [opcode](https://en.bitcoin.it/wiki/Script) in the pkscript makes the UTXO intentionally unspendable.

A transaction is considered to have a `standardPaymentReference` defined if it has exactly one output UTXO with `OP_RETURN` script and the script is of the form `OP_RETURN <reference\>` or `6a<lengthOfReferenceInHex\><reference\>` in hex, where the length of the `reference` is 32 bytes.
Then `0x<reference\>` is `standardPaymentReference`.

An example is the Bitcoin transaction with the ID **53bb7420d146c957ed4f41c5175043503b5e953ed5af0387340f8c2c4949c2e1** in block **578,772**
with `standardPaymentReference` **0xbdaf8a8067dae5b453e0e27bd33521c166ddc5dc481ee993006dcea30e6e2e5b**.

### XRPL

On XRPL, the `memoData` field is used to provide the payment reference.

A transaction has a `standardPaymentReference` if it has exactly one [Memo](https://xrpl.org/transaction-common-fields.html#memos-field) and the `memoData` of this `Memo` field is a hex string that represents a byte sequence of exactly 32 bytes.
This 32-byte sequence is considered to be `standardPaymentReference`.

An example is the transaction with the ID **C610A06B5B26A8AF3D24DB7D3D458B8AC46920803B5694FB1FFC0FB7C1857405** in ledger
**81,001,656** with `standardPaymentReference` **0x7274312e312e33322d6275676669782d322d67653135323239372d6469727479**.

## Confirmation Number

By design, the latest blocks on the main branch are subject to changes, i.e., at some point it might be uncertain which branch should be considered main.
However, blocks at a certain depth are considered confirmed (they will stay on the main branch with a high enough probability).

Several attestation types have a predefined notion of a sufficient number of confirmations as listed below:

| `Chain` | `numberOfConfirmations` |
| ------- | ----------------------- |
| `BTC`   | 6                       |
| `DOGE`  | 60                      |
| `XRP`   | 3                       |
