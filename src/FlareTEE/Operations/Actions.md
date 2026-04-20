# Actions
In the Flare Confidential Compute architecture, an *action* is a data structure prepared by a TEE proxy for processing by its associated TEE machine.
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

> **Note:** Actions are not considered as trusted inputs to TEE machines. Consequently, the TEE machine must independently check input data and verify that the signatures meet the required threshold before executing an action. The `signatures` field exists precisely for this purpose.

The structure of the `data` field is fixed as below:

- `id`: A unique identifier for the action.
- `type`: "Direct" or "Instruction" depending on whether or not the instruction was direct.
- `submissionTag`: Indicates purpose of the action submission. Custom submission tags are supported, but common values include:
	- `threshold`: Used when the action is generated from an instruction at the point where the threshold of signatures is achieved.
	- `end`: Used when the action is generated from the instruction at the end of a voting process.
	- `submit`: Used for actions generated from direct instructions, where only a single submission is intended.
- `message`: A byte encoded message listing the parameters of the action. In case of instruction related commands, this is an instruction without `additionalVariableMessage` and `signature`, which are put in the parent struct. In case of direct instructions, it is a marshalled/serialized direct instruction payload

## Action Processing
Once a TEE machine receives a signed action from the proxy, it is added to the [processing queue](../TEE Management/Tee Proxies.md#processing-queues) to be completed.
When the action is at the top of the queue, the TEE processes it and removes it from the queue.
The nature of this processing depends on the extension, and type of action, and any input parameters.
For example, in the PMW case, the action may be to sign a transaction to be completed on the external chain.

### Queue Processing Modes
The TEE machine processes actions from three independent queues:
1. **Direct queue**: Processed sequentially (one action at a time). Used for proxy-initiated operations such as policy updates and TEE info requests.
2. **Main queue**: May have several workers processing actions concurrently. Used for instruction-based actions that have passed the voting threshold.
3. **Backup queue**: Processed sequentially. Used for key backup actions triggered by policy updates.

### Execution Guarantees
The processing for each action has a limited processing time.
If the processing time exceeds this limit, the operation is terminated as an exception.
Every exception is caught, and consequently some type of result is always produced.
Pushing action results back to the TEE proxy executes several retries if it fails.
If all retries fail, result pushing is abandoned.

### Command Routing

The decision flow for action processing at the TEE machine is as follows:

1. The body of the action is parsed and `opType` and `opCommand` are extracted.
2. For instruction actions, the available signatures and threshold requirements are verified against the signing policy. Direct actions skip this check.
3. If the `(opType, opCommand)` pair matches a registered processor, that processor executes the action and returns the result.
4. If the pair is not registered and the TEE machine has extension forwarding enabled, the action is forwarded to the compute extension service. If forwarding is not enabled, an error result is returned.

### Cosigner Enforcement

Required cosigners are published in [instruction](Instructions.md) events.
However, a weighted majority of malicious data providers could delete cosigners from the instruction or change them. 
The TEE proxy and Flare TEE logic would then not be aware of the requirement for cosigners and would execute the action without cosigner verification.

Mitigations for this are up to the extension in question:

- For system extension instructions that result in actions that use keys on the machine (except the `teeId` key), the existence of a threshold of cosigner signatures is checked and enforced by the Flare TEE node app.
- FCE extensions are responsible for their own cosigner enforcement. They can use the same mechanism as the system extension to authorize usage of private keys. Additionally, enforcement may be done externally, for example by requiring that action results contain both the TEE machine signature and the cosigner signatures as part of the result. For example, the `F_FDC2 PROVE` command allows a verifying contract to require signatures from multiple TEE machines and multiple cosigners.

## Responses
After a TEE machine processes an action, it returns an *action response* to the corresponding TEE proxy.
The response is signed by the TEE, confirming for the proxy that the response came from the machine itself. 
The main data stored in the response itself varies depending on the content of the action, with the response sent as a pair $(\mathrm{result}, \mathrm{sign})$, with $\mathrm{result}$ formatted as follows:

- `id`: As above.
- `submissionTag`: As above.
- `status`: Indicates the status of the execution in $\mathrm{uint}8$. Typically $0$ for error and $1$ for success, with higher values available for more complicated actions.
  - $0$: Error/invalid.
  - $1$: Success.
  - $2$: In-progress (used for async operations such as XRP payments where results are posted progressively).
  - $3+$: Scheduled responses (used for [fee schedule progression](../Extensions/PMW/Transactions.md#fee-scheduling)).
- `log`: Optional; in cases where status is not success, an exception log is provided. Empty if the status is success.
- `opType`: As indicated in the instruction.
- `opCommand`: As indicated in the instruction.
- `version`: The version of the result, defining how the result `data` is encoded.
- `additionalResultStatus`: Optional; additional messages from the TEE machine to the proxy.
- `data`: Binary encoded result of the action, typically including a signature by some key stored on the TEE machine. Structure depends on the action instruction and version of the machine.

The signature $\mathrm{sign}$ is the signature over the hash

$\mathrm{hash}(\mathrm{hash}($`data`$),$ `id`$,$ $\mathrm{hash}$$($`submissionTag`$)$$,$ `status`$)$.

performed by the private key corresponding to the unique identity $\mathrm{TEE}_{\mathrm{ID}}$ of the TEE machine, and contains no other action response information, with `data` a self-contained store of the result of the action.

## Proxy Result Hooks
After a TEE machine pushes an action result to the TEE proxy, the result is first stored in the action result store (Redis). Based on the `status`, `opType`, `opCommand`, and `additionalResultStatus` fields, the TEE proxy can trigger additional post-processing actions. For example, the proxy can contact external services and, based on their responses, provide additional information and possibly resubmit an action with `additionalActionData` and a custom `submissionTag`.

## Reward Data
Alongside the result of the action, certain action responses will be accompanied by reward data to help determine the distribution of fees as rewards amongst data providers on Flare.
Reward data is included in the action response in the case where the `submissionTag` is set to "end".
In this case, the reward data is included in the result of the action, consisting of the following structure:

- `voteSequence`: Data about the voting for the action containing:
	- `voteHash`: The hash of the [vote queue](Voting.md).
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

How this data is used for rewarding is given in [rewarding](../../FSP/Rewarding.md).