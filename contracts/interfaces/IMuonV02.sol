// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}

interface IMuonV02 {
    function verify(
        bytes calldata reqId,
        uint256 hash,
        SchnorrSign[] calldata _sigs
    ) external returns (bool);
}