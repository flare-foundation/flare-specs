# IMintingTagManager

## Methods

### reserve

```solidity
function reserve() external payable returns (uint256)
```

Reserve a new minting tag by paying the reservation fee.
The caller becomes the owner of the tag and the initial minting recipient.

*Returns:*

- `uint256` — The newly reserved minting tag ID.

### transfer

```solidity
function transfer(address _to, uint256 _mintingTag) external
```

Transfer a minting tag to a new owner.
Also updates the minting recipient to the new owner and resets the allowed executor.

*Parameters:*

- `_to` — The address to transfer the tag to.
- `_mintingTag` — The minting tag ID to transfer.

### setMintingRecipient

```solidity
function setMintingRecipient(uint256 _mintingTag, address _recipient) external
```

Set the minting recipient for a tag.
Only callable by the tag owner.
The minting recipient is the address that receives minted FAssets when this tag is used.

*Parameters:*

- `_mintingTag` — The minting tag ID.
- `_recipient` — The new minting recipient address (must not be zero address).

### setAllowedExecutor

```solidity
function setAllowedExecutor(uint256 _mintingTag, address _executor) external
```

Set the allowed executor for a tag.
Only callable by the tag owner
The allowed executor is the only address that can execute direct mintings with this tag.
Setting an allowed executor is optional; if not set, anyone can execute mintings with the tag.
Changes to the allowed executor are subject to a cooldown delay before they become active.

*Parameters:*

- `_mintingTag` — The minting tag ID.
- `_executor` — The new allowed executor address (must not be zero address).

### nextAvailableTag

```solidity
function nextAvailableTag() external view returns (uint256)
```

*Returns:*

- `uint256` — The next tag ID that will be assigned on the next reservation.

### reservationFee

```solidity
function reservationFee() external view returns (uint256)
```

*Returns:*

- `uint256` - The fee (in native currency) required to reserve a new minting tag.

### reservationFeeRecipient

```solidity
function reservationFeeRecipient() external view returns (address payable)
```

*Returns:*

- `address` - The recipient that receives reservation fees paid when reserving minting tags.

### executorChangeAfterSeconds

```solidity
function executorChangeAfterSeconds() external view returns (uint256)
```

*Returns:*

 - `uint256` - The cooldown delay (in seconds) before a change to a tag's allowed executor becomes active. The delay must be longer than the time needed to obtain an FDC proof, so that an executor that has already paid for an FDC request cannot be locked out before they can use it.

### reservedTagsForOwner

```solidity
function reservedTagsForOwner(address _owner) external view returns (uint256[])
```

Return all minting tag IDs owned by the given address.

*Parameters:*

- `_owner` — The address to query.

*Returns:*

- `uint256[]` — An array of minting tag ids owned by `_owner`.

### mintingRecipient

```solidity
function mintingRecipient(uint256 _mintingTag) external view returns (address)
```

Return the minting recipient for a given tag.

*Parameters:*

- `_mintingTag` — The minting tag ID.

*Returns:*

- `address` — The address that receives minted FAssets when this tag is used.

### allowedExecutor

```solidity
function allowedExecutor(uint256 _mintingTag) external view returns (address)
```

Return the currently active allowed executor for a given tag.
If no executor is set or the pending change hasn't activated yet, returns the previous executor.

*Parameters:*

- `_mintingTag` — The minting tag ID.

*Returns:*

- `address` — The address of the allowed executor, or address(0) if none is set.

### pendingAllowedExecutorChange

```solidity
function pendingAllowedExecutorChange(uint256 _mintingTag) external view returns (bool _pending, address _newExecutor, uint256 _activeAfterTs)
```

Return information about a pending allowed executor change for a given tag.
Executor changes are subject to a cooldown delay to allow executor to avoid making FDC request when they won't be allowed to execute minting anymore.

*Parameters:*

- `_mintingTag` — The minting tag ID.

*Returns:*

- `_pending` — True if there is a pending executor change that hasn't activated yet.
- `_newExecutor` — The address of the pending new executor (address(0) if no pending change).
- `_activeAfterTs` — The timestamp after which the new executor becomes active (0 if no pending change).

### approve

```solidity
function approve(address to, uint256 tokenId) external
```

Gives permission to `to` to transfer `tokenId` token to another account.
The approval is cleared when the token is transferred.
Only a single account can be approved at a time, so approving the zero address clears previous approvals.
Emits an `Approval` event.

*Requirements:*

- The caller must own the token or be an approved operator. 
- `tokenId` must exist. 

*Parameters:*

- `_to` — The address to receive permission.
- `uint256` - The amount of token to be allowed to transfer
- `tokenID` - The ID of the token.

### balanceOf

```solidity
function balanceOf(address owner) external view returns (uint256 balance)
```
Returns the number of tokens in ``owner``'s account.

*Parameters:*

- `owner`: The owner of the account.

*Returns:*

- `balance`: The number of tokens.

### getApproved

```solidity
function getApproved(uint256 tokenId) external view returns (address operator)
```

Returns the account approved for `tokenId` token.

*Parameters:*

- `tokenID`: The ID of the token.

*Returns:*

- `operator`: The operator account for that token.


### isApprovedForAll

```solidity
function isApprovedForAll(address owner, address operator) external view returns (bool)
```

Returns if the `operator` is allowed to manage all of the assets of `owner`.
See `setApprovalForAll`

*Parameters:*

- `owner`: The owber of the address.
- `operator`: The operator of the account.

*Returns:*

- `bool`: True if the operator is allowed to manage the owner's assets.

### ownerOf

```solidity
function ownerOf(uint256 tokenId) external view returns (address owner)
```

Returns the owner of the `tokenId` token.

*Parameters:*

- `tokenID`: The ID of the token.

*Returns:*

- `owner`: The owner of the token type.

### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 tokenId) external
```

Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients are aware of the ERC721 protocol to prevent tokens from being forever locked.
Emits a `Transfer` event.

*Parameters:*

- `from`: The sender address.
- `to`: The receiver address.
- `tokenId`: The ID of the token being transferred.

Requirements:
 - `from` cannot be the zero address. 
 - `to` cannot be the zero address. 
 - `tokenId` token must exist and be owned by `from`. 
 - If the caller is not `from`, it must have been allowed to move this token by either `approve` or `setApprovalForAll`. 
 - If `to` refers to a smart contract, it must implement `IERC721Receiver-onERC721Received`, which is called upon a safe transfer.

### safeTransferFrom (Bytes)

```solidity
function safeTransferFrom(address from, address to, uint256 tokenId, bytes data) external
```

The same function as above, with the inclusion of a `data` parameter as in [ERC-21](https://eips.ethereum.org/EIPS/eip-721).

### setApprovalForAll

```solidity
function setApprovalForAll(address operator, bool approved) external
```

Approve or remove `operator` as an operator for the caller. Operators can call `transferFrom` or `safeTransferFrom` for any token owned by the caller.
Emits an `ApprovalForAll` event.

*Parameters:*

- `operator`: The operator whose status is being changed.
- `approved`: Whether the operator should be approved or removed.

*Requirements:* 

- The `operator` cannot be the caller.

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```

Returns true if this contract implements the interface defined by `interfaceId`. 

*Parameters:*

- `interfaceId`: The ID of the interface.

*Returns:*

- `bool`: Whether or not the interface is supported.

### tokenByIndex

```solidity
function tokenByIndex(uint256 index) external view returns (uint256)
```

Returns a token ID at a given `index` of all the tokens stored by the contract.
Use along with `totalSupply` to enumerate all tokens.

*Parameters:*

- `index`: The index of the token.

*Returns:*

- `uint256`: The token ID to be returned.

### tokenOfOwnerByIndex

```solidity
function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256)
```

Returns a token ID owned by `owner` at a given `index` of its token list. Use along with `balanceOf` to enumerate all of `owner`'s tokens.

*Parameters:*

- `owner`: The owner of the token.
- `index`: The index of the token.

*Returns:*

- `uint256`: The ID of the token.

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```

*Returns:*

- `uint256`: The total supply of the token.

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 tokenId) external
```

Transfers `tokenId` token from `from` to `to`.
Emits a `Transfer` event.

WARNING: Note that the caller is responsible tfor confirming that the recipient is capable of receiving ERC721 or else they may be permanently lost.
Usage of `safeTransferFrom` prevents loss, though the caller must understand this adds an external call which potentially creates a reentrancy vulnerability.

*Parameters:*

- `from`: The address of the sender.
- `to`: The address of the receiver.
- `tokenId`: The amount to be transferred.

*Requirements:*

- `from` cannot be the zero address.
- `to` cannot be the zero address.
- `tokenId` token must be owned by `from`.
- If the caller is not `from`, it must be approved to move this token by either `approve` or `setApprovalForAll`.

## Events

### MintingTagReserved

```solidity
event MintingTagReserved(uint256 tag, address owner)
```

Emitted when a new minting tag is reserved.

### RecipientChanged

```solidity
event RecipientChanged(uint256 tag, address recipient)
```

Emitted when the minting recipient for a tag is changed.

### AllowedExecutorChangePending

```solidity
event AllowedExecutorChangePending(uint256 tag, address executor, uint256 activeAfterTs)
```

Emitted when an allowed executor change is initiated (subject to cooldown delay).

### AllowedExecutorChangeCancelled

```solidity
event AllowedExecutorChangeCancelled(uint256 tag)
```

Emitted when a pending allowed executor change is cancelled before it activates.

### AllowedExecutorCleared

```solidity
event AllowedExecutorCleared(uint256 tag)
```

Emitted when the allowed executor state (active and/or pending) is reset to the zero address on tag transfer.
Unlike executor changes made by the tag owner, the reset takes effect immediately, without the cooldown delay.

### ReservationFeeChanged

```solidity
event ReservationFeeChanged(uint256 reservationFee, address recipient)
```

Emitted when the reservation fee or its recipient is changed by governance.

### ExecutorChangeAfterSecondsChanged

```solidity
event ExecutorChangeAfterSecondsChanged(uint256 executorChangeAfterSeconds)
```

Emitted when the cooldown delay for allowed executor changes is updated by governance.

### Approval

```solidity
event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId)
```

Emitted when `owner` enables `approved` to manage the `tokenId` token.

### ApprovalForAll

```solidity
event ApprovalForAll(address indexed owner, address indexed operator, bool approved)
```

Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.

### Transfer

```solidity
event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)
```

Emitted when `tokenId` token is transferred from `from` to `to`.