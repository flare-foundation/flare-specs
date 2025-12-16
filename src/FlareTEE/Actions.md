# Actions
In the FlareTEE architecture, an *action* is a data structure prepared by a TEE proxy for processing by its associated TEE machine.
Actions are prepared in response to instructions for which the TEE proxy has received the necessary amount of signatures to accept.
Once pushed to the TEE machine, the command corresponding to the action is executed, with the results returned to the TEE proxy.
The TEE proxy hosts an API making action results available to interested users. 

## Action Structure
The data structure of an action sent to a TEE machine has the following syntax:

- `data`: The data required to execute the action. The structure of this data is given below.
- `signatures`: The signatures of the data providers and cosigners who assembled the corresponding instruction. 
- `additionalVariableMessages`: The set of `additionalVariableMessage` variables sent by the signers, arranged in the same order as the list of signatures. Empty for actions resulting from direct instructions.
- `timestamps`: The timestamps of arrival of the instructions from the signers, arranged in the same order as the signatures. If the action does not arise from an instruction, only a single timestamp is given, included by the TEE proxy [unclear on this?].
- `additionalActionData`: Byte encoded data provided by the TEE proxy, necessary in certain cases where the proxy must provide extra information to the machine.

Note that the existence of the `signatures` field enforces that the TEE machines do not trust actions sent by the TEE proxy.
Instead, they need to see the signatures as well.
The structure of the `data` field is fixed as below:

- `id`: A unique identifier for the action.
- `type`: "Direct" or "Instruction" depending on whether or not the instruction was direct.
- `submissionTag`: Indicates purpose of the action.
- `message`: A byte encoded message listing the parameters of the action.

## Action Processing
Once a TEE machine receives a signed action from the proxy, it is added to the [processing queue](TEEOwnership.md) to be completed. 
When the action is at the top of the queue, the TEE processes it and removes it from the queue.
The nature of this processing depends on the extension, and type of action, and any input parameters.
For example, in the PMW case, the action may be to sign a transaction to be completed on the external chain.


## Responses
After a TEE machine processes an action, it returns an *action response* to the corresponding TEE proxy.
The response is signed by the TEE, confirming for the proxy that the response came from the machine itself. 
The main data stored in the response itself varies depending on the content of the action, with the response sent as a pair $(\mathrm{result}, \mathrm{sign})$, with $\mathrm{result}$ formatted as follows:

- `id`: As above.
- `submissionTag`: As above.
- `status`: Indicates the status of the execution in $\mathrm{uint}8$. Typically $0$ for error and $1$ for success, with higher values available for more complicated actions.
- `log`: Optional; in cases where status is not success, an exception log is provided. Empty if the status is success.
- `opType`: As indicated in the instruction.
- `opCommand`: As indicated in the instruction.
- `version`: The version of the result, defining how the result `data` is encoded.
- `additionalResultStatus`: Optional; additional messages from the TEE machine to the proxy.
- `data`: Binary encoded result of the action, typically including a signature by some key stored on the TEE machine. Structure depends on the action instruction and version of the machine.

The signature $\mathrm{sign}$ is the signature over the hash

$\mathrm{hash}(\mathrm{hash}($`data`$),$ `id`$,$ $\mathrm{hash}$$($`submissionTag`$)$$,$ `status`$)$.

performed by the private key corresponding to the unique identity $\mathrm{TEE}_{\mathrm{ID}}$ of the TEE machine, and contains no other action response information, with `data` a self-contained store of the result of the action.

## Reward Data
Alongside the result of the action, certain action responses will be accompanied by reward data to help determine the distribution of fees as rewards amongst data providers on Flare.
Reward data is included in the action response in the case where the `submissionTag` is set to "end".
In this case, the reward data is included in the result of the action, consisting of the following structure:

- `voteSequence`: Data about the voting for the action containing:
	- `voteHash`: The hash of the vote queue [cite vote process].
	- `instructionID`: The unique ID of the instruction.
	- `instructionHash`: The hash of the instruction.
	- `rewardEpochID`: The ID of the reward epoch in which the instruction was issued.
	- `teeID`: The unique identity of the TEE.
	- `signatures`: The list of data provider signatures.
	- `additionalVariableMessageHashes`: A list of hashes of each `additionalVariableMessage` included by the providers, in the same order as the list of signatures.
	- `timestamps`: The list of timestamps of the votes, in the same order as the signatures.
- `additionalData`: A binary encoding of any additional required rewarding data that is known to the TEE, depending on the instruction and instruction type.
- `version`: Encoding version for the data.
- `signature`: Signature by the TEE machine of $\mathrm{hash}($`voteHash`$,$`additionalData`$)$ using the key corresponding to $\mathrm{TEE}_{\mathrm{ID}}$. 

How this data is used for rewarding is given in [rewarding](rewarding.md).