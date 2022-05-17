// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

interface IDeiBonds {
    struct Bond {
        uint256 amount;
        uint256 apy;
        uint256 duration;
        uint256 startTime;
        uint256 lastClaimTimestamp;
    }

    event SetCap(uint256 oldValue, uint256 newValue);
    event SetSoldBond(uint256 oldValue, uint256 newValue);
    event SetOracle(address oldValue, address newValue);
    event SetNft(address oldValue, address newValue);
    event SetApyCalculator(address oldValue, address newValue);
    event SetPreMaturityExitCalculator(address oldValue, address newValue);
    event SetClaimInterval(uint256 oldValue, uint256 newValue);
    event Claim(uint256 bondId, uint256 claimAmount);
    event BuyBond(uint256 bondId);
    event MaturityExitBond(uint256 bondId);
    event PrematureWithdraw(uint256 bondId);
}
