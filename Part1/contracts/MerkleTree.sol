//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// poseidon(uint256[2] memory input) public pure returns (uint256)
import {PoseidonT3} from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

// DEBUG
// import "./hardhat/console.sol";

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

event VoteCast(uint x);
    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves

        // let's maintain hashes.length == 2**n

        hashes = treeWithSameLeaves(uint256(0), 8);
        index = 8;
        root = hashes[hashes.length - 1];
    }

    function log2(uint256 power_of_two) 
    private 
    pure 
    returns (uint256) {
        uint256 n = 0;
        while (1 < power_of_two) {
            power_of_two >>= 1;
            n++;
        }
        return n;
    }

    // numLeaves == 2**n
    function treeWithSameLeaves(uint256 hashedLeaf, uint256 numLeaves)
        private
        pure
        returns (uint256[] memory)
    {
        uint256 treeHeight = log2(numLeaves);
        uint256[] memory hs = new uint256[](2 ** (treeHeight + 1) - 1); // hs=hashes (new hashes)
        
        uint256 hashValue = hashedLeaf;
        uint256 hsIx = 0;
        
        for (uint256 depth = treeHeight; depth > 0; depth--) {
            
            uint256 two_power_i = 2 ** depth;
            
            if (depth < treeHeight) {
                hashValue = PoseidonT3.poseidon([hashValue, hashValue]);
            }
            
            for (uint256 j = 0; j < two_power_i; j++) {
                hs[hsIx] = hashValue;
                hsIx++;
            }
        }
        return hs;
    }

    function combineTrees(uint256[] memory left, uint256[] memory right)
        private 
        pure
        returns (uint256[] memory)
    {
        assert(left.length == right.length);

        uint256[] memory hs = new uint256[](left.length + right.length + 1);

        uint256 log_2_n = log2(left.length + 1);
        uint256 shift = 0;
        uint256 leftIx = 0;
        uint256 rightIx = 0;
        for (uint256 depth = log_2_n; 0 < depth; depth--) {
            
            uint256 D1  = 2 ** (depth - 1);
            uint256 D2  = D1 << 1;

            for (uint256 i = 0; i < D1; i++) {
                hs[i + shift] = left[leftIx];
                leftIx++;
            }
            for (uint256 i = D1; i < D2; i++) {
                hs[i + shift] = right[rightIx];
                rightIx++;
            }

            shift += D2;
        }

        // new root
        hs[hs.length - 1] = PoseidonT3.poseidon([hs[hs.length - 3], hs[hs.length - 2]]);

        return hs;
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree

        uint256[] memory newRightTree = treeWithSameLeaves(hashedLeaf, index);
        hashes = combineTrees(hashes, newRightTree);
        index += index;
        root = hashes[hashes.length - 1];

        return root;
    }

    function verify(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool) {
        // [assignment] verify an inclusion proof and check that the proof root matches current root
        return verifyProof(a, b, c, input);
    }
}
