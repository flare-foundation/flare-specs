# Instructions
Within the Flare Confidential Compute infrastructure, messages are sent to the TEE machines via a system of *instructions*.
Instructions come in two types:
- Messages submitted by Flare users to be relayed to the TEEs by Flare's data providers are known as *instruction events*, or sometimes *action instructions*.
- Instruction events are then then packaged, augmented, and signed by the providers, and possibly cosigners, into a corresponding *TEE instruction*, which are relayed to the TEEs. 

Once a TEE instruction is assembled by a data provider or cosigner, it is signed and relayed to the TEE machines via their proxy servers. 
Once a TEE proxy receives a threshold weight of signatures for a TEE instruction, it is packaged as an [action](Actions.md) and placed in a queue to be performed by the TEE machine. 
This page documents these features.

[Diagram: instruction on flare -> Tee instruction -> TEE proxy -> action queue]


## Instruction Events
An instruction event is the method by which a Flare user submits an instruction to one or more TEEs on a specific extension, instructing those machines to perform a certain action. 
They do so by submitting an instruction event to the `teeExtensionRegistry` smart contract on Flare.

Instruction events do not need to contain all required information to complete the action; rather, data providers and cosigners pick up the instruction on Flare, and are responsible for packaging it together with the necessary information to perform the action and their signature before relaying it to the TEEs.

An instruction event emitted on Flare has the following data structure:

- `instructionID`: A unique index for the instruction issued.
- `extensionID`: The ID of the extension on which the instruction is issued.
- `teeMachines`: A list of one of more TEE machines selected to fulfil the instruction, identified by their ID, URL, and proxy ID.
- `rewardEpochID`: The ID of the reward epoch (and thus signing policy) of the instruction, used by the TEEs for checking that the instruction is signed by enough weight of providers.
- `opType`: The type of operation issued, from a preset list for the extension.
- `opCommand`: The type of command issued, letting the data providers know how to process the instruction.
- `message`: Binary data representing the parameters for the specific command issued; this is the information providers and cosigners use to build the instruction that they send to the TEE.
- `cosigners`: An optional parameter listing the set of cosigners for the command (see below for more details).
- `cosignerThreshold`: The threshold of cosigner signatures required to accept the instruction.
- `fee`: Fee paid by the user on Flare for the instruction.

### Thresholds
In order for an instruction to be accepted at the TEE proxy, and thus sent to the TEE machine, a threshold of the weight of Flare's data providers must submit the signed instruction.
The exact weight required depends on the extension and type of instruction, but will typically be any amount in excess of $50\%$ of the weight of data providers.
This process is known as [voting](Voting.md).

### Cosigners 
Similarly, certain extensions and instructions permit the use of *cosigners* to increase security. 
A cosigner is a Flare address that the user who issued the instruction event assigns to vote to increase the security of the instruction. 
In an instruction event with the `cosigners` and `cosignerThreshold` fields included, the TEE proxy will only accept the corresponding TEE instruction upon receiving both the threshold weight of data provider signatures and an amount of cosigner signatures exceeding `cosignerThreshold` from the designated cosigner addresses. 
The possible addresses valid to be included `cosigners` depends on the extension and instruction; some extensions may indicate valid cosigner addresses, but in other cases any addresses can be used.

Note that it is in theory possible for a weighted majority of data providers to delete or change the cosigner fields in a given instruction to circumvent the extra security provided.
Each extension that intends to use cosigner fields must prepare its own protection against such an attack.
For example, requiring the [action response](Actions.md) to include the cosigner signatures allows a contract on Flare to confirm that the cosigners signed the instruction.

For a detailed discussion of how cosigner enforcement is handled at the system and extension level, including mitigation against 50%+ data provider attacks, see [Cosigner Enforcement](Actions.md#cosigner-enforcement)

## TEE Instructions
After an instruction event has been emitted on Flare, it is the duty of the data providers, and any optional cosigners, to respond to the event by preparing a *TEE instruction*, then signing this instruction and forwarding it to the appropriate TEE(s) via their proxy servers. 
Additionally, the providers and cosigners augment the instruction with the required information needed by the TEE machine to complete the required action.

### Instruction Format
Thus, a TEE proxy receives this instruction from a data provider (or cosigner) in two parts: firstly a package $\text{data}$ containing the instruction and information needed by the TEE machine to implement it.
Additionally, the proxy receives a signature $\mathrm{sign}_{\mathrm{sk}}$ over the instruction data performed using the senders secret key.


### Data Format
The package $\text{data}$ contains all the information that the TEE machine needs to execute the instruction. The information in the package is arranged as 

- `instructionId`: As in the instruction event.
- `teeID`: The unique identity of the destination TEE machine.
- `timestamp`: The timestamp of the block in which the instruction was issued.
- `rewardEpochID`: The ID of the reward epoch in which the instruction was issued.
- `opType`: As in the instruction event.
- `opCommand`: As in the instruction event.
- `originalMessage`: The `message` from the instruction event.
- `cosigners`: As in the instruction event.
- `cosignerThreshold`: As in the instruction event.
- `additionalFixedMessage`: Binary data depending on the command, fixed accross all providers and cosigners.
- `additionalVariableMessage`: Binary data depending on the command, specific to the data provider or cosigner.


### Signature Format
To compute the signature, first the following struct defining the command is ABI encoded:

```Solidity
struct TeeInstruction {
bytes32 instructionId;
address teeId;
uint64 timestamp;
uint32 rewardEpochId;
bytes32 opType;
bytes32 opCommand;
address[] cosigners;
uint64 cosignerThreshold;
bytes originalMessage;
bytes additionalFixedMessage;
}
```
then, the ABI encoding is hashed into `instructionHash`. Finally, the signature is taken over the data $\mathrm{Hash}($`instructionHash`, `additionalVariableMessage`$)$. 

> **Note on `instructionHash` vs `instructionId`:** Instructions are typically identified by `instructionId` (the unique event index from the smart contract), but for counting confirmations during the [voting process](Voting.md) on the TEE proxy, `instructionHash` is used instead. The `instructionHash` is defined as the hash of the instruction data excluding `additionalVariableMessage`, allowing the proxy to match votes from different providers on the same instruction content regardless of their individual variable messages.

## Direct Instructions
In certain circumstances, governance or administrating addresses are able to directly instruct participating TEEs via their proxies, circumventing the need for commands to be signed and packaged by data providers and cosigners. 
Such a command is known as a *direct instruction*. 
Typically direct instructions are not triggered by a specific message on smart contracts. 
They are used for specific configurations or setups such as upgrade version approvals or banning by governance signers, direct configurations, and similar administrative operations.

Direct instructions are submitted to the TEE proxy via the `/direct-instruction` API route. 
The signature collection for direct instructions occurs out-of-band, with the sender responsible for gathering the required signatures before submission.

The payload for a direct instruction sent to the TEE proxy is simpler than a normal instruction, and consists of only three parts, defined in the same manner as above:

- `opType`
- `opCommand`
- `message`.

Note that in some cases TEEs will still only follow direct instructions that have been signed by an appropriate number of signees; for example, in cases where the governance of an extension is via a multisig, the TEE will only accept a direct instruction in response to receiving a threshold number of signatures for it.
If the number and identities of signatures meet the required criteria (e.g. threshold of a specific multisig), the direct instruction is packed into an action and placed into either the main action queue or the governance queue for further processing.