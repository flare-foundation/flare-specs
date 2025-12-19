# TEE Proxies
A *TEE Proxy* is a proxy server controlling access to the TEE environment.
Each TEE machine has a corresponding TEE proxy, which is responsible for ferrying information to and from the TEE machine, so that access to the machine itself is controlled.
TEE proxies receive instructions and collect signatures from data providers and cosigners, distribute them to the TEE machines, and return the results of the corresponding actions on request. 
They handle their interactions by a system of internal and external API calls. 
Additionally, they host a collection of internal logic to manage action queues and logic for instructions.

## Proxy Security
Each TEE proxy corresponds to a unique TEE machine and has a public identity $\mathrm{Proxy}_\mathrm{ID}$ which defines the public part of a public/private key pair for a digital signature scheme. 
This identity is registered on Flare in the `TeeRegistry` smart contract, as well as provided in the proxies configuration. 
The key pair is used by the TEE proxy to sign receipts of its processes.

Both the TEE proxy and machine are owned by the same entity. 
Thus, the owner of the pair could censor access to the TEE machine via the proxy layer. 
To ensure that a request submitted to the TEE proxy has been correctly relayed to the TEE machine, the proxy makes confirmation available via an API.
This API returns a package signed by the TEE machine itself that it has received the request. 
Until the confirmation is obtained, there is no guarantee that the proxy relayed the request to the TEE machine.

## Signing Policy
The TEE proxy is responsible for maintaining an up to date copy of Flare's signing policy at both the TEE machine and at the proxy itself.
Without the signing policy, the TEE proxy and machine are unable to determine when a vote has passed successfully.

On initialization, the TEE proxy sets the signing policy at the TEE machine using an `initialize_policy` command, proving the current policy.
As part of its initial [attestation](Identities.md), the signing policy of the TEE machine is checked on registration by Flare's data providers to ensure that the correct policy was given.
To remain up to date, the proxy has access to a C-chain indexer to obtain new signing policies and relays them to the TEE machine using an `update_policy` [direct instruction](Instructions.md). 

## Processing Queues
The TEE proxy is responsible for managing two types of processing queues:

- **Direct Queue**: A queue filled by the proxy itself, usually used for GET type operations
- **Action Queues**: A queue for actions of all other types, in particular instructions with sufficient weight of signatures. 

Actions to be placed into the two queues are labelled with a  `queueID` of `direct` and `main` respectively. 
Both queues are persistently stored in the REDIS database.

[someone should read this section. Particularly for REDIS database stuff].

## Proxy State
The proxy state is managed through the REDIS database and consists of a collection of key-value pairs:

-   **Voting process store**: (`instructionHash` $\rightarrow$ `VotingProcess`), tracks the voting process for a given instruction hash.
- **Voting process list**: (`instructionId` $\rightarrow$ list of valid `instructionHash`), tracks the concurrent voting processes for the same instruction ID.
- **Action store**: ([`actionId`, `submissionTag`] $\rightarrow$ `actionData`), tracks the data for a given action identity.
- **Action result store**: ([`actionId`, `submissionTag`, `result`] $\rightarrow$ `actionResult`), tracks the result for a given action identity.
- **Signing policy store**: (`rewardEpochId` $\rightarrow$ `signingPolicyData`), tracks the signing policy data for a given reward epoch.
- **Key data store**: ([`walletId`, `keyId`]$\rightarrow$ `keydata`), tracks the key data for any keys stored in the TEE for [PMW](PMW.md) operations.
- **Last attestation**: Tracks the last available attestation made through the `Tee_INFO` action. This is updated by the TEE proxy every $30$ seconds, which generates a random challenge and calls the action.
- **Backup store**: (`backupIdHash` $\rightarrow$ `backupData`), tracks the data related to key backups stored by the TEE machine. Backup packages are extracted from the TEE machine each time `Tee_INFO` is called.

### Key Data Store
The key data store stores the list of keys stored on the TEE for participation in the PMW protocol.
This store is updated by calling the `Key_Info` action, which returns a list of `teeKeyExistenceProofs` from the TEE machine, proving the existence of each key.
Each proof is packaged into a pair (`timestamp`, `proof`) containing the timestamp at the proxy for the most recent update and the proof of existence.