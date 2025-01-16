# Merkle tree

There are several types of [Merkle trees](https://en.wikipedia.org/wiki/Merkle_tree), depending on their purpose.
We describe a Merkle tree used by Flare Systems protocols.

For working with Merkle trees, the following "standard" [Open Zeppelin library](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol) can be used.

## Merkle tree structure

A Merkle tree on _n_ sorted hashes is represented by an array of length _2n - 1_, which represents a complete binary tree.
A complete binary tree is a binary tree in which all levels are completely filled except possibly the lowest one, which is filled from the left.

A complete binary tree with _2n - 1_ elements has exactly _n_ leaves and all nodes are either leaves or have two children (left and right).

A Merkle tree with _n_ leaves can be presented with an array of exactly _2n - 1_ length, where the last _n_ elements are leaves.
This representation of a complete binary tree is well known from classic implementation of binary heaps.
It encodes the tree structure as follows:

- The Merkle root is at index _0_.
- Leaves are on the last _n_ indices, from _n - 1_ to _2n - 2_.
- Given an index _i_ of a node in the tree, the parent and both children are as follows:

  ```text
  parent(i) = floor((i - 1)/2)
  left(i)   = 2*i + 1,      if 2*i + 1 < 2*n - 1
  right(i)  = 2*i + 2,      if 2*i + 2 < 2*n - 1.
  ```

- A sibling of the node (that is not root) with index _i_ is calculated by:

  ```text
  sibling(i) = i + 2*(i % 2) - 1
  ```

Each node holds a value of type bytes32.
A value of a non-leaf node is a (sorted) hash of values of its children.
In the solidity code, it is defined by

```Solidity
function sortedHash(bytes32 _hash1, bytes32 _hash2) external pure returns (bytes32) {
    return _hash1 < _hash2 ? keccak256(abi.encode(_hash1, _hash2)) : keccak256(abi.encode(_hash2, _hash1));
}
```

where `hash(data)` is a hash function that, given a byte sequence `data`, produces a 32-byte hash. `sort(list)` is the sorting function for a list of byte strings and `join(list)` is the function that concatenates byte strings to a single byte string in order of appearance.

Basically it means that given two hashes they are first sorted, then joined, and then a hash is produced.

## Building a Merkle tree

A Merkle tree on _n_ hashes is built as follows:

- _n_ hashes are sorted in ascending order.
  Note that the order is unique.
- An array `M` with _2n - 1_ elements is allocated.
- _n_ hashes are put into the slots from _n - 1_ to _2n - 2_, this is, `M[n-1], ..., M[2n - 2]`.
- for _i = n - 2_ down to 0, calculate `M[i] = sortedHash( M[left(i)], M[right(i)])`

## Building a Merkle proof

A Merkle proof for a leaf is the shortest sequence of hashes in the Merkle tree on a path to the Merkle root that enables the calculation of the Merkle root from the leaf (array of values of siblings of the nodes on the path from the leaf to the root.).
Let `M` be an array representing a Merkle tree on _n_ leaves with _2n - 1_ nodes defined as above.
The hashes appear on indices _n-1_ to _2n - 2_ and are sorted.
Hence the _k_-th hash appears on the index _n - 1 + k_.
The Merkle proof for the _k_-th hash can be calculated by using the following pseudocode:

```text
getProof(k) {
   if (n == 0 || k < 0 || k >= n) {
      return null;
   }
   let proof = [];
   let pos = n - 1 + k;
   while (pos > 0) {
      proof.push(M[sibling(pos)]);
      pos = parent(pos);
   }
   return proof;
}
```

## Verifying with a Merkle proof

To verify that a hash is included in a Merkle tree one needs a Merkle proof and a Merkle root.
The verification is done with the following algorithm (in pseudocode):

```text
verify(proof, root, hash) {
    computedHash := hash
    for siblingHash in proof {
        computedHash = sortedHash(computedHash, siblingHash)
    }
    return computedHash == root
}
```
