# ICollateralPoolToken

## Methods

### collateralPool

```solidity
function collateralPool() external view returns (address)
```

Returns the address of the collateral pool that issued this token.

*Returns:*

- `address` - The address of the collateral pool contract for the token.

### lockedBalanceOf

```solidity
function lockedBalanceOf(address _account) external view returns (uint256)
```

Returns the amount of locked (time or debt locked) tokens that cannot be transferred.

*Parameters:*

- `account` - User's account address.

*Returns:*

- `uint256` - The amount of locked tokens owned by the user.

### transferableBalanceOf

```solidity
function transferableBalanceOf(address _account) external view returns (uint256)
```

Returns the amount of tokens that can be transferred. These are tokens that are neither timelocked neither locked due to fasset fee debt.

*Parameters:*

- `account` - User's account address.

*Returns:*

- `uint256` - Amount of tokens that the user is able to transfer.

### debtLockedBalanceOf

```solidity
function debtLockedBalanceOf(address _account) external view returns (uint256)
```

Returns the amount of account's tokens that are locked due to account's fasset fee debt.

*Parameters:*

- `account` - User's account address.

*Returns:*

- `uint256` - Amount of tokens that the user owns that are locked.

### debtFreeBalanceOf

```solidity
function debtFreeBalanceOf(address _account) external view returns (uint256)
```

Returns the amount of account's tokens that are not locked due to account's FAsset fee debt.

*Parameters:*

- `account` - User's account address.

*Returns:*

- `uint256` - Amount of tokens that the user owns that are not debtlocked.

### timelockedBalanceOf

```solidity
function timelockedBalanceOf(address _account) external view returns (uint256)
```

Returns the amount of account's tokens that are timelocked.

*Parameters:*

- `Account` - User's account address.

*Returns:*

- `uint256` - Amount of tokens that the user owns that are timelocked.

### nonTimelockedBalanceOf

```solidity
function nonTimelockedBalanceOf(address _account) external view returns (uint256)
```

Returns the amount of account's tokens that are not timelocked.

*Parameters:*

- `account` - User's account address.

*Returns:*

- `uint256` - Amount of tokens that the user owns that are not timelocked.

### allowance

```solidity
function allowance(address owner, address spender) external view returns (uint256)
```

Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through `transferFrom`.

*Parameters:*

- `owner` - The owner of the tokens.
- `spender` - The address eligible to transfer the tokens.

*Returns:*

- `uint256` - The amount that the spender is eligible to transfer.

### approve

```solidity
function approve(address spender, uint256 amount) external returns (bool)
```

Sets `amount` as the allowance of `spender` over the caller's tokens.

*Parameters:*

- `spender` - The address eligibile to transfer the tokens.
- `amount` - The new allowance of the spender account.

*Returns:*

- `bool` - Whether or not the transaction was successful.

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256)
```

Returns the amount of tokens owned by `account`.

*Parameters:*

- `account` - The account whose balance is returned.

*Returns:*

- `uint256` - The balance of the account.

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```

Returns the amount of tokens in existence.

*Returns:*

- `uint256` : The total amount of collateral pool tokens in existence.

### transfer

```solidity
function transfer(address to, uint256 amount) external returns (bool)
```

Moves `amount` tokens from the caller's account to `to`. 
Emits a `Transfer` event.

*Parameters:*

- `to` - The receiver address of the transfer.
- `uint256` - The amount to be transferred.

*Returns:*

- `bool` - Whether or not the transfer was successful.

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 amount) external returns (bool)
```

Moves `amount` tokens from `from` to `to` using the allowance mechanism. Returns a boolean value indicating whether the operation succeeded. Emits a {Transfer} event.

*Parameters:*

- `from` - The sender address of the transfer.
- `to` - The receiver address of the transfer.
- `uint256` - The amount to be transferred.

*Returns:*

- `bool` - Whether or not the transfer was successful.

## Events

### Approval

```solidity
event Approval(address indexed owner, address indexed spender, uint256 value)
```

Emitted when the allowance of a `spender` for an `owner` is set by a call to `approve`; `value` is the new allowance.

### Transfer

```solidity
event Transfer(address indexed from, address indexed to, uint256 value)
```

Emitted when `value` tokens are moved from one account (`from`) to another (`to`). Note that `value` may be zero.