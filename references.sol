// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library References {
    function standardAddressHash(string calldata _address) external pure returns (bytes32) {
        return keccak256(bytes(_address));
    }

    function sortedHash(bytes32 _hash1, bytes32 _hash2) external pure returns (bytes32) {
        return _hash1 < _hash2 ? keccak256(abi.encode(_hash1, _hash2)) : keccak256(abi.encode(_hash2, _hash1));
    }
}
