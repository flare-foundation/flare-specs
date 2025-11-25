# Instructions
Within the FlareTEE infrastructure, messages submitted by Flare users and relayed to the TEEs by Flare's data providers are known as *instructions*, or sometimes *instruction events*.
Instructions are issued by Flare's users via smart contracts on Flare, then packaged and augmented by the providers, and possibly cosigners, into a form known as a TEE instruction. 
Once the TEE instruction is assembled, it is signed and relayed to the TEE machines via their proxy servers. 
Once a TEE proxy receives a threshold weight of signatures for an instruction, it is packaged as an action and placed in a queue to be performed by the TEE machine. 
This page documents these features.

[Diagram: instruction on flare -> Tee instruction -> TEE proxy -> action queue]


## Instruction Events
An instruction event is the method by which a Flare user submits an instruction to one or more TEEs on a specific extension, instructing those machines to perform a certain action. 
Instruction events do not need to contain all required information to complete the action; rather, data providers and cosigners pick up the instruction on Flare, and are responsible for packaging it together with the necessary information to perform the action and their signature before relaying it to the TEEs.

An instruction event emitted on Flare has a specific data structure, as outlined below

- `instructionID`: A unique index for the instruction issued.
- `extensionID`: The ID of the extension on which the instruction is issued.
- `teeMachines`: A list of one of more TEE machines selected to fulfil the instruction, identified by their ID, URL, and proxy ID.
- `rewardEpochID`: The ID of the reward epoch (and thus signing policy) of the instruction, used by the TEEs for checking that the instruction is signed by enough weight of providers.
- `opType`: The type of operation issued, from a preset list for the extension.
- `opCommand`: The type of command issued, letting the data providers know how to process the instruction.
- `message`: Binary data representing the parameters for the specific command issued; this is the information providers and cosigners use to build the instruction sent to the TEE.
- `cosigners`: An optional parameter listing the set of cosigners for the command (see below for more details).
- `cosignerThreshold`: The threshold of cosigner signatures required to accept the instruction. [security flaw: providers edit this?]
- `fee`: Fee paid by the user on Flare for the instruction.

### Thresholds
In order for an instruction to be accepted at the TEE proxy, a threshold of the weight of Flare's data providers must submit the signed instruction.
The exact weight required depends on the extension and type of instruction, but will typically be any amount in excess of $50\%$ of the weight of data providers.

### Cosigners 
Similarly, certain extensions and instructions permit the use of *cosigners* to increase security. 
A cosigner is a Flare address that the user who issued the instruction event assigns to increase the security of the instruction. 
In an instruction event with `cosigners` and `cosignerThreshold` event included, the TEE proxy will only accept the corresponding TEE instruction upon receiving both the threshold weight of data provider signatures and an amount of cosigner signatures exceeding `cosignerThreshold` from the designated cosigner addresses. 
The possible addresses valid to be included `cosigners` depends on the extension and instruction; some extensions may indicate valid cosigner addresses, but in other cases any address can be used.

Note that it is in theory possible for a weighted majority of data providers to delete or change the cosigner fields in a given instruction to circumvent the extra security provided.
Each extension that intends to use cosigner fields must prepare its own protection against such an attack.
For example, requiring the action response [reference] to include the cosigner signatures allows a contract on Flare to confirm that the cosigners signed the instruction.

## TEE Instructions
After an instruction event has been emitted on Flare, it is the duty of the data providers, and any optional cosigners, to respond to the event by first preparing a *TEE instruction*, then signing this new instruction and forwarding it to the appropriate TEE(s). 
A TEE receives this instruction from a data provider (or cosigner) in two parts, a package $\text{data}$ containing the instruction and a signature $\mathrm{sign}_{\mathrm{sk}}$, a signature over the data performed using the senders secret key.

### Data Format
The package $\text{data}$ contains all the information that the TEE machine needs to execute the instruction. The information in the package is arranged as 

- `instructionId`: As in the instruction event.
- `teeID`: The unique identity of the destination TEE machine.
- `timestamp`: The time stamp of the block in which the instruction was issued.
- `rewardEpochID`: The ID of the reward epoch in which the instruction was issued.
- `opType`: As in the instruction event.
- `opCommand`: As in the instruction event.
- `originalMessage`: The `message` from the instruction event.
- `cosigners`: As in the instruction event.
- `cosignerThreshold`: As in the instruction event.
- `additionalFixedMessage`: Binary data depending on the command.
- `additionalVariableMessage`: Binary data depending on the command [are these two essentially the instruction? Presumably] 

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

## Direct Instructions
In certain circumstances, governance or administrating addresses are able to directly instruct participating TEE machines, circumventing the need for commands to be signed and packaged by data providers and cosigners. 
Such a command is known as a *direct instruction*. 
The payload for a direct instruction is simpler than a normal instruction, and consists of only three parts, defined in the same manner as above:

- `opType`
- `opCommand`
- `message`.

Note that in some cases TEEs will still only follow direct instructions that have been signed by an appropriate number of signees; for example, in cases where the governance of an extension is via a multisig, the TEE will only accept a direct instruction in response to receiving a threshold number of signatures for it.
