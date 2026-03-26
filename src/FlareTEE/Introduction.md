# Introduction
Flare Confidential Compute is an infrastructure project deployed on the Flare network to handle the secure outsourcing of operations to registered cloud-based Trusted Execution Environments (TEEs).
 A TEE is a secure, isolated, operating environment trusted to run specified code and store objects securely in memory.
 They are able to attest to their state, so that they will honestly execute instructions given to them in accordance to their code.

Flare users issue instructions to TEEs participating in Flare Confidential Compute via smart contracts on Flare, which are picked up by the data providers and relayed to the TEE network.
Once a TEE has received the instruction from a majority of data providers, it fulfils the instruction.
The results of the TEEs work is then relayed back onto the Flare network by the data providers or other participating entity. 

This documentation describes the processes and infrastructure that enable Flare Confidential Compute in technical detail.
It also describes two particular functions of Flare Confidential Compute: Protocol Managed Wallets [(PMWs)](Extensions/PMW/PMW.md) allow Flare users to control wallet accounts on external blockchains from Flare, and the Flare Data Connector [(FDC2)](Extensions/FTDC.md) that allows TEEs to verify the existence of external events.
A more high level description can be found in the accompanying White Paper.

## Extensions
Flare Confidential Compute manages the outsourcing of operations through a system of extensions. An extension on Flare Confidential Compute hosts a set of functions that can be sent to TEEs that are registered to that extension, with users calling these instructions via associated smart contracts.
For example, the [System Extension](Extensions/System Extension.md) hosts the PMW infrastructure, with users able to submit transaction instructions for their external wallet on Flare, which are then relayed to participating TEEs to perform.

Flare's users can create their own Flare Confidential Compute extensions, defining custom instructions to be performed by the TEE network.
Each extension is defined by the code to be deployed on the TEE network, as specified by the user.
In this way, the flexible design of Flare Confidential Compute allows Flare's users to leverage the security properties of the TEEs as they see fit, deploying their own code and instructions on the TEEs through the Flare infrastructure.
