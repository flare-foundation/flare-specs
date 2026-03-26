# Projects and Configuration
User ownership of keys stored on TEE machines is sorted in to a system of *projects*.
A project is a grouping structure for multiple *wallets*.
A wallet consists of a set of private keys stored inside TEE machines on Flare Confidential Compute.
Keys are identified by a *wallet key* data structure.
Each project has an *owner*, a governance address on Flare which handles administration for the project and its wallets and keys.

## Project Workflow
The owner of a project is the address with permissions to set up wallets, cosigners, and keys for the project.
The workflow beginning from instantiating a project to using keys in production follows a sequence of steps:

1. The Flare user creates a project by calling the `createProject` function on the `TeeWalletProjectManager` contract from address $F$. The owner of the new project is the Flare address $F$.
2. To add a wallet to the project, the owner calls `createWallet` on the `TeeWalletManager` contract from $F$. The new wallet is assigned a unique `walletId` (see below) and given an initial status of `created`, indicating that it is not production ready.
3. Optionally, the owner can call the `setAdmins` and `setCosigners` functions on the wallet manager contract to set admin and [cosigner](Instructions.md) addresses for the wallet. Designated admins and cosigners must then call the `confirmAdmin` and `confirmCosigner` functions on the same contract to confirm their participation and be registered to the wallet.
4. The owner finishes initialization by calling the `closeWalletInitialization` function on the wallet manager contract. This sets the wallet status to `initialized`.
5. Once initialized, the owner can generate private keys for the wallet by calling the `addKey` function on the wallet manager contract. This function issues an instruction to designated TEE machines to generate private keys.
6. On generating a key, the TEE machine provides a key existence proof that is relayed to the wallet manager contract on-chain (by any address on Flare) using the `confirmKey` function.
7. Once enough keys are confirmed and the multisig threshold is set, the owner can enable the wallet for production by calling the `enableWallet` function on the wallet manager smart contract. The number of confirmed keys must meet or exceed the multisig threshold.
8. The wallet is enabled and its status is set to `production`.

### Cosigners
In step 3 of the above process, the project owner set admin and cosigner addresses for the wallet.
The requirements on cosigning for projects are determined on a per-wallet basis by the wallet owner.
On initialization of a given wallet, the owner sets whether or not cosigners are required for transactions on it, as well as the corresponding signing threshold.
This determines parameters $(n,k)$ for a threshold signature, with $k$ of the $n$ cosigner addresses required to sign an instruction that uses a key before the key holding TEE machine executes it.

Once the cosigner addresses and threshold for a wallet are set, they can not be changed.
This can be useful for [cosigner enforcement](Instructions.md#cosigners).
For example, in the PMW case, TEE machines store immalleable cosigner information as metadata alongside the keys for the wallet so that they can check whether each instruction has been appropriately signed.
## Data Structures
Formally, the components are a sequence of nested data structures, with each one being a field within the above structure.
The main constituent parts are:

- Projects
- Wallets
- Wallet Keys
- Key Definitions

with each of these explained below.
Users interact with these data structures using the smart contracts on Flare, whose calls are laid out in the following section.

### Project Data Structures
For a Flare user to initialize a key, they must first have a project in place.
Thus, initializing a project data structure is the first part of registering a key.
To do so, the user calls the `createProject(extensionId, keyType, signingAlgo, authorizationAddress)` function at the `TeeProjectManager` contract.
The project data structure consists of the following fields:

- `projectId`: The unique project ID generated at project creation.
- `owner`: The (Flare) address of the creator and admin of the project.
- `keyType`: The key type (e.g. ECDSA, etc) for keys used in all wallets in the project.
- `signingAlgo`: The hash and sign algorithm of the keys used in all the wallets in the project.
- `submitAddress`: The (Flare) address from which the user can submit instructions for wallets on the project. Typically, this will be different to the owner address.
- `backupManager`: The (Flare) address from which key restoration can be triggered for keys that are backed up.
- `defaultWalletId`: The default project wallet used for signing.
### Wallet Data Structures
A wallet is a data structure hosted on Flare that controls one or more keys on TEE machines.
Wallets are created within existing projects.
The data structure contains the following fields:

- `walletId`: A unique wallet identifier, generated upon creation of the wallet.
- `projectId` : The ID of the project to which the wallet belongs.
-  `adminsPublicKeys`: A list of public keys of the wallet owner admin set (see below).
- `adminsThreshold`: Signing threshold for instructions issued by the owner admin set.
-  `cosigners`: An (optional) list of cosigner addresses.
- `cosignersThreshold`: The threshold requirement for cosigner signatures, if applicable.
- `status`: The status of the wallet. Options are created, initialized, production, or paused, indicating the current operational status of the wallet.

### Wallet Keys Data Structure
Typically, wallets will use multi-sig addresses on external chains for sending transactions.
Thus, the *wallet keys* data structure is used to store information about all the keys on a wallet, in the following format:

- `walletId`: The identifier of the wallet that the keys are for.
- `multisigThreshold`: The parameters $k$ and $n$ defining the multisig for the wallet, where $n$ defines the total number of confirmed key definition structures (see below) for the wallet and $k$ the required number of signatures to send a transaction.
- `keyIdCounter`: A counter for the wallet keys, defining the next key Id for key definition structures.
- `keyDefinitions`: The set of private keys used within the wallet. This field includes information on which TEEs the keys are stored.
- `feeFactor`: The number of TEE machines on which there is a key for the wallet.

### Key Definition Data Structure
The `keyDefinitions` field in the wallet keys data structure contains information about the private keys used in the wallet.
Each key is identified via a *key definition* data structure, formatted as follows:

-  `keyId`: A unique identifier, calculated sequentially each time a new key definition is introduced.
- `tees`: A list of TEE machine IDs on which the key exists. This field is updated using a `TeeKeyExistence` [proof](../TEE Management/Key Management.md).
- `publicKey`: The public part of the key pair, set by the owner on provision of `TeeKeyExistence` proof.

## Project and Wallet Manager Contracts
Flare users manage their projects and wallets through the `TeeProjectManager` and `TeeWalletManager` contracts.
The function calls available at these contracts are listed here.

### Project Manager Contract Calls
- `createProject(extensionId, keyType, signingAlgo, authorizationAddress)`: Initializes a new project, generating a new project ID and marking the address that called the function as the project owner. The `extensionId` identifies the extension, `keyType` and `signingAlgo` define the key properties for all wallets in the project, and `authorizationAddress` is the address that has permission to submit instructions.
- `setBackupManager(projectId, address)`: Sets a new backup manager address that can trigger key restores. This can only be called by the project owner.
- `setDefaultWallet(projectId, walletId)`: Sets the default wallet for the project that will be used for all the signing. This can only be called by the project owner.
- `proposeNewOwner(projectId, address)`: Proposes a new owner for the project. This can only be called by the current owner, and ownership does not transfer until it is confirmed.
- `confirmOwnership(projectId)` : Confirms the new ownership of project. This can only be called by the address proposed by the `proposeNewOwner` call issued by the previous owner. After this function is called, ownership is transferred to the new owner.

### Wallet Manager Contract Calls
- `createWallet(projectId)`: Creates a new wallet on the specified project with a new (randomly generated) wallet ID. This can only be called by the project owner.
- `setAdmins(walletId, adminsPublicKeys, adminsThreshold)`: Sets a signing threshold and admin public keys that are used for:
	- Encrypting shamir secret shares for storing backups    
	- Multisig confirmation of changes in config settings such as halting and resuming signings.

	Can be called by the owner until `closeWalletInitialization` is called.
- `confirmAdmin(walletId)`: Sent by one of the specified admin addresses in `adminPublicKeys`, this confirms the admin public key `adminPublicKey` that called the function as one of the key admins for the wallet ID.
- `setCosigners(walletId, cosigners, cosignersThreshold)`: Sets signing threshold and addresses for cosigners. This call is optional, and only for the case where cosigners are used.
- `confirmCosigner(walletId)`: Sent by one of the specified cosigner addreses in `cosigners`, this confirms  the cosigner address  `cosigner` that called the function as one of the key admins for the wallet ID.
- `closeWalletInitialization(walletId)`: Closes wallet initialization. Once the wallet is close, cosigners and key admins are locked, and keys can be added to the wallet. This function cannot be called until at least one admin public key is set and all admins and cosigners are confirmed. This can only be called by the project owner.
- `pauseWallet(walletId)`: Pauses the wallet. Indicates that existing payment instructions should be reverted.
- `enableWallet(walletId)`: Changes the wallet's status to production. Indicates that instructions can be issued.
- `setPausingAddresses(walletId, pausingAddresses)`: Sets the pausing addresses on all active TEE machines with keys belonging to the wallet by issuing the `SET_PAUSING_ADDRESSES` instruction. This can be called only by the project owner.
- `resume(walletId, keysData)`: Resumes the availability of the wallet keys for listed keys in `keysData`, which includes the TEE and key IDs and the pausing nonce. Does so by issuing a `RESUME` instruction. This can only be called by the project owner.

Triggered instructions are sent by the wallet manager contract to the instruction contract.
They are parameterized by:

- `SET_PAUSING_ADDRESSES(walletId, teeIdKeyIdPairs, pausingAddresses)`
- `RESUME(walletId, keysData)`.
