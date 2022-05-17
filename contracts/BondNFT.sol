// Be name Khoda
// Bime Abolfazl
// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ========================= Bond NFT =========================
// =============================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Kazem gh: https://github.com/kazemghareghani

// Auditor(s)

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BondNFT is AccessControl, ERC721Enumerable {
    /// @dev Mapping of interface id to bool about whether or not it's supported
    mapping(bytes4 => bool) internal supportedInterfaces;

    /// @dev ERC165 interface ID of ERC165
    bytes4 internal constant ERC165_INTERFACE_ID = 0x01ffc9a7;

    /// @dev ERC165 interface ID of ERC721
    bytes4 internal constant ERC721_INTERFACE_ID = 0x80ac58cd;

    /// @dev ERC165 interface ID of ERC721Metadata
    bytes4 internal constant ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SET_BOUND_ROLE = keccak256("SET_BOUND_ROLE");

    mapping(uint256 => address) public bondContract;

    /* ========== CONSTRUCTOR ========== */
    constructor(address admin) ERC721("DeiBonds", "DBND") {
        supportedInterfaces[ERC165_INTERFACE_ID] = true;
        supportedInterfaces[ERC721_INTERFACE_ID] = true;
        supportedInterfaces[ERC721_METADATA_INTERFACE_ID] = true;

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @dev Interface identification is specified in ERC-165.
    /// @param _interfaceID Id of the interface
    function supportsInterface(bytes4 _interfaceID)
        public
        view
        override(AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return supportedInterfaces[_interfaceID];
    }

    function mint(address user, address bondContract_)
        public
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        uint256 supply = totalSupply();
        bondContract[supply] = bondContract_;
        _safeMint(user, supply);
        return supply;
    }

    function changeTokenBond(uint256 tokenId, address bondContract_)
        public
        onlyRole(SET_BOUND_ROLE)
    {
        bondContract[tokenId] = bondContract_;
    }

    function tokensOf(address owner) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokensOfOwner = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokensOfOwner[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensOfOwner;
    }
}

// Dar panahe Khoda
