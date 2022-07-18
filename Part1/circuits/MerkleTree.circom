pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves

    // hash component array
    component hash[2**n-1];

    if (n == 0) { // handle trivial case
        root <== leaves[0];
    }
    else {
        
        // use 1-dim array nl for all hashes
        var N = 2**(n+1)-1;
        var nl[N];
        // init nl with leaves
        for(var i = 0; i < 2**n; i++) {
            nl[i] = leaves[i];
        }

        // calc hash of upper level
        var l = 0;
        var r = 1;
        var ix = 2**n;
        var hash_ix = 0;
        for(var d = n-1; d >= 0; d--) { // per level of tree
            for(var i = 0; i < 2**d; i++) {
                // new hash component
                hash[hash_ix] = Poseidon(2);
                hash[hash_ix].inputs[0] <== nl[l];
                hash[hash_ix].inputs[1] <== nl[r];
                nl[ix] = hash[hash_ix].out;

                // move indices
                l += 2;
                r += 2;
                ix++;
                hash_ix++;
            }
        }

        root <== nl[N-1];
    }
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path

    component poseidon[n];

    var hash = leaf;

    for (var i = 0; i < n; i++) {
        poseidon[i] = Poseidon(2);
        poseidon[i].inputs[0] <== (path_elements[i] - hash)*path_index[i] + hash;
        poseidon[i].inputs[1] <== (hash - path_elements[i])*path_index[i] + path_elements[i];
        hash = poseidon[i].out;
    }

    root <== hash;
}