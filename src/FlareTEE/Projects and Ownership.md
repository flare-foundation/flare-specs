# Projects and Configuration
Ownership of Protocol Managed Wallets is sorted in to a system of *projects*.
A project is a grouping structure for multiple *wallets*.
A wallet represents a set of private keys for an address on an external blockchain stored inside TEE machines on FlareTEE.
Each project has an *owner*, a governance address on Flare which handles administration for the project and its wallets.

## Project Workflow
The owner of a project is able to set up wallets, cosigners, and keys for PMWs managed by the project.
The workflow required to go from instantiating a project to getting a production PMW can be understood via a sequence of steps:

1. The Flare user creates a new project using by calling the `createProject` function on the `TeeWalletProjectManager` contract. The owner of the project is the Flare address of the user.
2. To add a wallet to the project, the owner calls `createWallet` on the `TeeWalletManager` contract. The new wallet is assigned a unique `walletId` (see below) and given an initial status of `created`, indicating that it is not production ready.
3. The owner can now call the `setAdmins` and `setCosigners` functions on the wallet manager contract to set admin and cosigner addresses for the wallet. Designated admins and cosigners must then call the `confirmAdmin` and `confirmCosigner` functions on the same contract to confirm their participation and be registered to the wallet.
4. With all addresses confirmed, the owner finishes initialization by calling the `closeWalletInitialization` function on the wallet manager contract. This sets the wallet status to initialized.
5. Once the wallet is initialized, the owner can generate private keys for the wallet by calling the `addKey` function on the wallet manager contract. This function issues an instruction to designated TEE machines to generate private keys.
6. On generating a key, the TEE machines provide a key existence proof that is sent to the wallet manager contract [by who? data providers?] using the `confirmKey` function.
7. Once enough keys are confirmed, corresponding to the multisig threshold set up by the project owner (see below), the owner can enable the wallet for production by calling the `enableWallet` function on the wallet manager smart contract. To call the enable wallet function, an FTDC proof of a properly configured multisig must first be obtained, using the attestation type `TeeMultisigAccountConfigured`.
8. The wallet is enabled and its status is set to `production`.

### Cosigners
In step 3 of the above process, the project owner set admin and cosigner addresses for the wallet that was set up.
The requirements on cosigning for payment instructions within the PMW infrastructure are determined on a per-wallet basis by the wallet owner.
On initialization of a given wallet, the owner sets whether or not cosigners are required for transactions on it, as well as the corresponding signing threshold. 

Once the cosigner addresses and threshold for a wallet are set, they can not be changed.
The TEE machines store cosigner information as metadata alongside the keys for the wallet so that they can check whether each instruction has been appropriately signed, preventing issues with cosigner enforcement [reference].
Thus, the cosigner information can not be changed after the fact.

## Data Structures
The components of a PMW are arranged in a sequence of data structures, with each one being a field within the above structure.
The main constituent parts are:

- Projects
- Wallets
- Wallet Keys
- Key Definitions

with each of these explained below.

### Project Data Structures
If a user wants to initialize a PMW, they must first have a project on which to place it.
Thus, setting up a project data structure is the first part of registering a PMW.
The project data structure consists of the following fields:

- `projectId`: The unique project ID generated at project creation.
- `owner`: The (Flare) address of the creator and admin of the project.
- `keyType`: The key type (e.g. ECDSA, etc) for keys used in all wallets in the project.
- `signingAlgo`: The hash and sign algorithm of the keys used in all the wallets in the project.
- `submitAddress`: The (Flare) address for the project, and hence all wallets on the project, from which the user can submit payment instruction transactions. Typically, this will be different to the owner address.
- `backupManager`: The (Flare) address from which key restoration can be triggered for keys that are backed up.

### Wallet Data Structures
A wallet is a data structure hosted on Flare that controls one or more addresses on external chains from which transactions can be sent.
Wallets are created within existing projects.
The data structure contains the following fields:

- `walletId`: A unique wallet identifier, generated upon creation of the wallet.
- `projectId` : The ID of the project to which the wallet belongs.
-  `adminsPublicKeys`: A list of public keys of the wallet owner admin set (see below).
- `adminsThreshold`: Signing threshold for instructions issued by the owner admin set.
-  `cosigners`: An (optional) list of cosigner addresses.
- `cosignersThreshold`: The threshold requirement for cosigner signatures.
- `status`: The status of the wallet. Options are created, initialized, production, or paused, indicating the current operational status of the wallet.

### Wallet Keys Data Structure
Typically, wallets will use multi-sig addresses on external chains for sending transactions.
Thus, the *wallet keys* data structure is used to store information about all the keys on a wallet, in the following format:

- `walletId`: The identifier of the wallet that the keys are for.
- `multisigThreshold`: The parameters $k$ and $n$ defining the multisig for the wallet, where $n$ defines the total number of confirmed key definition structures (see below) for the wallet.
- `keyIdCounter`: A counter for the wallet keys, defining the next keyId for key definition structures.
- `keyDefinitions` - The set of private keys used within the wallet. This field includes information on which TEEs the keys are stored.
- `feeFactor`: The number of TEE machines on which there is a key for the wallet.

### Key Definition Data Structure
The `keyDefinitions` field in the wallet keys data structure contains information about the private keys used in the wallet.
Each key is identified via a *key definition* data structure, formatted as follows:

-  `keyId`: A unique identifier, calculated sequentially each time a new key defintion is introduced.
- `tees`: A list of TEE machine ids on which the key exists. This field is updated using a TeeKeyExistence proof. 
- `publicKey`: The public part of the key pair, set by the owner on provision of TeeKeyExistence proof.

## TEE Key Existence Proof
Upon generation of a key for a PMW, the TEE machine on which the key was generated returns a key existence proof to the corresponding TEE proxy, from which the proof can be fetched and submitted on Flare.
The purpose of this proof is to verify that the key exists within the machine's memory.
Additionally, these proofs are occasionally fetched from the machine by the TEE proxy to ensure that the key has not been lost. 

The format of the proof is a signed `TeeKeyExistence` solidity struct, signed by the public key [signed by the ID or new key?] of the TEE.
The format of the solidity struct is

``` Solidity
struct KeyExistence {
address teeId;
bytes32 walletId;
uint64 keyId;
bytes32 keyType;
bytes32 signingAlgo;
bytes publicKey;
uint256 nonce;
bool restored;
KeyConfigConstants configConstants;
bytes32 settingsVersion;
bytes settings;
}
```
where `nonce` is a fresh nonce, `restored` is set to True if the key was restored on to the TEE machine [and otherwise false?], `configConstants` describes configuration of the private key data structure, and the final two fields describe configurations of the TEE settings.
The rest of the fields are as described in previous sections on this page.

## Project and Wallet Manager Contracts
Flare users manage their projects and wallets through the `TeeProjectManager` and `TeeWalletManager` contracts.
The function calls available at these contracts are listed here.

### Project Manager Contract Calls
- `createProject(opType, submitAddress)`: Initializes a new project, generating a project ID and marking the address that called the function as the owner. The functionality of the project is set to `opType` and `submitAddress` is the address that has permission to trigger payment instructions.
- `setBackupManager(projectId, address)`: Sets a new backup manager address that can trigger key restores. This can only be called by the project owner.
- `setDefaultWallet(projectId, walletId)`: Sets the default wallet for the project that will be used for all the signings (payments). This can only be called by the project owner.
- `proposeNewOwner(projectId, address)`: Proposes a new owner for the project. This can only be called by the current owner, and ownership does not transfer until it is confirmed (see next call).
- `confirmOwnership(projectId)` : Confirms the new ownership of project. This can only be called by the address proposed by the `proposeNewOwner` call issued by the previous owner. After this function is called, ownership is transferred to the new owner.

### Wallet Manager Contract Calls
- `createWallet(projectId)`: Creates a new wallet on the specified project, with a new wallet ID. This can only be called by the project owner.
- `setAdmins(walletId, adminsPublicKeys, adminsThreshold)`: Sets a signing threshold and admin public keys that are used for:
	- Encrypting shamir secret shares for storing backups    
	- Multisig confirmation of changes in config settings such as halting and resuming signings.

	Can be called by the owner only until closeWalletInitialization is not called.
- `confirmAdmin(walletId)`: Sent by one of the specified admin addresses, this confirms the admin public key that called the function.
- `setCosigners(walletId, cosigners, cosignersThreshold)`: Sets signing threshold and addresses for cosigners. This call is optional, and only for the case where cosigners are used.
- `confirmCosigner(walletId)`: Sent by one of the specified cosigner addreses, this confirms cosigner address that called the function.
- `closeWalletInitialization(walletId)`: Closes wallet initialization, such that admins and cosigners cannot be updated after this call, and enables adding keys. This function cannot be called until  at least one admin public key is set and all admins and cosigners are confirmed. This can only be called by the project owner.
- `pauseWallet(walletId)`: Pauses the wallet. Indicates that payment instructions should be reverted.
- `enableWallet(walletId)`: Changes the wallet?s status to production. Indicates that payment instructions can be issued.
- `setPausingAddresses(walletId, pausingAddresses)`: Sets the pausing addresses on all active TEE machines with keys belonging to the wallet by issuing the `SET_PAUSING_ADDRESSES` instruction. This can be called only by the project owner.
- `resume(walletId, keysData)`: Resumes the availability of the wallet keys for listed keysData, which includes the TEE and key IDs and the pausing nonce, by issuing a `RESUME` instruction. This can only be called by the owner.

The corresponding instructions take input parameters:
- `SET_PAUSING_ADDRESSES(walletId, teeIdKeyIdPairs, pausingAddresses)`
- `RESUME(walletId, keysData)`.