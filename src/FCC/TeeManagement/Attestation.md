# Attestation

A TEE machine attests to elements of its [state](State.md) — identity key, signing policies, FCE state, timestamp — when challenged.
The attestation chain ends in a signature produced by the TEE platform operator (Google for Intel TDX and AMD SEV), so the response format is platform-specific.

## Challenge and Response

A _challenger_ — any entity that wants to verify a machine's state — provides a $32$-byte challenge.
The machine builds an [`Attestation`](../Reference/Types/Abi/TeeMachine.md#attestation) struct from the challenge and its own state:

- `publicKey`: TEE identity public key.
- `initialSigningPolicyId`, `lastSigningPolicyId`: first and most recent signing policies known to the machine.
- `state`: ABI-encoded [`TeeState`](../Reference/Types/Abi/TeeMachine.md#teestate) at the moment of attestation.
- `teeTimestamp`: local machine timestamp at attestation time.
- `challenge`: the challenger's $32$-byte input.

The machine ABI-encodes the struct, hashes it ($\mathrm{hash}(\mathrm{Attestation})$), and passes the digest to the platform operator's attestation service.
The platform's signed response binds the digest to the hardware-attested boot state and is returned to the challenger.

For the FDC2 attestation type that wraps this procedure into an on-chain proof, see [`TeeAvailabilityCheck`](../FDC2/Reference/AttestationTypes/TeeAvailabilityCheck.md).
