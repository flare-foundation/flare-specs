# Migration: Relay v2

Relay v2 is a security release for the `Relay` contract.
It contains several fixes that required interface or behaviour changes:

- **Signatures are bound to one network** ([§2.1](#21-source-bound-digests)) — both digests include the chain id, so a signature cannot be replayed on another Flare network.
- **Finalizing an FTSO round carries the random number and a Merkle proof** ([§2.2](#22-the-random-number-and-its-merkle-proof-in-relay-calldata)).
- **Malleable signatures are rejected** ([§2.3](#23-signature-canonicalization)).
- **Reverts are typed errors** ([§2.4](#24-typed-revert-errors)) — 4-byte selectors instead of revert strings.
- **The random number read from the contract is the round's own value** ([§2.5](#25-reads-and-the-random-number)), no longer a hash of the Merkle root.

The new version is deployed ahead of the switch and takes over on each network at the scheduled **cutover epoch** ([§1](#1-schedule-and-addresses)).
Since changes are not backwards compatible, FSP clients need to implement support for a graceful switch to the new `Relay`, which should happen at the first voting round of the cutover epoch.

## 1. Schedule and addresses

The cutover epoch is the first reward epoch whose voting rounds are signed for, and finalized on, the new `Relay`.
The boundary is that epoch's `startVotingRoundId`, read from the chain ([§3](#3-boundary)).

The signing policy for the cutover epoch is generated at the end of the previous epoch and should still be signed with the old semantics ([which scheme applies](#which-scheme-applies)).

| Network | Chain id | Cutover epoch | New `Relay` | Old `Relay` |
| --- | --- | --- | --- | --- |
| Coston | 16 | 5991 | `0xEcD0B60Ea5E01e4D0bFd621c8920B40A32389b83` | `0x051f214D346Cfd97B107BECb87E2B35D1b4287E9` |
| Coston2 | 114 | TBA | `0x5017728F117501A24EF9C3756C07f0d564598596` | `0xa10B672D1c62e5457b17af63d4302add6A99d7dE` |
| Songbird | 19 | TBA | `0xc1BC89b717Af42AE27497C9FFb996002D3AC5031` | `0xCB86E8Be709001e01897Bf59847406853da8f14b` |
| Flare | 14 | TBA | `0x5A2Eb0cdB4Aa8253924a488A77EdfD24Bb64407f` | `0xCcF30790A93F15e24EB909548a2C58a9b0a7FBd4` |

Each address is fixed by `Create3Factory` ahead of time, so it can be configured now.
Only Coston is deployed; the other three hold no code until the epoch before their own cutover.
Of the mainnets, Songbird switches first and Flare follows.

## 2. Changes

Samples below are TypeScript with [ethers](https://docs.ethers.org) v6.

### 2.1 Source-bound digests

`sourceChainId` is the chain id of the network the contract serves, fixed when it is deployed and never changed afterwards.
It is mixed into both verified hashes as a 32-byte big-endian word followed by the unpadded content bytes:

```
keccak256(abi.encodePacked(uint256 sourceChainId, <content bytes>))
```

#### Protocol message

The content is the 38-byte [`ProtocolMerkleRoot`](../FSP/Encoding.md#protocolmerkleroot) message, unchanged; only the [EIP-191 preimage](../Utilities/Signing.md) it is signed under changes.

```ts
import { concat, getBytes, hashMessage, keccak256, toBeHex } from "ethers";

const legacyPreimage = (message: string) => keccak256(message);                                 // before
const boundPreimage = (message: string) => keccak256(concat([toBeHex(chainId, 32), message]));  // after

// EIP-191 signing and recovery are unchanged; only the preimage moves
const signature = await wallet.signMessage(getBytes(boundPreimage(message)));
const digest = hashMessage(getBytes(boundPreimage(message)));   // what a verifier recovers against
```

Verification changes symmetrically: recovering signers against the wrong digest yields unregistered addresses, and every voter's weight is silently dropped.

#### Signing policy

The hash `FlareSystemsManager.signNewSigningPolicy` accepts and `Relay.toSigningPolicyHash` stores:

| | hash of the encoded [`SigningPolicy`](../FSP/Encoding.md#signingpolicy) bytes |
| --- | --- |
| old `Relay` | zero-pad to a multiple of 32 bytes, `h = keccak256(chunk₀ ‖ chunk₁)`, then `h = keccak256(h ‖ chunkᵢ)` per further chunk |
| new `Relay` | `keccak256(uint256(chainId) ‖ policyBytes)`, one `keccak256`, no padding |

```ts
// before
function legacyPolicyHash(policy: string): string {
  const pad = dataLength(policy) % 32;
  const w = pad ? concat([policy, new Uint8Array(32 - pad)]) : policy;
  let h = keccak256(dataSlice(w, 0, 64));
  for (let i = 64; i < dataLength(w); i += 32) h = keccak256(concat([h, dataSlice(w, i, i + 32)]));
  return h;
}

// after
const boundPolicyHash = (policy: string, chainId: number) =>
  keccak256(concat([toBeHex(chainId, 32), policy]));
```

#### Which scheme applies

The signing policy for the cutover epoch is created in the usual way, during the previous epoch and while `FlareSystemsManager` still points at the old contract: the old contract emits its `SigningPolicyInitialized`, and the voters sign the policy under the old hashing scheme.
The new contract is then deployed already holding that same policy — the bytes the old contract initialized, hashed the source-bound way — together with the epoch's start round.
`initialize` also pins `lastInitializedRewardEpoch` to the cutover epoch without emitting an event, so the first `setSigningPolicy` on the new contract is the epoch *after* the cutover.
`FlareSystemsManager` is repointed once the cutover epoch's signing ceremony has closed.

The two schemes therefore do not switch at the same point:

| Artifact | Old scheme | New scheme |
| --- | --- | --- |
| Protocol messages (FTSO, FDC) | rounds before the boundary | from the boundary on |
| Signing policies | epochs up to and including the cutover epoch | from the epoch after the cutover |
| `SigningPolicyInitialized` emitted by | old `Relay`, up to and including the cutover epoch | new `Relay`, from the epoch after |

- The cutover epoch's policy therefore exists on both contracts, under a different hash on each — the same bytes, one folded the old way, one source-bound.
  Which of the two you must sign follows from the contract `FlareSystemsManager` points at ([§3](#3-boundary)).
- Because both contracts hold it, the switch is reversible for the whole of the cutover epoch.
  It is committed once the next epoch's policy has been signed source-bound.
- A deployment that instead seeded the epoch *before* the cutover, repointing ahead of that epoch's ceremony, would flip the policy scheme an epoch earlier, with the message boundary unchanged.
  The scheme is therefore something to read off the chain, not to derive from the cutover epoch.

Both schemes stay valid, selected per reward epoch (messages: per voting round), for as long as history is verified or graded.

### 2.2 The random number and its Merkle proof in `relay()` calldata

Finalizing an FTSO round (protocol id `100`) now requires two extra pieces of calldata after the signatures: the round's random number, and a Merkle proof of it against the `merkleRoot` carried in the signed message.
FDC and signing policy relays are unaffected and take nothing extra.

```
selector(4) │ signingPolicy(variable) │ message(38) │ sigCount(2) │ signatures(67 × n) │ randomNumber(32) │ proof(32 × k)
```

The contract takes everything after the last signature as the random number and proof, so they must come last and occupy a whole number of 32-byte words.
The tree itself is unchanged — this is the FTSO random leaf the round already builds:

- `leaf = keccak256(abi.encode(uint256 votingRoundId, uint256 value, uint256 isSecure))`
- `isSecure` is read from the signed message and normalized to `0`/`1`, not taken from the appended data, so a proof built against the other value will not verify
- each proof step hashes the pair in ascending order — `keccak256(min ‖ max)`, OpenZeppelin's sorted-pair convention

```ts
// before: the relay() calldata ended with the signatures
const calldata = concat([selector, signingPolicy, message, sigCount, signatures]);

// after: append the value and its proof, and check the fold first
const leaf = keccak256(AbiCoder.defaultAbiCoder().encode(
  ["uint256", "uint256", "uint256"], [votingRoundId, value, isSecure ? 1 : 0]));
const fold = (leaf: string, proof: string[]) => proof.reduce(
  (h, n) => BigInt(h) < BigInt(n) ? keccak256(concat([h, n])) : keccak256(concat([n, h])), leaf);

if (fold(leaf, proof) !== merkleRoot) throw new Error("proof does not match the signed root");
const calldata = concat([selector, signingPolicy, message, sigCount, signatures,
                         toBeHex(value, 32), ...proof]);
```

| Condition | Error |
| --- | --- |
| nothing, or fewer than 32 bytes, after the signatures | `NoRandomNumber()` |
| appended bytes not a whole number of 32-byte words | `IncorrectMerkleProof()` |
| fold does not reproduce the signed root | `InvalidRandomNumberProof()` |

On success the contract stores the random number for that round, so the read methods in [§2.5](#25-reads-and-the-random-number) can serve it, records the secure flag, and emits a new event (additive, for indexers):

```solidity
event RandomNumberRelayed(
    uint32 indexed votingRoundId,
    uint256 randomNumber,
    bool isSecureRandom
);
```

### 2.3 Signature canonicalization

ECDSA signatures are malleable: `(r, s, v)` and `(r, n − s, v ^ 1)` are different bytes that recover the same signer.
The new contract accepts only the canonical low-`s` form.
This is defence in depth: signature indices already have to ascend, which by itself stops the same voter's weight being counted twice.
`v ∉ {27, 28}` (`BadV()`) and `s` above half the group order (`BadS()`, [EIP-2](https://eips.ethereum.org/EIPS/eip-2)) now revert the entire `relay()` call.

The old contract has neither check, so a signature from a provider whose signer does not normalize `s` is accepted today and rejected after the cutover — and because the revert is not scoped to that one signature, including it costs the finalizer the whole round.
Dropping such a signature is the wrong fix, since it forfeits that voter's weight and can leave the round below threshold.
Normalize instead, as each signature is collected and before its weight is counted:

```ts
const N      = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141n;
const HALF_N = 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0n;

function canonical({ v, r, s }: { v: number; r: string; s: bigint }) {
  if (v !== 27 && v !== 28) throw new Error("BadV");
  return s <= HALF_N ? { v, r, s } : { v: v === 27 ? 28 : 27, r, s: N - s };
}
```

### 2.4 Typed revert errors

Every revert is a 4-byte custom error selector taking no arguments, instead of a revert string, so anything matching on revert reason text has to change.
All of them are declared in `contracts/userInterfaces/IRelay.sol`, so they are part of the contract ABI and any ABI-aware decoder resolves them by name:

```ts
// before
if (err.reason?.includes("already relayed")) return;

// after
const relay = new Interface(relayAbi);   // the IRelay errors come with the ABI
if (relay.parseError(err.data)?.name === "AlreadyRelayed") return;
```

`AlreadyRelayed()` (`0xd0ebeb4b`) is worth special-casing: it means the round was finalized by someone else, the expected outcome of a lost race, and should be neither retried nor alerted on.
The errors specific to this migration are `BadV()` and `BadS()` ([§2.3](#23-signature-canonicalization)), and `NoRandomNumber()`, `IncorrectMerkleProof()` and `InvalidRandomNumberProof()` ([§2.2](#22-the-random-number-and-its-merkle-proof-in-relay-calldata)).

### 2.5 Reads and the random number

History stays readable from the new address, so a consumer repoints once and keeps working.
For rounds before the boundary the new contract forwards `verify`, `isFinalized`, `merkleRoots` and `getRandomNumberHistorical` to the old one, and it does the same with `toSigningPolicyHash` for epochs before the cutover.
The old contract is not decommissioned, since those reads still land on it.

- `getRandomNumber()`, which reports the latest round rather than a specific one, does **not** forward: it returns `(0, false, timestamp)` until the first FTSO finalization lands on the new contract.
  Gate on `_isSecureRandom`.
  `getRandomNumberHistorical` reverts with `NoRandomNumber()` for an absent round.
- The value itself changes.
  The old contract hashed the round's whole Merkle root, `uint256(keccak256(abi.encode(merkleRoot)))`.
  The new one returns the random number the FTSO round produced, as proven against that root at finalization.
  Pre-boundary rounds are unchanged, being served by delegation.

## 3. Boundary

The cutover epoch and the new address are configuration, but the boundary round is not: a reward epoch can start later than its nominal schedule, and the rounds in that delay still belong to the previous epoch.
Computing the boundary from the epoch schedule therefore puts the switch in the wrong place; read it from the chain.

- **Boundary round**: the cutover epoch's `startVotingRoundId`, from its `SigningPolicyInitialized` event (watching both contracts), `FlareSystemsManager.getStartVotingRoundId(cutoverEpoch)`, or `Relay.startingVotingRoundIds(cutoverEpoch)`.
  All three agree.
  Take the first value learned and refuse a later one that disagrees, rather than silently re-dating the switch.
- **Digest per round**: decide from the voting round inside the message itself, so that a signer, a verifier and a finalizer reach the same answer without sharing any state:

  ```ts
  const digestFor = (message: string, votingRoundId: number) =>
    hashMessage(getBytes(votingRoundId < boundaryRound ? legacyPreimage(message) : boundPreimage(message)));
  ```

- **Policy hash**: hash the policy bytes you observed both ways and see which one matches `Relay.toSigningPolicyHash(rewardEpochId)` on the contract `FlareSystemsManager` currently points at.
  The chain value only selects the scheme — always sign a hash you derived from the policy bytes, never the stored value itself.

  ```ts
  const stored = await relay.toSigningPolicyHash(rewardEpochId);
  const hash = [legacyPolicyHash(policyBytes), boundPolicyHash(policyBytes, chainId)]
    .find((h) => h === stored);
  if (!hash) throw new Error(`no supported hash of epoch ${rewardEpochId} matches ${stored}`);
  ```

- **Signing policies come from both contracts** across the boundary — old up to and including the cutover epoch, new from the epoch after — merged and selected by reward epoch, not by log recency.
  Missing this fails one epoch late, when the first policy only the new contract emitted is needed.

## 4. Coston, for verification against a live network

| | |
| --- | --- |
| new `Relay` (proxy) | `0xEcD0B60Ea5E01e4D0bFd621c8920B40A32389b83` |
| implementation behind the proxy | `0x88C2D06dB810f267681333502E8409107c201Fb2` |
| old `Relay` | `0x051f214D346Cfd97B107BECb87E2B35D1b4287E9` |
| `FlareSystemsManager` | `0x85680dd93755fe5d0789773fd0896cee51f9e358` |
| `sourceChainId` | 16 |
| `initialRewardEpochId` — the cutover epoch | 5991 |
| `startingVotingRoundIdForInitialRewardEpochId` — the boundary round | 1437840 |
| first `setSigningPolicy` on the new contract | epoch 5992 |
| old contract's `lastInitializedRewardEpoch` | 5991 |

`toSigningPolicyHash`, showing the split of [Which scheme applies](#which-scheme-applies):

| epoch | new `Relay` | old `Relay` |
| --- | --- | --- |
| 5990 | `0x6bd3dd27…56a0` | `0x6bd3dd27…56a0` (delegated) |
| 5991, the cutover epoch | `0xf657306e…56a3` (source-bound) | `0xfba36428…3744` (legacy fold, signed) |
| 5992 | `0x62960047…9099` (source-bound, signed) | `0x0` (never initialized) |

Round 1437839 reads identically from both contracts (delegated); 1437840, the boundary, is held only by the new one.

## 5. References

- [Signing](../Utilities/Signing.md), [FSP Encoding Reference](../FSP/Encoding.md), [Finalization](../FSP/Finalization.md), [Random Number](../FSP/RandomNumber.md), [Signing Policy](../FSP/SigningPolicy.md)
- `Relay.sol`, `IRelay.sol` in [flare-smart-contracts-v2](https://github.com/flare-foundation/flare-smart-contra