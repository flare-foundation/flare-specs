# Merkle Tree

There are several types of [Merkle trees](https://en.wikipedia.org/wiki/Merkle_tree), depending on their purpose.
We describe a Merkle tree used by Flare Systems protocol.

For working with Merkle trees, the following "standard" [Open Zeppelin library](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol) can be used.

## Structure

A Merkle tree on $n$ sorted hashes is represented by an array of length $2n - 1$, which represents a complete binary tree.
A complete binary tree is a binary tree in which all levels are completely filled except possibly the lowest one, which is filled from the left.

A complete binary tree with $2n - 1$ elements has exactly $n$ leaves and all nodes are either leaves or have two children (left and right).

A Merkle tree with $n$ leaves can be presented with an array of exactly $2n - 1$ length, where the last $n$ elements are leaves.
This representation of a complete binary tree is well known from classic implementation of binary heaps.
It encodes the tree structure as follows:

- The Merkle root is at index $0$.
- Leaves are on the last $n$ indices, from $n - 1$ to $2n - 2$.
- Given an index $i$ of a node in the tree, the parent and both children are as follows:

  ```text
  parent(i) = floor((i - 1)/2)
  left(i)   = 2i + 1,      if 2i + 1 < 2n - 1
  right(i)  = 2i + 2,      if 2i + 2 < 2n - 1.
  ```

- A sibling of the node (that is not root) with index $i$ is calculated by:

  ```text
  sibling(i) = i + 2(i % 2) - 1
  ```

Each node holds a value of type bytes32.
A value of a non-leaf node is a (sorted) hash of values of its children.
In the solidity code, it is defined by

```Solidity
function sortedHash(bytes32 _hash1, bytes32 _hash2) external pure returns (bytes32) {
    return _hash1 < _hash2 ? keccak256(abi.encode(_hash1, _hash2)) : keccak256(abi.encode(_hash2, _hash1));
}
```

Basically, the two hashes are first sorted, then joined, and then a hashed.

## Building a Merkle Tree

A Merkle tree on $n$ hashes is built as follows:

- $n$ hashes are sorted in ascending order.
  Note that the order is unique.
- An array $M$ with $2n - 1$ elements is allocated.
- $n$ hashes are put into the slots from $n - 1$ to $2n - 2$, i.e, $M[n-1],\dots, M[2n - 2]$.
- for $i = n - 2$ down to $0$, the value is $M[i] = \mathrm{sortedHash}(M[\mathrm{left}(i)], M[\mathrm{right}(i)])$

## Merkle Proof

A Merkle proof for a leaf is the sequence of values of siblings of the nodes on the shortest path form the leaf to the root which enables the calculation of Merkle root from the leaf.
Let $M$ be an array representing a Merkle tree on $n$ leaves with $2n - 1$ nodes as above.
The hashes appear on indices $n-1$ to $2n - 2$ and are sorted.
Hence, the $k$-th hash appears on the index $n - 1 + k$.
The Merkle proof for the $k$-th hash can be assembled by using the following pseudocode:

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

### Verifying with a Merkle proof

To verify that a hash is included in a Merkle tree one needs a Merkle proof and a Merkle root.
The verification is done with the following algorithm (in pseudocode):

```text
verify(proof, root, hash) {
    let computedHash = hash;
    for sibling in proof {
        computedHash = sortedHash(computedHash, sibling);
    }
    return computedHash == root;
}
```
