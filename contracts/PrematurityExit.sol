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
import "./interfaces/IPrematurityExit.sol";

contract PrematurityExit is AccessControl, IPrematurityExit {
    /* ========== ROLES ========== */
    bytes32 public constant TRSUTY_ROLE = keccak256("TRSUTY_ROLE");

    constructor(address admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function getPrematurityAmount(uint256 bondId, address nft)
        external
        view
        returns (uint256)
    {
        revert();
    }
}
