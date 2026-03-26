# Relay Client
A *relay client* is an off-chain component used by data providers and cosigners to transform instruction events on Flare into signed TEE instructions submitted to TEE proxies.
This page specifies the relay client as a blackbox component.

## Role
The relay client performs the following functions:

- It consumes `TeeInstructionsSent` events from Flare.
- It determines whether the local signer is permitted to relay the instruction.
- It prepares any command-specific augmentation required for the corresponding TEE instruction.
- It signs the resulting TEE instruction for each destination TEE machine.
- It submits the signed TEE instructions to the corresponding TEE proxies.

## Interfaces
The relay client interacts with the FlareTEE system through the following interfaces:

- Input from Flare: the `TeeInstructionsSent` event stream emitted by the `TeeExtensionRegistry`.
- Output to the proxy layer: the `POST /instruction` endpoint defined in [TEE Proxies](TEE Management/Tee Proxies.md).

The relay client may also consume command-specific off-chain data required to prepare `additionalFixedMessage` or `additionalVariableMessage`.
The semantics of those fields are defined by the relevant owner pages.

## Relay Roles
A relay client operated by a data provider may relay any instruction for which that provider is eligible to vote under the current signing policy.
A relay client operated by a cosigner may relay only instructions in which its address appears in the `cosigners` list.

## Relay Flow
For a standard instruction event, the relay client proceeds as follows:

1. It observes the instruction event on Flare.
2. It checks whether the local signer is permitted to relay the instruction.
3. It prepares the command-specific augmentation required for the instruction.
4. It constructs one TEE instruction for each destination TEE machine.
5. It signs each instruction.
6. It submits the signed instructions to the relevant proxies.

One signed instruction is required per destination TEE machine because `teeID` is part of the signed instruction payload.

## Behavior
The relay path is *best effort*.
It does not guarantee delivery or ordering.
The same instruction may therefore be submitted more than once or arrive in different orders at different proxies.
This is compatible with proxy voting and, where required, replay protection inside the TEE machine.

Direct instructions bypass the relay client.
They are submitted directly to the proxy through the direct-instruction path with signatures collected out-of-band.

## Specialized Relay Cases
Certain instruction families impose additional relay-side requirements.

### FDC2
For [FDC2](Extensions/FTDC.md), the relay client obtains or constructs the attestation response off-chain.
It places the encoded `requestBody` into `additionalFixedMessage`.
It places its signature over the attestation response hash into `additionalVariableMessage`.

### Key Restoration
For key restoration, as specified in [Key Management](TEE Management/Key Management.md), the relay client or equivalent off-chain component extracts its holder backup package, decrypts its own share, re-encrypts that share for the target TEE machine, and submits the resulting restore instruction.

## Limitations
The relay client is a transport and augmentation component only.
It does not determine voting thresholds.
It does not determine whether a set of votes is sufficient.
It does not execute actions.
It does not determine the final validity of the requested operation.
Those checks remain the responsibility of the proxy, the TEE machine, and the relevant on-chain contracts.
