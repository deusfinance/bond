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
// ========================= Bonds =========================
// =============================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Kazem gh: https://github.com/kazemghareghani

// Auditor(s)

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IApy.sol";
import "./interfaces/IPrematurityExit.sol";
import "./interfaces/IDeiBonds.sol";
import "./BondNFT.sol";

/// @title dei bonds
/// @author Kazem Ghareghani
/// @notice user can buy dei bonds and eran rewards
contract DeiBonds is
    IDeiBonds,
    AccessControlEnumerable,
    Pausable,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    mapping(uint256 => Bond) public bonds;
    address public deus;
    address public exitToken;
    address public entryToken;
    address public nft;
    address public oracle;
    address public apyCalculator;
    address public preMaturityExitCalculator;
    uint256 public capacity;
    uint256 public soldAmount;
    uint256 public claimInterval = 12 hours;

    /* ========== ROLES ========== */
    bytes32 public constant TRUSTY_ROLE = keccak256("TRUSTY_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address admin,
        address trusty,
        address deus_,
        address exitToken_,
        address entryToken_,
        address nft_,
        address apyCalculator_,
        address preMaturityExitCalculator_,
        address oracle_,
        uint256 capacity_
    ) ReentrancyGuard() {
        deus = deus_;
        exitToken = exitToken_;
        entryToken = entryToken_;
        nft = nft_;
        apyCalculator = apyCalculator_;
        preMaturityExitCalculator = preMaturityExitCalculator_;
        oracle = oracle_;
        capacity = capacity_;

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(TRUSTY_ROLE, trusty);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function approve(address token, address to) public onlyRole(TRUSTY_ROLE) {
        IERC20(token).safeApprove(to, type(uint256).max);
    }

    function withdrawERC20(address token, uint256 amount)
        external
        onlyRole(TRUSTY_ROLE)
    {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function withdrawETH(uint256 amount) external onlyRole(TRUSTY_ROLE) {
        payable(msg.sender).transfer(amount);
    }

    /// @notice set cap
    /// @param cap new value
    function setCap(uint256 cap) external onlyRole(TRUSTY_ROLE) {
        emit SetCap(capacity, cap);
        capacity = cap;
    }

    /// @notice set sold amount
    /// @param soldAmount_ new value
    function setSoldAmount(uint256 soldAmount_) external onlyRole(TRUSTY_ROLE) {
        emit SetSoldAmount(soldAmount, soldAmount_);
        soldAmount = soldAmount_;
    }

    /// @notice set oracle
    /// @param oracle_ new value
    function setOracle(address oracle_) external onlyRole(TRUSTY_ROLE) {
        emit SetOracle(oracle, oracle_);
        oracle = oracle_;
    }

    /// @notice set NFT
    /// @param nft_ new value
    function setNFT(address nft_) public onlyRole(TRUSTY_ROLE) {
        emit SetNft(nft, nft_);
        nft = nft_;
    }

    /// @notice set Apy Calculator
    /// @param apyCalculator_ new value
    function setApyCalculator(address apyCalculator_)
        public
        onlyRole(TRUSTY_ROLE)
    {
        emit SetApyCalculator(apyCalculator, apyCalculator_);
        apyCalculator = apyCalculator_;
    }

    /// @notice set Pre Maturity Exit Calculator
    /// @param preMaturityExitCalculator_ new value
    function setPreMaturityExitCalculator(address preMaturityExitCalculator_)
        public
        onlyRole(TRUSTY_ROLE)
    {
        emit SetPreMaturityExitCalculator(
            preMaturityExitCalculator,
            preMaturityExitCalculator_
        );
        preMaturityExitCalculator = preMaturityExitCalculator_;
    }

    /// @notice Set claim interval
    /// @param claimInterval_ new value
    function setClaimInterval(uint256 claimInterval_)
        public
        onlyRole(TRUSTY_ROLE)
    {
        emit SetClaimInterval(claimInterval, claimInterval_);
        claimInterval = claimInterval_;
    }

    /// @notice pause contract
    function pause() external onlyRole(PAUSER_ROLE) {
        super._pause();
    }

    /// @notice unpause contract
    function unpause() external onlyRole(TRUSTY_ROLE) {
        super._unpause();
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    /// @notice User can claim deus as a reward
    /// @param bondId id of bond nft token
    function claim(uint256 bondId) external whenNotPaused nonReentrant {
        address owner = BondNFT(nft).ownerOf(bondId);
        require(owner == msg.sender, "DeiBond: SENDER_IS_NOT_BOND_OWNER");
        require(
            BondNFT(nft).bondContract(bondId) == address(this),
            "DeiBond: NFT_IS_NOT_SUPPORTED"
        );
        uint256 deusPrice = IOracle(oracle).getPrice();
        uint256 deusAmount = claimableDeus(bondId, deusPrice);
        require(deusAmount > 0, "DeiBond: CLAIM_AMOUNT_IS_ZERO");
        bonds[bondId].lastClaimTimestamp = block.timestamp;
        IERC20(deus).safeTransfer(msg.sender, deusAmount);
        emit Claim(msg.sender, bondId, deusAmount);
    }

    /// @notice User can buy bond with this function
    /// @param amount amount of entry token
    /// @param minApy min apy that user want
    function buyBond(uint256 amount, uint256 minApy)
        external
        whenNotPaused
        nonReentrant
    {
        require(amount + soldAmount <= capacity, "DeiBond: THERE_IS_NO_CAP");
        require(
            minApy <= IApy(apyCalculator).getApy(),
            "DeiBond: INSUFFICIENT_APY"
        );
        IERC20(entryToken).transferFrom(msg.sender, address(this), amount);
        uint256 id = BondNFT(nft).mint(msg.sender, address(this));
        Bond memory bond = Bond(
            amount,
            IApy(apyCalculator).getApy(),
            180 days,
            block.timestamp,
            block.timestamp
        );
        soldAmount += amount;
        bonds[id] = bond;
        emit BuyBond(msg.sender, amount, id);
    }

    /// @notice user can withdraw amount before bond matured
    /// @param bondId id of bond nft token
    function prematureWithdraw(uint256 bondId)
        external
        whenNotPaused
        nonReentrant
    {
        address owner = BondNFT(nft).ownerOf(bondId);
        require(owner == msg.sender, "DeiBond: SENDER_IS_NOT_BOND_OWNER");
        require(
            BondNFT(nft).bondContract(bondId) == address(this),
            "DeiBond: NFT_NOT_SUPPORTED"
        );
        Bond memory bond = bonds[bondId];
        require(
            bond.duration + bond.startTime > block.timestamp,
            "DeiBond: BOND_IS_EXPIRED"
        );
        uint256 bondAmount = bond.amount;
        soldAmount -= bondAmount;
        bonds[bondId].amount = 0;
        uint256 preMaturityAmount = IPrematurityExit(preMaturityExitCalculator)
            .getPrematurityAmount(bondId, nft);
        IERC20(entryToken).safeTransfer(msg.sender, preMaturityAmount);
        emit PrematureWithdraw(
            msg.sender,
            bondAmount,
            preMaturityAmount,
            bondId
        );
    }

    /// @notice user can exit after bond matured
    /// @param bondId id of bond nft token
    function maturityExit(uint256 bondId) external whenNotPaused nonReentrant {
        address owner = BondNFT(nft).ownerOf(bondId);
        require(owner == msg.sender, "DeiBond: SENDER_IS_NOT_BOND_OWNER");
        require(
            BondNFT(nft).bondContract(bondId) == address(this),
            "DeiBond: NFT_NOT_SUPPORTED"
        );
        Bond memory bond = bonds[bondId];
        require(
            bond.duration + bond.startTime < block.timestamp,
            "DeiBond: BOND_IS_NOT_EXPIRED"
        );
        uint256 deusPrice = IOracle(oracle).getPrice();
        uint256 deusAmount = claimableDeus(bondId, deusPrice);
        require(deusAmount == 0, "DeiBond: NOT_CLAIMED_YET");
        uint256 bondAmount = bond.amount;
        soldAmount -= bondAmount;
        bonds[bondId].amount = 0;
        uint256 exitTokenAmount;
        uint256 entryDecimal = IERC20Metadata(entryToken).decimals();
        uint256 exitDecimal = IERC20Metadata(exitToken).decimals();
        uint256 pow = entryDecimal < exitDecimal
            ? exitDecimal - entryDecimal
            : entryDecimal - exitDecimal;
        exitTokenAmount = bondAmount / 10**pow;
        IERC20(exitToken).safeTransfer(msg.sender, exitTokenAmount);
        emit MaturityExitBond(msg.sender, bondAmount, bondId);
    }

    /* ========== VIEWS ========== */

    /// @notice get list of bonds of a user
    /// @param user address of user
    /// @return bonds lsit of bonds object
    /// @return tokens lsit of nft ids
    function bondsOfOwner(address user)
        external
        view
        returns (Bond[] memory bondsOfUser, uint256[] memory tokensOfUser)
    {
        uint256[] memory tokens = BondNFT(nft).tokensOf(user);
        bondsOfUser = new Bond[](tokens.length);
        tokensOfUser = new uint256[](tokens.length);
        uint256 j = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (BondNFT(nft).bondContract(tokens[i]) == address(this)) {
                bondsOfUser[j] = bonds[tokens[i]];
                tokensOfUser[j] = tokens[i];
                j++;
            }
        }
    }

    /// @notice returns apy for bond
    /// @return apyValue apy in 18 decimals
    function getApy() external view returns (uint256 apyValue) {
        apyValue = IApy(apyCalculator).getApy();
    }

    /// @notice computes deus amount can be claimed
    /// @param bondId id of bond nft token
    /// @param deusPrice price of deus in 18 decimals
    /// @return deusAmount deus amount can be claimed
    function claimableDeus(uint256 bondId, uint256 deusPrice)
        public
        view
        returns (uint256 deusAmount)
    {
        Bond memory bond = bonds[bondId];
        uint256 endTimestamp = bond.startTime + bond.duration;
        uint256 currentTimestamp = block.timestamp > endTimestamp
            ? endTimestamp
            : block.timestamp;
        uint256 numberOfClaims = (currentTimestamp - bond.startTime) /
            claimInterval -
            (bond.lastClaimTimestamp - bond.startTime) /
            claimInterval;
        uint256 totalClaims = bond.duration / claimInterval;
        uint256 claimableDeusValue = (bond.amount *
            numberOfClaims *
            bond.apy *
            (10**(18 - IERC20Metadata(entryToken).decimals()))) /
            (totalClaims * 1e18);
        deusAmount = (claimableDeusValue * 1e18) / deusPrice;
    }
}

// Dar panahe Khoda
