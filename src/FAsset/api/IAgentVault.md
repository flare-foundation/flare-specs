# IAgentVault

## Methods

### depositCollateral

```solidity
function depositCollateral(IERC20 _token, uint256 _amount) external
```

Deposit vault collateral.
Parameter `_token` is explicit to allow depositing before collateral switch.

NOTE: Owner must call `token.approve(vault, amount)` before calling this method. Only the agent vault owner can call.

*Parameters:*

- `token` — The token to be deposited.
- `amount` - The amount of the token to be deposited.

### updateCollateral

```solidity
function updateCollateral(IERC20 _token) external
```

Update collateral after `transfer(vault, some amount)` was called (alternative to depositCollateral).
Parameter `_token` is explicit to allow depositing before collateral switch.

NOTE: only the owner of the agent vault may call this method.

*Parameters:*

- `token` — The token for which the amount is being updated.

### withdrawCollateral

```solidity
function withdrawCollateral(IERC20 _token, uint256 _amount, address _recipient) external
```

Withdraw vault collateral. 

NOTE: only the owner of the agent vault may call this method.

*Parameters:*

- `token` — The token to be withdrawn.
- `amount` - The amount of the token to be withdrawn.
- `address` - The recipient address of the withdrawal.

### transferExternalToken

```solidity
function transferExternalToken(IERC20 _token, uint256 _amount) external
```

Allow transferring a token, airdropped to the agent vault, to the owner (management address). Doesn't work for vault collateral tokens or agent's pool tokens.

NOTE: only the owner of the agent vault may call this method.

*Parameters:*

- `token` — The token to be transferred.
- `amount` - The amount of the token to be transferred.

### buyCollateralPoolTokens

```solidity
function buyCollateralPoolTokens() external payable
```

Buy collateral pool tokens for NAT.
Holding enough pool tokens in the vault is required for minting.

NOTE: only the owner of the agent vault may call this method.

### withdrawPoolFees

```solidity
function withdrawPoolFees(uint256 _amount, address _recipient) external
```

The amount of collateral pool tokens which must be held by the agent accrue minting fees in form of FAssets.
These fees can be withdrawn using this method.

NOTE: only the owner of the agent vault may call this method.

*Parameters:*

- `amount` - The amount of the token to be withdrawn.
- `address` - The recipient address of the withdrawal.

### redeemCollateralPoolTokens

```solidity
function redeemCollateralPoolTokens(uint256 _amount, address payable _recipient) external
```

This method allows the agent to convert collateral pool tokens back to NAT.

NOTE: only the owner of the agent vault may call this method.

*Parameters:*

- `amount` - The amount of the token to be redeemed.
- `address` - The recipient address of the redemption.


### collateralPool

```solidity
function collateralPool() external view returns (ICollateralPool)
```

Get the address of the collateral pool contract corresponding to this agent vault (there is 1:1 correspondence between agent vault and collateral pools).

*Returns:*

- `ICollateralPool` - The collateral pool contract for the agent vault.
