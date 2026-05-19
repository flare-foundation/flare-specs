# Attestation

On registration, and periodically during their operation, TEE platform operators are required to attest to certain aspects of the machine's [state](State.md).
The ability to securely perform this attestation is a crucial property of a TEE machine.
The exact response format depends on the TEE platform, as the signed attestation is performed by the operator (e.g. Google for Intel TDX and AMD-SEV).

## Challenge and Response

A TEE machine operator provides an attestation response to a *challenge*, a $32$-byte string provided by a challenger.
The challenger can be any entity who wants to confirm the state of the TEE machine.
Upon receiving the challenge, the TEE machine generates a challenge hash specific to the machine.
To generate the challenge hash, the [`Attestation`](../Types/Abi/TeeMachine.md#attestation) struct is ABI encoded and then hashed.
The `publicKey` is the key that corresponds to $\mathrm{TEE}_\mathrm{ID}$.
The initial and last signing policies refer to the first and most recent signing policy available to the TEE respectively.
The `state` field is encoded as the [`TeeState`](../Types/Abi/TeeMachine.md#teestate) struct.
The `teeTimestamp` refers to the local timestamp at the TEE machine at time of attestation.
Thus, the TEE-specific challenge is $\mathrm{hash}(\mathrm{Attestation})$.

Once the TEE specific challenge is created, the platform provider signs the challenge and returns the response.
