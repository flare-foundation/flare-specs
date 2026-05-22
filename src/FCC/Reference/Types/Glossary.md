# Format Glossary

The JSON schemas under [`Abi/`](Abi) and [`Wire/`](Wire) use custom `format` values to describe Solidity and EVM types.
This page defines each format and its JSON wire representation.

| Format | Solidity type | JSON representation | Example |
|--------|--------------|---------------------|---------|
| `address` | `address` | 0x-prefixed hex string, $20$ bytes | `"0x1234...5678"` |
| `bytes32` | `bytes32` | 0x-prefixed hex string, $32$ bytes | `"0xabcd...ef01"` |
| `bytes` | `bytes` | 0x-prefixed hex string, variable length | `"0xdeadbeef"` |
| `uint256` | `uint256` | Decimal integer or decimal string | `999` or `"999"` |
| `uint64` | `uint64` | JSON number | `12345` |
| `uint32` | `uint32` | JSON number | `42` |
| `uint16` | `uint16` | JSON number | `4000` |
| `uint8` | `uint8` | JSON number | `1` |

All byte and hash values use lowercase hex with a `0x` prefix.
Integer types up to $64$ bits are represented as JSON numbers.
The `uint256` type may appear as either a JSON number or a decimal string depending on context.
