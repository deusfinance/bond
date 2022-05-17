// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

interface IEscapeBond {
    function getEscapeAmount(uint256 bondId, address nft) external view returns (uint256);
}
