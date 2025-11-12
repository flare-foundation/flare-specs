# Actions
In the FlareTEE architecture, an *action* is a data structure prepared by a TEE proxy for processing by its associated TEE machine.
Actions are prepared in response to instructions for which the TEE proxy has seen the necessary amount of signatures to accept.
Once pushed to the TEE machine, the command corresponding to the action is executed, with the results returned to the TEE proxy, which hosts an API making the results available to interested users. 

## Action Structure
The data structure of an action sent to a TEE machine has the following syntax:

- `data`: Contains the data required to execute the action, in a structure given below.
- `signatures`: The signatures of the data providers and/or cosigners who assembled the corresponding instruction. 
- `additionalVariableMessages`: The set of `additionalVariableMessage` variables sent by the signers, arranged in the same order as the list of signatures. Empty for actions resulting from direct instructions.
- `timestamps`: Timestamps of arrival of the instructions from the signers, arranged in the same order as the signatures. If the action does not arise from an instruction, only a single timestamp is given, included by the TEE proxy [unclear on this?].
- `additionalActionData`: Byte encoded data provided by the TEE proxy, necessary in certain cases where the proxy must provide extra information to the machine.

Note that the existence of the `signatures` field enforces that the TEE machines do not trust actions sent by the TEE proxy; instead, they need to see the signatures as well.
The structure of the `data` field is fixed as below:

- `id`: A unique identifier for the action.
- `type`: "Direct" or "Instruction" depending on whether or not the instruction was direct.
- `submissionTag`: Indicates purpose of the action.
- `message`: A byte encoded message listing the parameters of the action.

## Responses
After a TEE machine processes an action, it returns an *action response* to the corresponding TEE proxy.
The response is signed by the TEE, so that the proxy knows that the response came from the machine itself. 
The main data stored in the response itself varies depending on the content of the action, with the response sent as a pair $(\mathrm{result}, \mathrm{sign})$, with $\mathrm{result}$formatted as follows:

- `id`: As above.
- `submissionTag`: As above.
- `status`: Indicates the status of the execution in uint8. Typically $0$ for error and $1$ for success, with higher values available for more complicated actions.
- `log`: Optional; in case where status is not success, an exception log is provided. Empty if the status is success.
- `opType`: As indicated in the instruction.
- `opCommand`: As indicated in the instruction.
- `version`: Version of the result, defining how the result `data` is encoded.
- `additionalResultStatus`: Optional; additional messages from the TEE machine to the proxy.
- `data`: Binary encoded result of the action, typically of some kind of result and signature by some key stored on the TEE machine. Structure depends on the operation and version.

The signature $\mathrm{sign}$ as the signature over the hash

$\mathrm{hash}(\mathrm{hash}($`data`$),$ `id`$,$ $\mathrm{hash}$$($`submissionTag`$)$$,$ `status`$)$.

performed by the private key corresponding to the unique identity of the TEE machine, and is typically only required by the TEE proxy, with `data` a self-contained store of the result of the action.

## Reward Data
Alongside the result of the action, certain action responses will be accompanied by reward data to help determine the distribution of rewards amongst data providers on Flare.
Reward data is included in the action response in the case where the `submissionTag` is set to "end".
In this case, the reward data is included in the result of the action, consisting of the following structure:

- `voteSequence`: Data on the voting for the action containing
	- `voteHash`: The hash of the vote queue [cite vote process].
	- `instructionID`: The unique ID of the instruction.
	- `instructionHash`: The hash of the instruction.
	- `rewardEpochID`: The ID of the reward epoch in which the instruction was issued.
	- `teeID`: The unique identity of the TEE.
	- `signatures`: The list of data provider signatures.
	- `additionalVariableMessageHashes`: A list of hashes of each `additionalVariableMessage` included by the providers, in the same order as the list of signatures.
	- `timestamps`: The list of timestamps, in the same order as the signatures.
- `additionalData`: A binary encoding of any additional required rewarding data that is known to the TEE, depending on the instruction and instruction type.
- `version`: Encoding version for the data.
- `signature`: Signature by the TEE machine of $\mathrm{hash}($`voteHash`$,$`additionalData`$)$ using the key corresponding to its identity. 

How this data is used for rewarding is given in [cite rewarding].