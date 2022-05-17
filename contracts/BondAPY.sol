// Be name Khoda
// Bime Abolfazl
// SPDX-License-Identifier: MIT

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ==================== Bond APY ===================
// ==============================================
// DEUS Finance: https://github.com/deusfinance

// Primary Author(s)
// Kazem: https://github.com/kazemghareghani

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IApy.sol";

contract BondAPY is AccessControl, IApy {
    /* ========== ROLES ========== */
    bytes32 public constant TRSUTY_ROLE = keccak256("TRSUTY_ROLE");

    uint256 public apy;
    uint256 public APY_PRECISION = 1e18;

    constructor(
        address admin,
        address trusty,
        uint256 apy_
    ) {
        apy = apy_;

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(TRSUTY_ROLE, trusty);
    }

    function setApy(uint256 apy_) external onlyRole(TRSUTY_ROLE) {
        apy = apy_;
    }

    function getApy() external view returns (uint256) {
        return apy;
    }
}
