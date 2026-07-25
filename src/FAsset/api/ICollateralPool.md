# ICollateralPool

## Methods

### enter

```solidity
function enter() external payable returns (uint256 _receivedTokens, uint256 _timelockExpiresAt)
```

Enters the collateral pool by depositing NAT.
The tokens have a timelock before which exiting or transferring tokens is not possible.

*Returns:*

- `receivedTokens` - The tokens received by the user entering the pool.
- `timelockExpiresAt` - The expiry time of the timelock.

### exit

```solidity
function exit(uint256 _tokenShare) external returns (uint256 _natShare)
```

Exits the pool by redeeming the given amount of pool tokens for a share of NAT and FAsset fees.
Exiting only returns collateral, the fasset fees must be separately collected by calling `withdrawFees`.
Exiting with collateral that lowers pool's collateral ratio below exit CR is not allowed and will revert.

*Parameters:*

- `_tokenShare` — The amount of pool tokens to be redeemed.

*Returns:*

- `natShare` - The NAT to be received for redeeming.

### selfCloseExit

```solidity
function selfCloseExit(uint256 _tokenShare, bool _redeemToCollateral, string _redeemerUnderlyingAddress, address payable _executor) external payable
```

Exits the pool by redeeming the given amount of pool tokens and burning FAssets in a way that doesn't endanger the pool collateral ratio. 
In case of self-close via redemption, the user can set executor to trigger possible default. 
In this case, some NAT can be sent with transaction, to pay the executor's fee.

*Parameters:*

- `_tokenShare` — The amount of pool tokens to be liquidated.
- `_redeemToCollateral` — Specifies if redeemed Fassets should be exchanged to vault collateral.
- `_redeemerUnderlyingAddress` — Redeemer's address on the underlying chain.
- `_executor` — The account that is allowed to execute redemption default.

### withdrawFees

```solidity
function withdrawFees(uint256 _amount) external
```

Collect FAsset fees by locking an appropriate ratio of transferable tokens

*Parameters:*

- `_amount` — The amount of f-asset fees to withdraw. Must be positive and smaller than or equal to the sender's FAsset fees.

### exitTo

```solidity
function exitTo(uint256 _tokenShare, address payable _recipient) external returns (uint256 _natShare)
```

Exits the pool by redeeming the given amount of pool tokens for a share of NAT and FAsset fees.
Exiting only returns collateral, the FAsset fees must be separately collected by calling `withdrawFees`. 
Exiting with collateral that lowers pool's collateral ratio below exit CR is not allowed and will revert.

*Parameters:*

- `_tokenShare` — The amount of pool tokens to be redeemed.
- `_recipient` — The address to which NATs and FAsset fees will be transferred.



### selfCloseExitTo

```solidity
function selfCloseExitTo(uint256 _tokenShare, bool _redeemToCollateral, address payable _recipient, string _redeemerUnderlyingAddress, address payable _executor) external payable
```

Exits the pool by redeeming the given amount of pool tokens and burning f-assets in a way that doesn't endanger the pool collateral ratio. Specifically, if pool's collateral ratio is above exit CR, then the method burns an amount of user's f-assets that do not lower collateral ratio below exit CR. If, on the other hand, collateral pool is below exit CR, then the method burns an amount of user's f-assets that preserve the pool's collateral ratio. The method always burns fassets from user address even if the user has some fasset fees in the pool (those can be collected before using selfCloseExit). F-assets will be redeemed in collateral if their value does not exceed one lot, regardless of  `_redeemToCollateral` value. In case of self-close via redemption, the user can set executor to trigger possible default. In this case, some NAT can be sent with transaction, to pay the executor's fee.

*Parameters:*

- `_tokenShare` — The amount of pool tokens to be liquidated
- `_redeemToCollateral` — Specifies if redeemed f-assets should be exchanged to vault collateral                                      by the agent
- `_recipient` — The address to which NATs and FAsset fees will be transferred
- `_redeemerUnderlyingAddress` — Redeemer's address on the underlying chain
- `_executor` — The account that is allowed to execute redemption default.

*Returns:*

- `natShare` - The NAT to be received for redeeming.

### withdrawFeesTo

```solidity
function withdrawFeesTo(uint256 _amount, address _recipient) external
```

Collect FAsset fees by locking an appropriate ratio of transferable tokens

*Parameters:*

- `_amount` — The amount of FAsset fees to withdraw. Must be positive and smaller than or equal to the sender's fAsset fees.
- `_recipient` — The address to which FAsset fees will be transferred.

### payFAssetFeeDebt

```solidity
function payFAssetFeeDebt(uint256 _fassets) external
```

Unlock pool tokens by paying FAsset fee debt

*Parameters:*

- `_fassets` — The amount of debt FAsset fees to pay.

### claimAirdropDistribution

```solidity
function claimAirdropDistribution(IDistributionToDelegators _distribution, uint256 _month) external returns (uint256 _claimedAmount)
```

Claim airdrops earned by holding wrapped native tokens in the pool.

NOTE: only the owner of the pool's corresponding agent vault may call this method.

*Parameters:*

- `distribution` — The airdrop distribution contract.
- `month` — The month for which the claim is made.

*Returns:*

- `claimedAmount` - The amount of asset claimed in the airdrop.

### optOutOfAirdrop

```solidity
function optOutOfAirdrop(IDistributionToDelegators _distribution) external
```

Opt out of airdrops for wrapped native tokens in the pool.

NOTE: only the owner of the pool's corresponding agent vault may call this method.

*Parameters:*

- `distribution` — The airdrop distribution contract.

### delegate

```solidity
function delegate(address _to, uint256 _bips) external
```

Delegate WNat vote power for the wrapped native tokens held in this vault.

NOTE: only the owner of the pool's corresponding agent vault may call this method.

*Parameters:*

- `to` — The address to which the delegation goes.
- `bips` — The delegation share.

### undelegateAll

```solidity
function undelegateAll() external
```

Clear all WNat delegations.

### claimDelegationRewards

```solidity
function claimDelegationRewards(IRewardManager _rewardManager, uint24 _lastRewardEpoch, RewardsV2Interface.RewardClaimWithProof[] _proofs) external returns (uint256 _claimedAmount)
```

Claim the rewards earned by delegating the vote power for the pool.

NOTE: only the owner of the pool's corresponding agent vault may call this method.

*Parameters:*

- `_rewardManager` — The reward manager contract address.
- `_lastRewardEpoch` — The last claimed epoch; all unclaimed epochs until this epoch are claimed.
- `_proofs` — The proofs of the collateral pool's claims.

*Returns:*

- `claimedAmount` - The amount of asset claimed from the delegations.

### poolToken

```solidity
function poolToken() external view returns (ICollateralPoolToken)
```

Get the ERC20 pool token used by this collateral pool

*Returns:*

- `ICollateralPoolToken` - The pool token for the collateral pool.

### agentVault

```solidity
function agentVault() external view returns (address)
```

Get the vault of the agent that owns this collateral pool.

*Returns:*

- `address` - The address of the Agent Vault for the collateral pool.

### exitCollateralRatioBIPS

```solidity
function exitCollateralRatioBIPS() external view returns (uint32)
```

Get the exit collateral ratio in BIPS.
This is the collateral ratio below which exiting the pool is not allowed.

*Returns:*

- `uint32` - The exit CR of the pool.

### totalCollateral

```solidity
function totalCollateral() external view returns (uint256)
```

Return total amount of collateral in the pool.

*Returns:*

- `uint256` - The total amount of collateral in the pool.

### fAssetFeesOf

```solidity
function fAssetFeesOf(address _account) external view returns (uint256)
```

Returns the FAsset fees belonging to this user.

*Parameters:*

- `_account` — User address.

*Returns:*

- `uint256` - The amount of FAsset fees owned.

### totalFAssetFees

```solidity
function totalFAssetFees() external view returns (uint256)
```

Returns the total FAsset fees in the pool.

*Returns:*

- `uint256` - The amount of FAsset fees in the pool.

### fAssetFeeDebtOf

```solidity
function fAssetFeeDebtOf(address _account) external view returns (int256)
```

Returns the user's FAsset fee debt.

*Parameters:*

- `_account` — User address.

*Returns:*

- `int256` - The amount of FAsset fee debt owned by the user.

### totalFAssetFeeDebt

```solidity
function totalFAssetFeeDebt() external view returns (int256)
```

Returns the total FAsset fee debt for all users.

*Returns:*

- `int256` - The amount of FAsset fee debt owned across all users.

### fAssetRequiredForSelfCloseExit

```solidity
function fAssetRequiredForSelfCloseExit(uint256 _tokenAmountWei) external view returns (uint256)
```

Get the amount of fassets that need to be burned to perform self-close exit.

*Parameters:*

- `tokenAmountWei` — The amount of tokens to be self-closed.

*Returns:*

- `uint256` - The amount of FAssets required to be burnt.

## Events

### CPEntered

```solidity
event CPEntered(address indexed tokenHolder, uint256 amountNatWei, uint256 receivedTokensWei, uint256 timelockExpiresAt)
```

### CPExited

```solidity
event CPExited(address indexed tokenHolder, uint256 burnedTokensWei, uint256 receivedNatWei)
```

### CPSelfCloseExited

```solidity
event CPSelfCloseExited(address indexed tokenHolder, uint256 burnedTokensWei, uint256 receivedNatWei, uint256 closedFAssetsUBA)
```

### CPFeeDebtPaid

```solidity
event CPFeeDebtPaid(address indexed tokenHolder, uint256 paidFeesUBA)
```

### CPFeesWithdrawn

```solidity
event CPFeesWithdrawn(address indexed tokenHolder, uint256 withdrawnFeesUBA)
```

### CPFeeDebtChanged

```solidity
event CPFeeDebtChanged(address indexed tokenHolder, int256 newFeeDebtUBA)
```

### CPPaidOut

```solidity
event CPPaidOut(address indexed recipient, uint256 paidNatWei, uint256 burnedTokensWei)
```

### CPClaimedReward

```solidity
event CPClaimedReward(uint256 amountNatWei, uint8 rewardType)
```