# IAssetManager

Asset manager publicly callable methods.

## Methods

### assetManagerController

```solidity
function assetManagerController() external view returns (address)
```

Get the asset manager controller, the address that can change settings.

*Returns:*

- `address` - The address of the asset manager controller.

### fAsset

```solidity
function fAsset() external view returns (IERC20)
```

Get the FAsset contract managed by this asset manager instance.

*Returns:*

- `IERC20` - The FAsset contract for this asset manager instance.


### priceReader

```solidity
function priceReader() external view returns (address)
```

Get the price reader contract used by this asset manager instance.


*Returns:*

- `address` - The address of the price reader contract.

### lotSize

```solidity
function lotSize() external view returns (uint256 _lotSizeUBA)
```

Return lot size in UBA.

*Returns:*

- `lotSizeUBA` - The amount of asset in a lot, in UBA.


### assetMintingGranularityUBA

```solidity
function assetMintingGranularityUBA() external view returns (uint256)
```

Return asset minting granularity.

*Returns:*

- `uint256` - The smallest unit of FAsset stored internally within this asset manager instance.

### assetMintingDecimals

```solidity
function assetMintingDecimals() external view returns (uint256)
```

Return asset minting decimals.

*Returns:*

- `uint256` - The decimal precision used for minting.


### getSettings

```solidity
function getSettings() external view returns (AssetManagerSettings.Data)
```

Get complete current settings.

*Returns:*

- `AssetManagerSettings.Data` - The settings of the asset maanger contract.

### controllerAttached

```solidity
function controllerAttached() external view returns (bool)
```

When `controllerAttached` is true, asset manager has been added to the asset manager controller, and thus is operational.

*Returns:*

- `bool` - Whether or not the asset manager is attached and operational.

### emergencyPaused

```solidity
function emergencyPaused() external view returns (bool)
```

If true, the system is in emergency pause mode and most operations (mint, redeem, liquidate) are disabled.

*Returns:*

- `bool` - Whether or not the system is in emergency pause mode.

### emergencyPauseLevel

```solidity
function emergencyPauseLevel() external view returns (EmergencyPause.Level)
```

Returns the current emergency pause level.

*Returns:*

- `EmergencyPause.Level` - The emergency pause level.

### emergencyPausedUntil

```solidity
function emergencyPausedUntil() external view returns (uint256)
```

The time when emergency pause mode will end automatically.

*Returns:*

- `uint256` - The timestemp at which the current pause will end.

### mintingPaused

```solidity
function mintingPaused() external view returns (bool)
```

True if minting is paused.

*Returns:*

- `bool` - Whether or not minting is paused.

### updateCurrentBlock

```solidity
function updateCurrentBlock(IConfirmedBlockHeightExists.Proof _proof) external
```

Prove that a block with given number and timestamp exists and update the current underlying block info if the provided data is higher. 


*Parameters:*

- `proof` — Proof that a block with a given block number and timestamp exists

### currentUnderlyingBlock

```solidity
function currentUnderlyingBlock() external view returns (uint256 _blockNumber, uint256 _blockTimestamp, uint256 _lastUpdateTs)
```

Get block number and timestamp of the current underlying block known to the FAsset system.

*Returns:*

- `blockNumber` - Current underlying block number tracked by asset manager.
- `blockTimestamp` - Current underlying block timestamp tracked by asset manager.
- `lastUpdateTs` - The timestamp on this chain when the current underlying block was last updated.

### getCollateralType

```solidity
function getCollateralType(CollateralType.Class _collateralClass, IERC20 _token) external view returns (CollateralType.Data)
```

Get collateral information about a token.

*Parameters:*

- `collateralClass` - The collateral class to query.
- `token` - The token in question.

*Returns:*

- `CollateralType.Data` - Collateral data for the token.

### getCollateralTypes

```solidity
function getCollateralTypes() external view returns (CollateralType.Data[])
```

Get the list of all available tokens used for collateral.

*Returns:*

- `CollateralType.Data[]` - The list of tokens that can be used as collateral.

### createAgentVault

```solidity
function createAgentVault(IAddressValidity.Proof _addressProof, AgentSettings.Data _settings) external returns (address _agentVault)
```

Create an agent vault. 

NOTE: may only be called by an agent on the allowed agent list. Can be called from the management or the work agent owner address.

*Parameters:*

- `addressProof` - The proof that the address is valid.
- `settings` - The settings for the agent vault.

*Returns:*

- `_agentVault` — The new agent vault address.

### announceDestroyAgent

```solidity
function announceDestroyAgent(address _agentVault) external returns (uint256 _destroyAllowedAt)
```

Announce that the agent is going to be destroyed.

NOTE: may only be called by the agent vault owner.

*Parameters:*

- `agentVault` - The vault to be destroyed.

*Returns:*

- `destroyAllowedAt` - The timestamp at which the destroy can be executed.

### destroyAgent

```solidity
function destroyAgent(address _agentVault, address payable _recipient) external
```

Delete all agent data, destroy the agent vault, and send remaining collateral to the `_recipient`.

NOTE: may only be called by the agent vault owner and must be preceeded by an announcement as above.

*Parameters:*

- `agentVault` — Address of the agent's vault to destroy.
- `recipient` — Address that receives the remaining funds and possible vault balance.

### upgradeAgentVaultAndPool

```solidity
function upgradeAgentVaultAndPool(address _agentVault) external
```

Upgrades the agent vault and pool.

NOTE: may only be called by the agent vault owner.

*Parameters:*

- `agentVault` — Address of the agent's vault; the vault, its corresponding pool, and its pool token will be upgraded to the newest implementations.

### isPoolTokenSuffixReserved

```solidity
function isPoolTokenSuffixReserved(string _suffix) external view returns (bool)
```

Check if the collateral pool token has been used already by some vault.

*Parameters:*

- `suffix` - The suffix to check whether or not is in use.

*Returns:*

- `bool` - Whether or not it is in use.

### announceAgentSettingUpdate

```solidity
function announceAgentSettingUpdate(address _agentVault, string _name, uint256 _value) external returns (uint256 _updateAllowedAt)
```

Announces a setting change. The change can be executed after the timelock expires.

NOTE: may only be called by the agent vault owner.

*Parameters:*

- `agentVault` - Agent vault address.
- `name` - Name of the setting to be updated.
- `value` - The value to update the setting to.

*Returns:*

- `updateAllowedAt` - The timestamp at which the update can be executed.

### executeAgentSettingUpdate

```solidity
function executeAgentSettingUpdate(address _agentVault, string _name) external
```

Executes a setting change after the timelock expires.

NOTE: may only be called by the agent vault owner and must be preceeded by an announcement as above.

*Parameters:*

- `agentVault` - Agent vault address
- `name` - Name of the setting to be updated.

### announceVaultCollateralWithdrawal

```solidity
function announceVaultCollateralWithdrawal(address _agentVault, uint256 _valueNATWei) external returns (uint256 _withdrawalAllowedAt)
```

Announces the agent intention to withdraw `_valueNATWei` amount of collateral from the agent vault. The agent must then wait `withdrawalWaitMinSeconds` time.

NOTE: may only be called by the agent vault owner.

*Parameters:*

- `agentVault` - Agent vault address.
- `valueNATWei` - The amount to be withdrawn.

*Returns:*

- `withdrawalAllowedAt` - The timestamp when the withdrawal can be made.

### announceAgentPoolTokenRedemption

```solidity
function announceAgentPoolTokenRedemption(address _agentVault, uint256 _valuePoolTokenWei) external returns (uint256 _redemptionAllowedAt)
```

Agent is going to withdraw `_valuePoolTokenWei` of pool tokens from the agent vault and redeem them for NAT from the collateral pool. The agent must then wait `withdrawalWaitMinSeconds` time.

NOTE: may only be called by the agent vault owner.

*Parameters:*

- `agentVault` - Agent vault address.
- `valuePoolTokenWei` - The amount to be withdrawn and redeemed.

*Returns:*

- `redemptionAllowedAt` - The timestamp when the redemption can be made.

### confirmTopupPayment

```solidity
function confirmTopupPayment(IPayment.Proof _payment, address _agentVault) external
```

When the agent tops up his underlying address, it has to be confirmed by calling this method, which updates the underlying free balance value.

NOTE: may only be called by the agent vault owner.

*Parameters:*

- `payment` — pProof of the underlying payment; must include payment      reference.
- `agentVault` — Agent vault address.

### announceUnderlyingWithdrawal

```solidity
function announceUnderlyingWithdrawal(address _agentVault) external
```

Announce withdrawal of underlying currency.
Until the announced withdrawal is performed and confirmed or canceled, no other withdrawal can be announced.

NOTE: may only be called by the agent vault owner.

*Parameters:*

- `agentVault` — Agent vault address.

### confirmUnderlyingWithdrawal

```solidity
function confirmUnderlyingWithdrawal(IPayment.Proof _payment, address _agentVault) external
```

Proovide confirmation of performed underlying withdrawal.

NOTE: may only be called by the owner of the agent vault, except if enough time has passed without confirmation; then it can be called by anybody.

*Parameters:*

- `payment` - Proof of the underlying payment.
- `agentVault` - Agent vault address.

### cancelUnderlyingWithdrawal

```solidity
function cancelUnderlyingWithdrawal(address _agentVault) external
```

Cancel ongoing withdrawal of underlying currency.

NOTE: may only be called by the agent vault owner.

*Parameters:*

- `AgentVault` - Agent vault address.

### getAllAgents

```solidity
function getAllAgents(uint256 _start, uint256 _end) external view returns (address[] _agents, uint256 _totalLength)
```

Get (a part of) the list of all active agents.

*Parameters:*

- `start` - First index to return from the available agent's list.
- `end` - End index (one above last) to return from the available agent's list.

*Returns:*

- `agents`- Addresses of the agents.
- `totalLength` - The total number of active agents in the list.

### getAgentInfo

```solidity
function getAgentInfo(address _agentVault) external view returns (AgentInfo.Info)
```

Return detailed info about an agent, typically needed by a minter.

*Parameters:*

- `agentVault` - Agent vault address.

*Returns:*

- `AgentInfo.Info` - Structure containing agent's minting fee (BIPS), min collateral ratio (BIPS), and current free collateral (lots).

### getAgentSetting

```solidity
function getAgentSetting(address _agentVault, string _name) external view returns (uint256)
```

Get agent's setting by name. This allows reading individual settings.

*Parameters:*

- `agentVault` - Agent vault address.
- `name` - Name of the setting being queried.

*Returns:*

- `uint256` - The value of the setting in question.

### getCollateralPool

```solidity
function getCollateralPool(address _agentVault) external view returns (address)
```

Returns the collateral pool address of the agent.

*Parameters:*

- `agentVault` The address of the agent vault for the pool.

*Returns:*

- `address` - The address of the agent's collateral pool.

### getAgentVaultOwner

```solidity
function getAgentVaultOwner(address _agentVault) external view returns (address _ownerManagementAddress)
```

Return the management address of the owner of the agent identified by `_agentVault`.

*Parameters:*

- `agentVault` The address of the agent vault for the pool.

*Returns:*

- `ownerManagementAddress` - The owner address of the agent.

### getAgentVaultCollateralToken

```solidity
function getAgentVaultCollateralToken(address _agentVault) external view returns (IERC20)
```

Return vault collateral ERC20 token chosen by the agent identified by `_agentVault`.

*Parameters:*

- `agentVault` The address of the agent vault for the pool.

*Returns:*

- `IERC20` - The agent's vault collateral token.

### getAgentFullVaultCollateral

```solidity
function getAgentFullVaultCollateral(address _agentVault) external view returns (uint256)
```

Return full vault collateral (free and locked) deposited in the vault `_agentVault`.

*Parameters:*

- `agentVault` The address of the agent vault for the pool.

*Returns:*

- `uint256` - The amount of agent vault collateral.

### getAgentFullPoolCollateral

```solidity
function getAgentFullPoolCollateral(address _agentVault) external view returns (uint256)
```

Return full pool NAT collateral (free and locked) deposited in the vault `_agentVault`.

*Parameters:*

- `agentVault` The address of the agent vault for the pool.

*Returns:*

- `uint256` - The amount of agent pool collateral.

### getAgentLiquidationFactorsAndMaxAmount

```solidity
function getAgentLiquidationFactorsAndMaxAmount(address _agentVault) external view returns (uint256 liquidationPaymentFactorVaultBIPS, uint256 liquidationPaymentFactorPoolBIPS, uint256 maxLiquidationAmountUBA)
```

Return the current liquidation factors and max liquidation amount of the agent identified by `_agentVault`.

*Parameters:*

- `agentVault` The address of the agent vault for the pool.

*Returns:*

- `liquidationPaymentFactorVaultBIPS` - The agent's liquidation payment factor.
- `maxLiquidationAmountUBA` - The max liquidation amount of the agent.

### getAgentMinPoolCollateralRatioBIPS

```solidity
function getAgentMinPoolCollateralRatioBIPS(address _agentVault) external view returns (uint256)
```

Return the minimum collateral ratio of the pool collateral owned by vault `_agentVault`.

*Parameters:*

- `agentVault` The address of the agent vault for the pool.

*Returns:*

- `uint256` - The min pool CR that the agent will accept.

### getAgentMinVaultCollateralRatioBIPS

```solidity
function getAgentMinVaultCollateralRatioBIPS(address _agentVault) external view returns (uint256)
```

Return the minimum collateral ratio of the vault collateral owned by vault `_agentVault`.

*Parameters:*

- `agentVault` The address of the agent vault for the pool.

*Returns:*

- `uint256` - The min vault CR that the agent will accept.

### makeAgentAvailable

```solidity
function makeAgentAvailable(address _agentVault) external
```

Add the agent to the list of publicly available agents.

NOTE: may only be called by the agent vault owner.

*Parameters:*

- `agentVault` - Agent vault address.

### announceExitAvailableAgentList

```solidity
function announceExitAvailableAgentList(address _agentVault) external returns (uint256 _exitAllowedAt)
```

Announce exit from the publicly available agents list.

NOTE: may only be called by the agent vault owner.

*Parameters:*

- `agentVault` - Agent vault address.

*Returns:*

- `exitAllowedAt` - The timestamp at which the agent can exit.

### exitAvailableAgentList

```solidity
function exitAvailableAgentList(address _agentVault) external
```

Exit the publicly available agents list.

NOTE: may only be called by the agent vault owner and after announcement as above.

*Parameters:*

- `agentVault` - Agent vault address.

### getAvailableAgentsList

```solidity
function getAvailableAgentsList(uint256 _start, uint256 _end) external view returns (address[] _agents, uint256 _totalLength)
```

Get (a part of) the list of available agents.

*Parameters:*

- `start` - First index to return from the available agents list.
- `end` - End index (one above last) to return from the available agents list.

*Returns:*
- `agents` - List of available agents in the specified index range.
- `totalLength` - The length of the available agents list.

### getAvailableAgentsDetailedList

```solidity
function getAvailableAgentsDetailedList(uint256 _start, uint256 _end) external view returns (AvailableAgentInfo.Data[] _agents, uint256 _totalLength)
```

Get (a part of) the list of available agents with extra information about agents' fee, min collateral ratio and available collateral (in lots). 

*Parameters:*

- `start` - First index to return from the available agent's list.
- `end` - End index (one above last) to return from the available agent's list.

*Returns:*
- `agents` - List of agents and associated data in the specified indexes.
- `totalLength` - The length of the available agents list.

### reserveCollateral

```solidity
function reserveCollateral(address _agentVault, uint256 _lots, uint256 _maxMintingFeeBIPS, address payable _executor) external payable returns (uint256 _collateralReservationId)
```

Reserve collateral for a minting transaction.

NOTE: if the underlying block isn't updated regularly, it can happen that there is not enough time for the underlying payment. Therefore minters have to verify the current underlying before minting and, if needed, update it by calling `updateCurrentBlock`.

*Parameters:*

- `agentVault` - Agent vault address.
- `lots` - The number of lots for which to reserve collateral.
- `maxMintingFeeBIPS` - The maximum minting fee (BIPS) that can be charged by the agent.
- `executor` - Account that is allowed to execute minting (besides minter and agent).

*Returns:*

- `collateralReservationId` - The unique identifier for the collateral reservation.

### collateralReservationFee

```solidity
function collateralReservationFee(uint256 _lots) external view returns (uint256 _reservationFeeNATWei)
```

Return the collateral reservation fee amount that has to be passed to the `reserveCollateral` method.

NOTE: the amount paid may be larger than the required amount, but the difference is not returned.

*Parameters:*

- `lots` - The number of lots for which to reserve collateral.

*Returns:*

- `reservationFeeNATWei` - The reservation fee in NAT wei

### collateralReservationInfo

```solidity
function collateralReservationInfo(uint256 _collateralReservationId) external view returns (CollateralReservationInfo.Data)
```

Returns data about the collateral reservation for an ongoing minting.

*Parameters:*

- `collateralReservationId` - The collateral reservation ID.

*Returns:*

- `CollateralReservationInfo.Data` - Data on the status of the collateral reservation.

### executeMinting

```solidity
function executeMinting(IPayment.Proof _payment, uint256 _collateralReservationId) external
```

Finish the minting and collect the minted FAssets.

NOTE: may only be called by the minter, the executor appointed by the minter, or the agent owner.

*Parameters:*

- `payment` - Proof of the underlying payment.
- `collateralReservationId` - Collateral reservation ID.

### mintingPaymentDefault

```solidity
function mintingPaymentDefault(IReferencedPaymentNonexistence.Proof _proof, uint256 _collateralReservationId) external
```

Declare payment default for a minting.

NOTE: may only be called by the owner of the agent vault in the collateral reservation request.

*Parameters:*

- `proof` - Proof that the minter didn't perform a minting transaction with correct payment reference on the underlying chain.
- `_collateralReservationId` - ID of the collateral reservation created by the minter.

### confirmClosedMintingPayment

```solidity
function confirmClosedMintingPayment(IPayment.Proof _payment, uint256 _collateralReservationId) external
```

Enables the agent to confirm existence of payments made during minting that were not correct but still credited the agent's account.

NOTE: may only be called by the agent vault owner.

*Parameters:*

- `payment` - Proof of the underlying payment (must have correct payment reference).
- `collateralReservationId` - Corresponding collateral reservation ID.

### unstickMinting

```solidity
function unstickMinting(IConfirmedBlockHeightExists.Proof _proof, uint256 _collateralReservationId) external payable
```

Agent can call this method to unstick a stuck minting.

NOTE: may only be called by the owner of the agent vault in the collateral reservation request.

*Parameters:*

- `proof` - Proof that the attestation query window can not not contain the payment/non-payment proof anymore.
- `collateralReservationId` - Collateral reservation ID.

### selfMint

```solidity
function selfMint(IPayment.Proof _payment, address _agentVault, uint256 _lots) external
```

Perform a self-mint.

NOTE: may only be called by the agent vault owner.

*Parameters:*

- `payment` - Proof of the underlying payment; must contain payment reference.
- `agentVault` - Agent vault address.
- `lots` - Number of lots to mint.

### mintFromFreeUnderlying

```solidity
function mintFromFreeUnderlying(address _agentVault, uint64 _lots) external
```

An agent with enough free underlying mints immediately without any underlying payment.

NOTE: may only be called by the agent vault owner.

*Parameters:*

- `agentVault` - Agent vault address
- `lots` - Number of lots to mint

### redeem

```solidity
function redeem(uint256 _lots, string _redeemerUnderlyingAddressString, address payable _executor) external payable returns (uint256 _redeemedAmountUBA)
```

Redeem (up to) `lots` lots of FAssets. 

*Parameters:*

- `lots` - Number of lots to redeem.
- `redeemerUnderlyingAddressString` - The underlying redeemer address to receive the funds.
- `executor` - The account that is allowed to execute redemption default (besides redeemer and agent).

*Returns:*

- `redeemedAmountUBA` - The actual redeemed amount; may be less than requested if there are not enough redemption tickets available or the maximum redemption ticket limit is reached.

### rejectInvalidRedemption

```solidity
function rejectInvalidRedemption(IAddressValidity.Proof _proof, uint256 _redemptionRequestId) external
```

Rejects a redemption to an invalid address.

NOTE: may only be called by the owner of the agent vault in the redemption request

*Parameters:*

- `proof` - Proof that the address is invalid.
- `redemptionRequestId` - ID of the existing redemption request.

### confirmRedemptionPayment

```solidity
function confirmRedemptionPayment(IPayment.Proof _payment, uint256 _redemptionRequestId) external
```

Confirms a redemption, unlocking the corresponding collateral.

NOTE: may only be called by the owner of the agent vault in the redemption request, except if enough time has passed without confirmation; then it can be called by anybody.

*Parameters:*

- `payment` - Proof of the underlying payment (must contain exact fee amount and correct payment reference).
- `redemptionRequestId` - ID of the existing redemption request

### redemptionPaymentDefault

```solidity
function redemptionPaymentDefault(IReferencedPaymentNonexistence.Proof _proof, uint256 _redemptionRequestId) external
```

Defaults an existing redemption request.

NOTE: may only be called by the redeemer, the executor appointed by the redeemer, or the agent owner.

*Parameters:*

- `proof` - Proof that the agent didn't make a payment with correct payment reference on the underlying chain.
- `redemptionRequestId` - ID of the existing redemption request.

### finishRedemptionWithoutPayment

```solidity
function finishRedemptionWithoutPayment(IConfirmedBlockHeightExists.Proof _proof, uint256 _redemptionRequestId) external
```

Closes a redemption request without payment.

NOTE: may only be called by the owner of the agent vault in the redemption request.

*Parameters:*

- `proof` - Proof that the attestation query window can not not contain the payment/non-payment proof anymore.
- `redemptionRequestId` - ID of an existing, but already defaulted, redemption request.

### redemptionRequestInfo

```solidity
function redemptionRequestInfo(uint256 _redemptionRequestId) external view returns (RedemptionRequestInfo.Data)
```

Returns the data about an ongoing redemption request. 

*Parameters:*

- `redemptionRequestId` - The redemption request ID.

*Returns:*

- `RedemptionRequestInfo.Data` - Data about the redemption request.

### selfClose

```solidity
function selfClose(address _agentVault, uint256 _amountUBA) external returns (uint256 _closedAmountUBA)
```

Agent redeems against their own collateral.

NOTE: may only be called by the agent vault owner.

*Parameters:*

- `agentVault` - Agent vault address.
- `amountUBA` - Amount of FAssets to self-close.

*Returns:*

- `closedAmountUBA` - The actual self-closed amount; may be less than requested if there are not enough redemption tickets available or the maximum redemption ticket limit is reached.

### redemptionQueue

```solidity
function redemptionQueue(uint256 _firstRedemptionTicketId, uint256 _pageSize) external view returns (RedemptionTicketInfo.Data[] _queue, uint256 _nextRedemptionTicketId)
```

Return (part of) the redemption queue.

*Parameters:*

- `firstRedemptionTicketId` - The ticket ID to start listing from; if 0, starts from the beginning
- `pageSize` - the maximum number of redemption tickets to return.

*Returns:*

- `queue` - The (part of) the redemption queue.
- `nextRedemptionTicketId` - The first ticket ID not returned; if the end is reached, returns 0.

### agentRedemptionQueue

```solidity
function agentRedemptionQueue(address _agentVault, uint256 _firstRedemptionTicketId, uint256 _pageSize) external view returns (RedemptionTicketInfo.Data[] _queue, uint256 _nextRedemptionTicketId)
```

Return (part of) the redemption queue for a specific agent.

*Parameters:*

- `agentVault` - The agent vault address of the queried agent.
- `firstRedemptionTicketId` - The ticket ID to start listing from; if 0, starts from the beginning.
- `pageSize` - The maximum number of redemption tickets to return.

*Returns:*

- `queue` - The (part of) the redemption queue for the agent.
- `nextRedemptionTicketId` - First ticket ID not returned; if the end is reached, returns 0.

### convertDustToTicket

```solidity
function convertDustToTicket(address _agentVault) external
```

Converts an agent's dust into an appropriate amount of tickets.

*Parameters:*

- `agentVault` - Agent vault address.

### consolidateSmallTickets

```solidity
function consolidateSmallTickets(uint256 _firstTicketId) external
```

This method converts small tickets to dust, then when the dust exceeds one lot adds it to the ticket.

NOTE: this method can be called by the governance or its executor.

*Parameters:*

- `firstTicketId` - The ticket id of starting ticket; if zero, the starting ticket will be the redemption queue's first ticket ID.

### startLiquidation

```solidity
function startLiquidation(address _agentVault) external returns (uint256 _liquidationStartTs)
```

Checks that the agent's collateral is too low; if true, starts agent's liquidation.
If the agent is already in liquidation, returns the timestamp when liquidation started.

*Parameters:*

- `agentVault` - Agent vault address.

*Returns:*

- `liquidationStartTs` - Timestamp when liquidation started.

### liquidate

```solidity
function liquidate(address _agentVault, uint256 _amountUBA) external returns (uint256 _liquidatedAmountUBA, uint256 _amountPaidVault, uint256 _amountPaidPool)
```

Burns up to `_amountUBA` FAssets owned by the caller and pays the caller the corresponding amount of native currency with premium.
If the agent isn't in liquidation yet but satisfies conditions for liquidation, automatically puts the agent in liquidation status.

*Parameters:*

- `agentVault` - Agent vault address.
- `amountUBA` - The amount of FAssets to liquidate.

*Returns:*

- `liquidatedAmountUBA` - Liquidated amount of FAsset.
- `amountPaidVault` - Amount paid to liquidator in agent's vault collateral.
- `amountPaidPool` - Amount paid to liquidator in NAT from pool.

### endLiquidation

```solidity
function endLiquidation(address _agentVault) external
```

Stops liquidation process if eligible.

*Parameters:*

- `agentVault` - Agent vault address.

### illegalPaymentChallenge

```solidity
function illegalPaymentChallenge(IBalanceDecreasingTransaction.Proof _payment, address _agentVault) external
```

Challenges an illegal payment, sending the agent into full liquidation.

*Parameters:*

- `payment` - Proof of an illegal transaction from the agent's underlying address.
- `agentVault` - Agent vault address.

### doublePaymentChallenge

```solidity
function doublePaymentChallenge(IBalanceDecreasingTransaction.Proof _payment1, IBalanceDecreasingTransaction.Proof _payment2, address _agentVault) external
```

Called with proofs of two payments made from the agent's underlying address with the same payment reference. On success, immediately triggers full agent liquidation and rewards the caller.

*Parameters:*

- `payment1` - Proof of first payment from the agent's underlying address.
- `payment2` - Proof of second payment from the agent's underlying address whose reference matches `payment1`.
- `agentVault` - Agent vault address.

### freeBalanceNegativeChallenge

```solidity
function freeBalanceNegativeChallenge(IBalanceDecreasingTransaction.Proof[] _payments, address _agentVault) external
```

Immediately triggers full agent liquidation for agent with negative free balance and rewards the caller.

*Parameters:*

- `payments` - Proofs of several distinct payments from the agent's underlying address.
- `agentVault` - Agent vault address.

### addAlwaysAllowedMinterForAgent

```solidity
function addAlwaysAllowedMinterForAgent(address _agentVault, address _minter) external
```

Adds an always allowed minter for an agent.

*Parameters:*

- `agentVault` - Agent vault address.
- `minter` - Allowed minting address.

### agentPing

```solidity
function agentPing(address _agentVault, uint256 _query) external
```

Used for liveness checks. Emits an `AgentPing` event.

*Parameters:*

- `agentVault` - The agent vault of the agent being pinged.
- `query` - ID of the query.

### agentPingResponse

```solidity
function agentPingResponse(address _agentVault, uint256 _query, string _response) external
```

Response to AgentPing event. Emits an `AgentPingResponse` event identifying the owner.

NOTE: may only be called by the agent vault owner

*Parameters:*

- `agentVault` - Agent vault address.
- `query` - ID of the query being responded to.
- `response` - Response data for the query.

### alwaysAllowedMintersForAgent

```solidity
function alwaysAllowedMintersForAgent(address _agentVault) external view returns (address[])
```

Recovers the always allowed minters for an agent.

*Parameters:*

- `agentVault` - Agent vault address.

*Returns:*

- `address` - List of always allowed minter addresses for the agent.

### cancelReturnFromCoreVault

```solidity
function cancelReturnFromCoreVault(address _agentVault) external
```

Cancels a requested return from core vault that has not been completed, releasing the agent's reserved collateral.

*Parameters:*

- `agentVault` - Agent vault address.

### confirmCoreVaultDonation

```solidity
function confirmCoreVaultDonation(IXRPPayment.Proof _payment) external
```

Confirm a donation payment made to the core vault underlying address.

*Parameters:*

- _payment` - Payment proof.

### confirmReturnFromCoreVault

```solidity
function confirmReturnFromCoreVault(IPayment.Proof _payment, address _agentVault) external
```

Confirm the payment from core vault to the agent's underlying address. Adds the reserved funds to the agent's backing.

*Parameters:*

- `payment` - Payment proof.
- `agentVault` - Agent vault address.

### confirmXRPRedemptionPayment

```solidity
function confirmXRPRedemptionPayment(IXRPPayment.Proof _payment, uint256 _redemptionRequestId) external
```

Unlocks the collateral corresponding to a redemption payment, confirming that the payment was made.

NOTE: Distinct from `confirmRedemptionPayment` as this one accepts `IXRPPayment` proof types and supports destination tags.

NOTE: May only be called by the owner of the agent vault in the redemption request except if enough time has passed without confirmation; then it can be called by anybody.

*Parameters:*

- `payment` - Proof of the underlying payment; must contain exact fee amount and correct payment reference.
- `redemptionRequestId` - ID of the existing redemption request.

### coreVaultAvailableAmount

```solidity
function coreVaultAvailableAmount() external view returns (uint256 _immediatelyAvailableUBA, uint256 _totalAvailableUBA)
```

Returns the amount available on the core vault, the maximum amount that can be returned to agent or redeemed directly from the core vault.

*Returns:*

- `immediatelyAvailableUBA` - The amount on the core vault operating account.
- `totalAvailableUBA` - The total amount on the core vault, including all escrows.

### directMintingDelayState

```solidity
function directMintingDelayState(bytes32 _transactionId) external view returns (IDirectMinting.DirectMintingDelayState _delayState, uint256 _allowedAt, uint256 _startedAt)
```

Gets the delay state of a direct minting.

*Parameters:*

- `transactionId` - The direct minting underlying payment transaction ID.

*Returns:*

- `delayState` - The delay state of the direct minting.
- `allowedAt` - The timestamp at which the minting can be executed.
- `startedAt` - The timestamp at which the minting was started.

### directMintingPaymentAddress

```solidity
function directMintingPaymentAddress() external view returns (string)
```

Gets the payment address to which the underlying assets must be sent for direct minting.

*Returns:*

- `string` - The payment address for direct mintings.

### effectiveSystemRedemptionFeeBIPS

```solidity
function effectiveSystemRedemptionFeeBIPS() external view returns (uint256)
```

The system redemption fee in BIPS that is actually charged, taking the fee receiver into account. 

*Returns:*
- `uint256` - Equals `systemRedemptionFeeBIPS()` when a fee receiver is set, and zero otherwise.

### executeDirectMinting

```solidity
function executeDirectMinting(IXRPPayment.Proof _payment) external payable
```

Executes minting directly, without a collateral reservation. The payment must be made to the fAsset Core Vault's XRP address.

*Parameters:*

- `payment` - The XRP payment proof data.

### executeDirectMintingWithData

```solidity
function executeDirectMintingWithData(IXRPPayment.Proof _payment, bytes _data) external payable
```

Executes minting directly, without a collateral reservation. The payment must be made to the FAsset Core Vault's XRP address.

NOTE: unlike `executeDirectMinting`, this form is only allowed for minting to smart accounts.

*Parameters:*

- `payment` - the XRP payment proof data.
- `data` - Additional data sent to the smart account manager, as specified in the memo data.

### facetAddress

```solidity
function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_)
```

Gets the facet that supports the given selector.

If facet is not found return address(0).

*Parameters:*

- `functionSelector` - The function selector to be checked.

*Returns:*

- `facetAddress` - The facet address.

### facetAddresses

```solidity
function facetAddresses() external view returns (address[] facetAddresses_)
```

Get all the facet addresses used by a diamond.

*Returns:*

- `facetAddresses` - Addresses of facets used.

### facetFunctionSelectors

```solidity
function facetFunctionSelectors(address _facet) external view returns (bytes4[] facetFunctionSelectors_)
```

Gets all the function selectors supported by a specific facet.

*Parameters:*

- `facet` - The facet address.

*Returns:*

- `facetFunctionSelectors` - The facets function selectors.

### facets

```solidity
function facets() external view returns (IDiamondLoupe.Facet[] facets_)
```

Gets all facet addresses and their four byte function selectors.

*Returns:*

- `facets` - A list of facet addresses and function selectors.

### getCoreVaultDonationTag

```solidity
function getCoreVaultDonationTag() external view returns (uint256)
```

*Returns:*
- `uint256` - The donation tag for the core vault.

### getCoreVaultManager

```solidity
function getCoreVaultManager() external view returns (address)
```

*Returns:*
- `address` - The address of the core vault manager contract.

### getCoreVaultMinimumAmountLeftBIPS

```solidity
function getCoreVaultMinimumAmountLeftBIPS() external view returns (uint256)
```

*Returns:*
- `uint256` - The minimum amount of funds allowed to be left in the core vault, in BIPS.

### getCoreVaultMinimumRedeemLots

```solidity
function getCoreVaultMinimumRedeemLots() external view returns (uint256)
```

*Returns*:
- `uint256` - The minimum amount of lots that can be redeemed from the core vault in a single transaction.

### getCoreVaultNativeAddress

```solidity
function getCoreVaultNativeAddress() external view returns (address)
```

*Returns:*
- `address` - The address of the core vault.

### getCoreVaultRedemptionFeeBIPS

```solidity
function getCoreVaultRedemptionFeeBIPS() external view returns (uint256)
```

*Returns:*
- `uint256` - The redemption fee (in BIPS) of the core vault.

### getCoreVaultTransferDefaultPenaltyBIPS

```solidity
function getCoreVaultTransferDefaultPenaltyBIPS() external view returns (uint256)
```

*Returns:*
- `uint256` - The penalty (in BIPS) for defaulting on core vault trasfers.

### getCoreVaultTransferTimeExtensionSeconds

```solidity
function getCoreVaultTransferTimeExtensionSeconds() external view returns (uint256)
```

*Returns:*
- `uint256` - The additional time allowed to perform transfers to the core vault on top of the regular transfer time.

### getDirectMintingDailyLimitUBA

```solidity
function getDirectMintingDailyLimitUBA() external view returns (uint256)
```

*Returns:*
- `uint256` - The maximum amount (in UBA) of direct minting permitted.

### getDirectMintingDailyLimiterState

```solidity
function getDirectMintingDailyLimiterState() external view returns (uint64 _windowStartTimestamp, uint64 _mintedInCurrentWindow)
```

*Returns:*
- `windowStartTimestamp` - The starting timestamp of the current direct minting window.
- `mintedInCurrentWindow` - The amount minted in the current direct minting window.

### getDirectMintingExecutorFeeUBA

```solidity
function getDirectMintingExecutorFeeUBA() external view returns (uint256)
```

*Returns:*
- `uint256` - The executor fee (in UBA) for direct minting.

### getDirectMintingFeeBIPS

```solidity
function getDirectMintingFeeBIPS() external view returns (uint256)
```

*Returns:*
- `uint256` - The direct minting fee (in BIPS).

### getDirectMintingFeeReceiver

```solidity
function getDirectMintingFeeReceiver() external view returns (address)
```

*Returns:*
- `address` - The address that receives direct minting fees.

### getDirectMintingHourlyLimitUBA

```solidity
function getDirectMintingHourlyLimitUBA() external view returns (uint256)
```

*Returns:*
- `uint256` - The hourly limit on direct minting (in UBA)


### getDirectMintingHourlyLimiterState

```solidity
function getDirectMintingHourlyLimiterState() external view returns (uint64 _windowStartTimestamp, uint64 _mintedInCurrentWindow)
```

*Returns:*
- `windowStartTimestamp` - The starting timestamp of the current hourly direct minting window.
- `mintedInCurrentWindow` - The amount minted in the current hourly direct minting window.

### getDirectMintingLargeMintingDelaySeconds

```solidity
function getDirectMintingLargeMintingDelaySeconds() external view returns (uint256)
```

*Returns:*
- `uint256` - The minting delay (in seconds) for large mintings.

### getDirectMintingLargeMintingThresholdUBA

```solidity
function getDirectMintingLargeMintingThresholdUBA() external view returns (uint256)
```

*Returns:*
- `uint256` - The threshold (in UBA) for large mintings.

### getDirectMintingMinimumFeeUBA

```solidity
function getDirectMintingMinimumFeeUBA() external view returns (uint256)
```

*Returns:*
- `uint256` - The minimum fee (in UBA) for direct mintings.

### getDirectMintingOthersCanExecuteAfterSeconds

```solidity
function getDirectMintingOthersCanExecuteAfterSeconds() external view returns (uint256)
```

*Returns:*
- `uint256` - The amount of seconds after which direct mintings can be executed by other entities.

### getDirectMintingsUnblockUntilTimestamp

```solidity
function getDirectMintingsUnblockUntilTimestamp() external view returns (uint256)
```


*Returns:*
- `uint256` - The timestamp after which direct mintings are unblocked (if currently blocked).

### getMintingTagManager

```solidity
function getMintingTagManager() external view returns (address)
```

*Returns:*
- `address` - The address of the minting tag manager.


### getSmartAccountManager

```solidity
function getSmartAccountManager() external view returns (address)
```

*Returns:*
- `address` - The address of the smart account manager.

### markUnblockedDirectMintingAllowed

```solidity
function markUnblockedDirectMintingAllowed(bytes32 _transactionId) external
```

If the minter has set an allowed executor, it has the exclusive right to execute minting for a fixed time after the minting is allowed to execute; begins the exclusive period.

NOTE: this method is intentionally callable by anybody, not just allowed executor, as it is in the interest of other executors to call it as soon as mintings are unblocked by governance.

*Parameters:*

- `transactionId` Transaction ID of the delayed minting.

### maximumTransferToCoreVault

```solidity
function maximumTransferToCoreVault(address _agentVault) external view returns (uint256 _maximumTransferUBA, uint256 _minimumLeftAmountUBA)
```

Return the maximum amount that can be transferred to the core vault and the minimum amount that has to remain on the agent vault's underlying address.

*Parameters:*

- `agentVault` - The agent vault address

*Returns:*

- `maximumTransferUBA` - Maximum amount (in UBA) that can be transferred to the core vault.
- `minimumLeftAmountUBA` - The minimum amount (in UBA) that has to remain on the agent vault's underlying address after the transfer.

### minimumRedeemAmountUBA

```solidity
function minimumRedeemAmountUBA() external view returns (uint256)
```

*Returns:*

- `uint256` - The minimum amount (in UBA) allowed for redemption with tag redemptions.

### redeemAmount

```solidity
function redeemAmount(uint256 _amountUBA, string _redeemerUnderlyingAddressString, address payable _executor) external payable returns (uint256 _redeemedAmountUBA)
```

Redeem (up to) `_amountUBA` FAssets. Like `redeem`, but accepts an arbitrary amount in UBA instead of whole lots. 

*Parameters:*

- `amountUBA` - Amount of redeemer's FAssets that will be burned.
- `redeemerUnderlyingAddressString` - The underlying address that receives the redemption.
- `executor` - The account that is allowed to execute redemption default, besides redeemer and agent.

*Returns:*

- `redeemedAmountUBA` - The actual redeemed amount; may be less than requested if there are not enough redemption tickets available or the maximum redemption ticket limit is reached.

### redeemFromCoreVault

```solidity
function redeemFromCoreVault(uint256 _lots, string _redeemerUnderlyingAddress) external
```

Directly redeem from core vault by a user holding FAssets.

*Parameters:*

- `lots` - the number of lots to redeem; must be larger than `coreVaultMinimumRedeemLots` setting.
- `redeemerUnderlyingAddress` - The underlying address to which the assets will be redeemed.

### redeemWithTag

```solidity
function redeemWithTag(uint256 _amountUBA, string _redeemerUnderlyingAddressString, address payable _executor, uint256 _destinationTag) external payable returns (uint256 _redeemedAmountUBA)
```

Redeem (up to) `amountUBA` FAssets, with tag.

*Parameters:*

- `amountUBA` - Amount of redeemer's FAssets that will be burned.
- `redeemerUnderlyingAddressString` - The underlying address which will receive the redemption.
- `executor` - The account that is allowed to execute redemption default, besides redeemer and agent.
- `_destinationTag` - The destination tag that is required in the redemption payment (only for XRP).

*Returns:*

- `redeemedAmountUBA` - The actual redeemed amount; may be less than requested if there are not enough redemption tickets available or the maximum redemption ticket limit is reached.

### redeemWithTagSupported

```solidity
function redeemWithTagSupported() external view returns (bool)
```

If false, calling `redeemWithTag` will revert.
For now, only XRP chain supports destination tags, so this flag will be true only on XRP network.

*Returns:*
- `bool` - Whether or not `redeemWithTag` will succeed.

### redemptionPaymentExtensionSeconds

```solidity
function redemptionPaymentExtensionSeconds() external view returns (uint256)
```

*Returns:*
- `uint256` - The current additional time allowed for redemption payments, relevant when there are many concurrent redemptions.

### removeAlwaysAllowedMinterForAgent

```solidity
function removeAlwaysAllowedMinterForAgent(address _agentVault, address _minter) external
```

Removes a minter from an agent's list of always allowed minters.

*Parameters:*

- `agentVault` - AgentVaultAddress.
- `minter` - Minter address.

### requestReturnFromCoreVault

```solidity
function requestReturnFromCoreVault(address _agentVault, uint256 _lots) external
```

Request that core vault transfers funds to the agent's underlying address, which makes them available for redemptions. 

NOTE: only agent vault owner can call

NOTE: there can be only one active return request (until it is confirmed or cancelled).

*Parameters:*

- `AgentVault` - Agent vault address.
- `lots` - Number of lots.

### setCoreVaultManager

```solidity
function setCoreVaultManager(address _coreVaultManager) external
```

Sets core vault manager address.

*Parameters:*

- `coreVaultManager` - Address set as core vault manager.

### setCoreVaultMinimumAmountLeftBIPS

```solidity
function setCoreVaultMinimumAmountLeftBIPS(uint256 _minimumAmountLeftBIPS) external
```

Sets core vault manager minimum allowed funds.

*Parameters:*

- `minimumAmountLeftBIPS` - Amount (in BIPS) set as core vault minimum amount left.

```solidity
function setCoreVaultMinimumRedeemLots(uint256 _minimumRedeemLots) external
```

Sets minimum amount of lots allowed for a core vault redemption.

*Parameters:*

- `minimumRedeemLots` - Minimum amount of lots in a core vault redemption.

### setCoreVaultNativeAddress

```solidity
function setCoreVaultNativeAddress(address payable _nativeAddress) external
```

Sets native address of core vault.

*Parameters:*

- `nativeAddress` - Address set as native address.

### setCoreVaultRedemptionFeeBIPS

```solidity
function setCoreVaultRedemptionFeeBIPS(uint256 _redemptionFeeBIPS) external
```

Sets core vault's redemption fee.

*Parameters:*

- `redemptionFeeBIPS` - Redemption fee (in BIPS) for core vault.

### setCoreVaultTransferDefaultPenaltyBIPS

```solidity
function setCoreVaultTransferDefaultPenaltyBIPS(uint256 _transferDefaultPenaltyBIPS) external
```

Sets core vault's penalty fee for defaulted transfers.

*Parameters:*

- `transferDefaultPenaltyBIPS` - Penalty fee for defaulted core vault transfers.

### setCoreVaultTransferTimeExtensionSeconds

```solidity
function setCoreVaultTransferTimeExtensionSeconds(uint256 _transferTimeExtensionSeconds) external
```

Sets additional transfer time for core vault transfers (on top of standard payment window).

*Parameters:*

- `transferTimeExtensionSeconds` - The additional transfer time set.

### setDirectMintingDailyLimitUBA

```solidity
function setDirectMintingDailyLimitUBA(uint256 _dailyLimitUBA) external
```

*Parameters:*

- `dailyLimitUba` - The daily limit (in UBA) of direct mintings.

### setDirectMintingExecutorFee

```solidity
function setDirectMintingExecutorFee(uint256 _executorFeeUBA) external
```

*Parameters:*

- `executorFeeUBA` - The direct minting executor fee.

### setDirectMintingFee

```solidity
function setDirectMintingFee(uint256 _mintingFeeBIPS, uint256 _minimumMintingFeeUBA) external
```

*Parameters:*

- `mintingFeeBIPS` - The direct minting fee (in BIPS).
- `minimumMintingFeeUBA` - The minimum minting fee due before a minting is successful, in UBA.

### setDirectMintingFeeReceiver

```solidity
function setDirectMintingFeeReceiver(address _mintingFeeReceiver) external
```

*Parameters:*
- `mintingFeeReceiver` - The address that receives direct minting fees.

### setDirectMintingHourlyLimitUBA

```solidity
function setDirectMintingHourlyLimitUBA(uint256 _hourlyLimitUBA) external
```

*Parameters:*

- `hourlyLimitUBA` - The maximum amount that can be directly minted in an hour, in UBA.

### setDirectMintingLargeMintingThrottling

```solidity
function setDirectMintingLargeMintingThrottling(uint256 _largeMintingThresholdUBA, uint256 _largeMintingDelaySeconds) external
```

*Parameters:*

- `largeMintingThresholdUBA` - The amount (in UBA) after which a minting becomes a large minting.
- `largeMintingDelaySeconds` - The number of seconds a large minting must be delayed before execution.

### setDirectMintingOthersCanExecuteAfterSeconds

```solidity
function setDirectMintingOthersCanExecuteAfterSeconds(uint256 _seconds) external
```

*Parameters:*

- `seconds` - The amount of seconds after which other entities can execute direct mintings.

### setMinimumRedeemAmountUBA

```solidity
function setMinimumRedeemAmountUBA(uint256 _valueUBA) external
```

Set the minimum amount in UBA for redemption with tag. 

NOTE: may only be called by the governance.

*Parameters:*

- `valueUBA` - The minimum redeem with tag amount (in UBA); must be at most 10 lots.

### setMintingTagManager

```solidity
function setMintingTagManager(address _mintingTagManager) external
```

*Parameters:*
- `mintingTagManager` - The minting tag manager address.

### setRedemptionPaymentExtensionSeconds

```solidity
function setRedemptionPaymentExtensionSeconds(uint256 _value) external
```

Adds additional time for redemption payments to be made.

*Parameters:*
- `value` - The number of extra seconds allowed for redemption payments.

### setSmartAccountManager

```solidity
function setSmartAccountManager(address _smartAccountManager) external
```

*Parameters:*
- `smartAccountManager` - The smart account manager address.

### setSystemRedemptionFeeBIPS

```solidity
function setSystemRedemptionFeeBIPS(uint256 _feeBIPS) external
```

Set the part of the redemption value, in BIPS, that is charged as the system redemption fee. Setting it to zero disables the system redemption fee.

NOTE: may only be called by the governance.

*Parameters:*

- `feeBIPS` - The new system redemption fee (in BIPS); must be less than 10000.

### setSystemRedemptionFeeReceiver

```solidity
function setSystemRedemptionFeeReceiver(address _receiver) external
```

Set the address to which the system redemption fee is re-minted. Setting it to address(0) disables the system redemption fee.

NOTE: may only be called by the governance.

*Parameters:*

- `receiver` - The new system redemption fee receiver

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```

Returns true if this contract implements the interface defined by `interfaceId`.

*Parameters:*
- `interfaceId` - The interface ID in question.

*Returns:*
- `bool` - Whether or not the contract implements the specified interface.

### systemRedemptionFeeBIPS

```solidity
function systemRedemptionFeeBIPS() external view returns (uint256)
```

Returns the part of the redemption value, in BIPS, that is charged as a system fee at the creation of every redemption request (except for the transfers to the core vault).

*Returns:*

- `uint256` - The system fee (in BIPS) for redemption requests.

### systemRedemptionFeeReceiver

```solidity
function systemRedemptionFeeReceiver() external view returns (address)
```

Returns the address to which the system redemption fee is re-minted.

*Returns:*

- `address` - The address receiving system redemption fees; if 0, indicates no system redemption fee.

### transferToCoreVault

```solidity
function transferToCoreVault(address _agentVault, uint256 _amountUBA) external
```

Called by an agent to transfer their backing to core vault and release corresponding collateral.

NOTE: only agent vault owner can call

*Parameters:*

- `agentVault` - Agent vault address
- `amountUBA` - The amount to transfer to the core vault

### unblockDirectMintingsUntil

```solidity
function unblockDirectMintingsUntil(uint256 _timestamp) external
```

Unblocks direct mintings until the given timestamp.

NOTE: only governance can call this function.

*Parameters:*

- `timestamp` - The timestamp until which direct mintings are unblocked

### xrpRedemptionPaymentDefault

```solidity
function xrpRedemptionPaymentDefault(IXRPPaymentNonexistence.Proof _proof, uint256 _redemptionRequestId) external
```

If the agent doesn't transfer the redeemed underlying assets in time, the redeemer calls this method and receives payment in collateral instead. The agent can also call default if the redeemer is unresponsive.

NOTE: Distinct from `redemptionPaymentDefault` as this one accepts `IXRPPayment` proof type and supports destination tags.

*Parameters:*

- `proof` - Proof that the agent didn't pay with correct payment reference on the underlying chain.
- `redemptionRequestId` - ID of the existing redemption request.

## Events

### AgentAvailable

```solidity
event AgentAvailable(address indexed agentVault, uint256 feeBIPS, uint256 mintingVaultCollateralRatioBIPS, uint256 mintingPoolCollateralRatioBIPS, uint256 freeCollateralLots)
```

Agent was added to the list of available agents and can accept collateral reservation requests.

### AgentCollateralTypeChanged

```solidity
event AgentCollateralTypeChanged(address indexed agentVault, uint8 collateralClass, address token)
```

Agent or agent's collateral pool has changed token contract.

### AgentDestroyAnnounced

```solidity
event AgentDestroyAnnounced(address indexed agentVault, uint256 destroyAllowedAt)
```

Agent has announced destroy (close) of agent vault and will be able to perform destroy after the timestamp `destroyAllowedAt`.

### AgentDestroyed

```solidity
event AgentDestroyed(address indexed agentVault)
```

Agent has destroyed (closed) the agent vault.

### AgentPing

```solidity
event AgentPing(address indexed agentVault, address indexed sender, uint256 query)
```

Agent bot liveness check.

### AgentPingResponse

```solidity
event AgentPingResponse(address indexed agentVault, address indexed owner, uint256 query, string response)
```

Response to agent liveness check.

### AgentSettingChangeAnnounced

```solidity
event AgentSettingChangeAnnounced(address indexed agentVault, string name, uint256 value, uint256 validAt)
```

Agent has initiated setting change (fee or some agent collateral ratio change). The setting change can be executed after the timestamp `validAt`.

### AgentSettingChanged

```solidity
event AgentSettingChanged(address indexed agentVault, string name, uint256 value)
```

Agent has executed setting change (fee or some agent collateral ratio change).

### AgentVaultCreated

```solidity
event AgentVaultCreated(address indexed owner, address indexed agentVault, IAssetManagerEvents.AgentVaultCreationData creationData)
```

A new agent vault was created.

### AvailableAgentExitAnnounced

```solidity
event AvailableAgentExitAnnounced(address indexed agentVault, uint256 exitAllowedAt)
```

Agent exited from available agents list. The agent can exit the available list after the timestamp `exitAllowedAt`.

### AvailableAgentExited

```solidity
event AvailableAgentExited(address indexed agentVault)
```

Agent exited from available agents list.

### CollateralRatiosChanged

```solidity
event CollateralRatiosChanged(uint8 collateralClass, address collateralToken, uint256 minCollateralRatioBIPS, uint256 safetyMinCollateralRatioBIPS)
```

System defined collateral ratios for the token have changed (minimal and safety collateral ratio).

### CollateralReservationDeleted

```solidity
event CollateralReservationDeleted(address indexed agentVault, address indexed minter, uint256 indexed collateralReservationId, uint256 reservedAmountUBA)
```

Both minter and agent failed to present any proof within the attestation time window, so the agent called `unstickMinting` to release reserved collateral.

### CollateralReserved

```solidity
event CollateralReserved(address indexed agentVault, address indexed minter, uint256 indexed collateralReservationId, uint256 valueUBA, uint256 feeUBA, uint256 firstUnderlyingBlock, uint256 lastUnderlyingBlock, uint256 lastUnderlyingTimestamp, string paymentAddress, bytes32 paymentReference, address executor, uint256 executorFeeNatWei)
```

Minter reserved collateral, paid the reservation fee, and is expected to pay the underlying funds.
Agent's collateral was reserved.

### CollateralTypeAdded

```solidity
event CollateralTypeAdded(uint8 collateralClass, address token, uint256 decimals, bool directPricePair, string assetFtsoSymbol, string tokenFtsoSymbol, uint256 minCollateralRatioBIPS, uint256 safetyMinCollateralRatioBIPS)
```

New collateral token has been added.

### ConfirmedClosedMintingPayment

```solidity
event ConfirmedClosedMintingPayment(address indexed agentVault, bytes32 transactionHash, uint256 depositedUBA)
```

Emitted when a late or too small payment for an already defaulted or expired minting is confirmed; equivalent to an agent performing underlying topup.

### ContractChanged

```solidity
event ContractChanged(string name, address value)
```

A contract in the settings has changed.

### CoreVaultFundsAdded

```solidity
event CoreVaultFundsAdded(uint256 amountUBA)
```

Funds have been added to the core vault operating account.

### CoreVaultRedemptionRequested

```solidity
event CoreVaultRedemptionRequested(address indexed redeemer, string paymentAddress, bytes32 paymentReference, uint256 valueUBA, uint256 feeUBA)
```

Redemption was requested from a core vault. Can only be redeemed to a payment address from to the `allowedDestinations` list in the core vault manager.

### CurrentUnderlyingBlockUpdated

```solidity
event CurrentUnderlyingBlockUpdated(uint256 underlyingBlockNumber, uint256 underlyingBlockTimestamp, uint256 updatedAt)
```

Current underlying block number or timestamp has been updated.

### DirectMintingDelayed

```solidity
event DirectMintingDelayed(bytes32 transactionId, uint256 amount, uint256 executionAllowedAt)
```

The identified direct minting was delayed.

### DirectMintingExecuted

```solidity
event DirectMintingExecuted(bytes32 transactionId, address targetAddress, address executor, uint256 mintedAmountUBA, uint256 mintingFeeUBA, uint256 executorFeeUBA)
```

The identified direct minting was executed.

### DirectMintingExecutedToSmartAccount

```solidity
event DirectMintingExecutedToSmartAccount(bytes32 transactionId, string sourceAddress, address executor, uint256 mintedAmountUBA, uint256 mintingFeeUBA, bytes memoData)
```

The identified direct minting was executed to a smart account.

### DirectMintingPaymentTooSmallForFee

```solidity
event DirectMintingPaymentTooSmallForFee(bytes32 transactionId, uint256 receivedAmountUBA, uint256 minimumMintingFeeUBA)
```

The identified direct minting was too small to reach the minimum fee.

### DirectMintingsUnblocked

```solidity
event DirectMintingsUnblocked(uint256 startedUntilTimestamp)
```

Direct mintings were unblocked.

### DuplicatePaymentConfirmed

```solidity
event DuplicatePaymentConfirmed(address indexed agentVault, bytes32 transactionHash1, bytes32 transactionHash2)
```

Two transactions with the same payment reference, both from the agent's underlying address, were proved.
Whole agent's position goes into liquidation.
The challenger is rewarded from the agent's collateral.

### DustChanged

```solidity
event DustChanged(address indexed agentVault, uint256 dustUBA)
```

Due to lot size change, some dust was created for this agent during redemption.
Value `dustUBA` is the new amount of dust.

### EmergencyPauseCanceled

```solidity
event EmergencyPauseCanceled()
```

Emergency pause was canceled.

### EmergencyPauseTotalDurationReset

```solidity
event EmergencyPauseTotalDurationReset()
```

Emergency pause total duration was reset by the governance.

### EmergencyPauseTriggered

```solidity
event EmergencyPauseTriggered(EmergencyPause.Level externalLevel, uint256 externalPausedUntil, EmergencyPause.Level governanceLevel, uint256 governancePausedUntil)
```

Emergency pause was triggered.

### FullLiquidationStarted

```solidity
event FullLiquidationStarted(address indexed agentVault, uint256 timestamp)
```

Agent entered liquidation state due to illegal payment.
Full liquidation will always liquidate the whole agent's position and the agent can never use the same vault and underlying address for minting again.

### IllegalPaymentConfirmed

```solidity
event IllegalPaymentConfirmed(address indexed agentVault, bytes32 transactionHash)
```

An unexpected transaction from the agent's underlying address was proved.
Whole agent's position goes into liquidation.
The challenger is rewarded from the agent's collateral.

### LargeDirectMintingDelayed

```solidity
event LargeDirectMintingDelayed(bytes32 transactionId, uint256 amount, uint256 executionAllowedAt)
```

A direct minting was delayed as it was deemed to be large.

### LiquidationEnded

```solidity
event LiquidationEnded(address indexed agentVault)
```

Agent exited liquidation state as agent's position was healthy again and not in full liquidation.

### LiquidationPerformed

```solidity
event LiquidationPerformed(address indexed agentVault, address indexed liquidator, uint256 valueUBA, uint256 paidVaultCollateralWei, uint256 paidPoolCollateralWei)
```

Some of the agent's position was liquidated, by burning liquidator's fassets.
Liquidator was paid in collateral with extra.

### LiquidationStarted

```solidity
event LiquidationStarted(address indexed agentVault, uint256 timestamp)
```

Agent entered liquidation state due to unhealthy position.

### MintingExecuted

```solidity
event MintingExecuted(address indexed agentVault, uint256 indexed collateralReservationId, uint256 mintedAmountUBA, uint256 agentFeeUBA, uint256 poolFeeUBA)
```

Minter paid underlying funds in time and received the FAssets.
The agent's collateral is locked.

### MintingPaused

```solidity
event MintingPaused(bool paused)
```

Minting was paused/unpaused by the governance.

### MintingPaymentDefault

```solidity
event MintingPaymentDefault(address indexed agentVault, address indexed minter, uint256 indexed collateralReservationId, uint256 reservedAmountUBA)
```

Minter failed to pay underlying funds in time.
Collateral reservation fee was paid to the agent.
Reserved collateral was released.

### PoolTokenRedemptionAnnounced

```solidity
event PoolTokenRedemptionAnnounced(address indexed agentVault, uint256 amountWei, uint256 withdrawalAllowedAt)
```

Agent has announced a withdrawal of collateral and will be able to redeem the announced amount of pool tokens after the timestamp `withdrawalAllowedAt`.
If withdrawal was canceled (announced with amount 0), `amountWei` and `withdrawalAllowedAt` are zero.

### RedeemedInCollateral

```solidity
event RedeemedInCollateral(address indexed agentVault, address indexed redeemer, uint256 redemptionAmountUBA, uint256 paidVaultCollateralWei)
```

Due to self-close exit, some of the agent's backed fAssets were redeemed, but the redemption was immediately paid in collateral so no redemption process is started.

### RedemptionAmountIncomplete

```solidity
event RedemptionAmountIncomplete(address indexed redeemer, uint256 remainingAmountUBA)
```

In case there were not enough tickets or more than the maximum allowed number would have to be redeemed, only partial redemption is done and the `remainingAmountUBA` of the FAssets are returned to the redeemer.

### RedemptionDefault

```solidity
event RedemptionDefault(address indexed agentVault, address indexed redeemer, uint256 indexed requestId, uint256 redemptionAmountUBA, uint256 redeemedVaultCollateralWei, uint256 redeemedPoolCollateralWei)
```

The time for redemption payment is over and payment proof was not provided. Redeemer was paid in the collateral (with extra). The rest of the agent's collateral is released. The corresponding amount of underlying currency, held by the agent, is released and the agent can withdraw it after announcement.

### RedemptionPaymentBlocked

```solidity
event RedemptionPaymentBlocked(address indexed agentVault, address indexed redeemer, uint256 indexed requestId, bytes32 transactionHash, uint256 redemptionAmountUBA, int256 spentUnderlyingUBA)
```

Agent provided the proof that redemption payment was attempted and failed due to the redeemer's address being blocked.
Redeemer is not paid and the agent's collateral is released, along with underlying currency.

### RedemptionPaymentFailed

```solidity
event RedemptionPaymentFailed(address indexed agentVault, address indexed redeemer, uint256 indexed requestId, bytes32 transactionHash, int256 spentUnderlyingUBA, string failureReason)
```

Agent provided the proof that redemption payment was attempted, but failed due to his own error.
Also triggers payment default, unless the redeemer has done it already.

### RedemptionPerformed

```solidity
event RedemptionPerformed(address indexed agentVault, address indexed redeemer, uint256 indexed requestId, bytes32 transactionHash, uint256 redemptionAmountUBA, int256 spentUnderlyingUBA)
```

Agent provided proof of redemption payment.
Agent's collateral is released.

### RedemptionPoolFeeMinted

```solidity
event RedemptionPoolFeeMinted(address indexed agentVault, uint256 indexed requestId, uint256 poolFeeUBA)
```

At the end of a successful redemption, part of the redemption fee is re-minted as FAssets and paid to the agent's collateral pool as fee.

### RedemptionRejected

```solidity
event RedemptionRejected(address indexed agentVault, address indexed redeemer, uint256 indexed requestId, uint256 redemptionAmountUBA)
```

Agent rejected the redemption payment because the redeemer's address is invalid.

### RedemptionRequestIncomplete

```solidity
event RedemptionRequestIncomplete(address indexed redeemer, uint256 remainingLots)
```

IThere were not enough tickets for a redemption or more than the maximum allowed number would have to be redeemed; only partial redemption was done and the `remainingLots` lots of the fassets are returned to the redeemer.

### RedemptionRequested

```solidity
event RedemptionRequested(address indexed agentVault, address indexed redeemer, uint256 indexed requestId, string paymentAddress, uint256 valueUBA, uint256 feeUBA, uint256 firstUnderlyingBlock, uint256 lastUnderlyingBlock, uint256 lastUnderlyingTimestamp, bytes32 paymentReference, address executor, uint256 executorFeeNatWei)
```

Redeemer started the redemption process and provided FAssets.
The amount of FAssets corresponding to `valueUBA` was burned. 
One `RedemptionRequested` event is emitted for every agent redeemed against.

### RedemptionTicketCreated

```solidity
event RedemptionTicketCreated(address indexed agentVault, uint256 indexed redemptionTicketId, uint256 ticketValueUBA)
```

Redemption ticket with given value was created (when minting was executed).

### RedemptionTicketDeleted

```solidity
event RedemptionTicketDeleted(address indexed agentVault, uint256 indexed redemptionTicketId)
```

Redemption ticket was deleted.

### RedemptionTicketUpdated

```solidity
event RedemptionTicketUpdated(address indexed agentVault, uint256 indexed redemptionTicketId, uint256 ticketValueUBA)
```

Redemption ticket value was changed (partially redeemed).

### RedemptionTicketsConsolidated

```solidity
event RedemptionTicketsConsolidated(uint256 firstTicketId, uint256 nextTicketId)
```

Method `consolidateSmallTickets` has finished.

### RedemptionWithTagRequested

```solidity
event RedemptionWithTagRequested(address indexed agentVault, address indexed redeemer, uint256 indexed requestId, string paymentAddress, uint256 valueUBA, uint256 feeUBA, uint256 firstUnderlyingBlock, uint256 lastUnderlyingBlock, uint256 lastUnderlyingTimestamp, bytes32 paymentReference, address executor, uint256 executorFeeNatWei, uint256 destinationTag)
```

Redeemer started the redemption with tag process and provided FAssets. 
The amount of FAssets corresponding to `valueUBA` was burned.
One `RedemptionWithTagRequested` event is emitted for every agent redeemed against.

### ReturnFromCoreVaultCancelled

```solidity
event ReturnFromCoreVaultCancelled(address indexed agentVault, uint256 indexed requestId)
```

The agent has cancelled a return from core vault request.

### ReturnFromCoreVaultConfirmed

```solidity
event ReturnFromCoreVaultConfirmed(address indexed agentVault, uint256 indexed requestId, uint256 receivedUnderlyingUBA, uint256 remintedUBA)
```

The payment from core vault to the agent's underlying address has been confirmed.

### ReturnFromCoreVaultRequested

```solidity
event ReturnFromCoreVaultRequested(address indexed agentVault, uint256 indexed requestId, bytes32 paymentReference, uint256 valueUBA)
```

The agent has requested return of some of the underlying from the core vault to the agent's underlying address.

### SelfClose

```solidity
event SelfClose(address indexed agentVault, uint256 valueUBA)
```

Agent self-closed `valueUBA` of backed FAssets.

### SelfMint

```solidity
event SelfMint(address indexed agentVault, bool mintFromFreeUnderlying, uint256 mintedAmountUBA, uint256 depositedAmountUBA, uint256 poolFeeUBA)
```

Agent performed self-minting, either by executing `selfMint` with underlying deposit or by executing `mintFromFreeUnderlying`.

### SettingArrayChanged

```solidity
event SettingArrayChanged(string name, uint256[] value)
```

A setting array has changed.

### SettingChanged

```solidity
event SettingChanged(string name, uint256 value)
```

A setting has changed.

### SystemRedemptionFeePaid

```solidity
event SystemRedemptionFeePaid(address indexed agentVault, uint256 indexed requestId, uint256 feeUBA)
```

At the creation of a redemption request, the system redemption fee part of the redemption value was re-minted as FAssets to the system redemption fee receiver and the redemption value was lowered by the fee amount.

### TransferToCoreVaultDefaulted

```solidity
event TransferToCoreVaultDefaulted(address indexed agentVault, uint256 indexed transferRedemptionRequestId, uint256 remintedUBA)
```

Agent has cancelled transfer to the core vault without paying. The amount `valueUBA` has been re-minted.

### TransferToCoreVaultStarted

```solidity
event TransferToCoreVaultStarted(address indexed agentVault, uint256 indexed transferRedemptionRequestId, uint256 valueUBA)
```

Agent has requested transfer of (some of) their backing to the core vault.

### TransferToCoreVaultSuccessful

```solidity
event TransferToCoreVaultSuccessful(address indexed agentVault, uint256 indexed transferRedemptionRequestId, uint256 valueUBA)
```

The transfer of underlying to the core vault was successfully completed.

### UnderlyingBalanceChanged

```solidity
event UnderlyingBalanceChanged(address indexed agentVault, int256 underlyingBalanceUBA)
```

Emitted whenever the tracked underlying balance changes.

### UnderlyingBalanceTooLow

```solidity
event UnderlyingBalanceTooLow(address indexed agentVault, int256 balance, uint256 requiredBalance)
```

Agent's underlying balance became lower than required for backing FAssets, either through payment or via a challenge.
Agent goes into full liquidation.
The challenger is rewarded from the agent's collateral.

### UnderlyingBalanceToppedUp

```solidity
event UnderlyingBalanceToppedUp(address indexed agentVault, bytes32 transactionHash, uint256 depositedUBA)
```

Emitted when the agent tops up the underlying address balance.

### UnderlyingWithdrawalAnnounced

```solidity
event UnderlyingWithdrawalAnnounced(address indexed agentVault, uint256 indexed announcementId, bytes32 paymentReference)
```

Announces withdrawal of (some of) the agent's underlying.
Only one announcement can exist per agent; agent has to present payment proof for withdrawal before starting a new one.

### UnderlyingWithdrawalCancelled

```solidity
event UnderlyingWithdrawalCancelled(address indexed agentVault, uint256 indexed announcementId)
```

After announcing legal underlying withdrawal agent, agent cancels ongoing withdrawal.

### UnderlyingWithdrawalConfirmed

```solidity
event UnderlyingWithdrawalConfirmed(address indexed agentVault, uint256 indexed announcementId, int256 spentUBA, bytes32 transactionHash)
```

After announcing legal underlying withdrawal and creating transaction, the agent confirms the transaction.

### VaultCollateralWithdrawalAnnounced

```solidity
event VaultCollateralWithdrawalAnnounced(address indexed agentVault, uint256 amountWei, uint256 withdrawalAllowedAt)
```

Agent has announced a withdrawal of collateral and will be able to withdraw the announced amount after timestamp `withdrawalAllowedAt`. If withdrawal was canceled (announced with amount 0), `amountWei` and `withdrawalAllowedAt` are zero.