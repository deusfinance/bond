// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

interface IPrematurityExit {
    function getPrematurityAmount(uint256 bondId, address nft)
        external
        view
        returns (uint256);
}
