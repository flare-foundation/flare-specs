# IFAsset

## Methods

### assetName

```solidity
function assetName() external view returns (string)
```

The name of the underlying asset.

*Returns:*

- `string` - The asset name.

### assetSymbol

```solidity
function assetSymbol() external view returns (string)
```

The symbol of the underlying asset.

*Returns:*

- `string` - The asset symbol.

### assetManager

```solidity
function assetManager() external view returns (address)
```

Get the asset manager, corresponding to this FAsset. FAssets and asset managers are in 1:1 correspondence.

*Returns:*

- `address` - The address of the asset manager contract for the FAsset.

### allowance

```solidity
function allowance(address owner, address spender) external view returns (uint256)
```

Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through `transferFrom`.

*Parameters:*

- `owner` - The owner that the spender acts on behalf of.
- `spender` - The address that is allowed to call `transferFrom`.

*Returns:*

- `uint256` - The number of tokens allowed to be spent.

### approve

```solidity
function approve(address spender, uint256 amount) external returns (bool)
```

Sets `amount` as the allowance of `spender` over the caller's tokens.

*Parameters:*

- `spender` - The address that is allowed to call `transferFrom`.
- `amount` - The amount of tokens the spender is allowed to transfer.

*Returns:*

- `bool` - Whether or not the call was successful.

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256)
```

Returns the amount of tokens owned by `account`.

*Parameters:*

- `account` - The account in question.

*Returns:*

- `uint256` - The amount of tokens owned by the account.

### decimals

```solidity
function decimals() external view returns (uint8)
```

Returns the decimals places of the token.

*Returns:*

- `uint8` - The number of decimal places of the token. 

### name

```solidity
function name() external view returns (string)
```

Returns the name of the token.

*Returns:*

- `string` - The name of the token.

### symbol

```solidity
function symbol() external view returns (string)
```

Returns the symbol of the token.

*Returns:*

- `string` - The symbol of the token.

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```

Returns the amount of tokens in existence.

*Returns:*

- `uint256` - The total amount of tokens in circulation.

### transfer

```solidity
function transfer(address to, uint256 amount) external returns (bool)
```

Moves `amount` tokens from the caller's account to `to`. Emits a `Transfer` event.

*Parameters:*

- `to` - The address receiving the token transfer.
- `amount` - The amount of tokens to be transferred.

*Returns:*

- `bool` - Whether or not the call was successful.

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 amount) external returns (bool)
```

Moves `amount` tokens from `from` to `to` using the allowance mechanism. Emits a `Transfer` event.

*Parameters:*

- `from` - The address sending the tokens.
- `to` - The address receiving the token transfer.

*Returns:*

- `bool` - Whether or not the call was successful.

## Events

### Approval

```solidity
event Approval(address indexed owner, address indexed spender, uint256 value)
```

Emitted when the allowance of a `spender` for an `owner` is set by a call to `approve`. `value` is the new allowance.

### Transfer

```solidity
event Transfer(address indexed from, address indexed to, uint256 value)
```

Emitted when `value` tokens are moved from one account (`from`) to another (`to`). Note that `value` may be zero.