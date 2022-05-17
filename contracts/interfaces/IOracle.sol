// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;
import "./IMuonV02.sol";

interface IOracle {
    struct Signature {
        uint256 price;
        uint256 timestamp;
        bytes reqId;
        SchnorrSign[] sigs;
    }

    event SetMuon(address oldValue, address newValue);
    event SetMinimumRequiredSignatures(uint256 oldValue, uint256 newValue);
    event SetValiTime(uint256 oldValue, uint256 newValue);
    event SetAppId(uint32 oldValue, uint32 newValue);
    event SetValidEpoch(uint256 oldValue, uint256 newValue);

    function getPrice() external view returns (uint256);
}