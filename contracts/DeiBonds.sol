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
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IApy.sol";
import "./interfaces/IPrematurityExit.sol";
import "./interfaces/IDeiBonds.sol";
import "./BondNFT.sol";

contract DeiBonds is IDeiBonds, AccessControlEnumerable, Pausable {
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
    uint256 public soldBond;
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
    ) {
        deus = deus_;
        exitToken = exitToken_;
        entryToken = entryToken_;
        nft = nft_;
        apyCalculator = apyCalculator_;
        preMaturityExitCalculator = preMaturityExitCalculator;
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

    function setCap(uint256 cap) public onlyRole(TRUSTY_ROLE) {
        emit SetCap(capacity, cap);
        capacity = cap;
    }

    function setSoldBond(uint256 soldBond_) public onlyRole(TRUSTY_ROLE) {
        emit SetSoldBond(soldBond, soldBond_);
        soldBond = soldBond_;
    }

    function setOracle(address oracle_) public onlyRole(TRUSTY_ROLE) {
        emit SetOracle(oracle, oracle_);
        oracle = oracle_;
    }

    function setNFT(address nft_) public onlyRole(TRUSTY_ROLE) {
        emit SetNft(nft, nft_);
        nft = nft_;
    }

    function setApyCalculator(address apyCalculator_)
        public
        onlyRole(TRUSTY_ROLE)
    {
        emit SetApyCalculator(apyCalculator, apyCalculator_);
        apyCalculator = apyCalculator_;
    }

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

    function claim(uint256 bondId) external whenNotPaused {
        address owner = BondNFT(nft).ownerOf(bondId);
        require(owner == msg.sender, "DeiBond: SENDER IS NOT BOND OWNER");
        require(
            BondNFT(nft).bondContract(bondId) == address(this),
            "DeiBond: NFT IS NOT SUPPORTED"
        );
        uint256 deusPrice = IOracle(oracle).getPrice();
        uint256 deusAmount = claimableDeus(bondId, deusPrice);
        require(deusAmount > 0, "DeiBond: CLAIM AMOUNT IS ZERO");
        bonds[bondId].lastClaimTimestamp = block.timestamp;
        IERC20(deus).safeTransfer(msg.sender, deusAmount);
        emit Claim(bondId, deusAmount);
    }

    function buyBond(uint256 amount, uint256 minApy) external whenNotPaused {
        require(amount + soldBond <= capacity, "DeiBond: THERE IS NO CAP");
        require(
            minApy <= IApy(apyCalculator).getApy(),
            "DeiBond: INSUFFICIENT APY"
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
        soldBond += amount;
        bonds[id] = bond;
        emit BuyBond(id);
    }

    function prematureWithdraw(uint256 bondId) external whenNotPaused {
        address owner = BondNFT(nft).ownerOf(bondId);
        require(owner == msg.sender, "DeiBond: SENDER IS NOT BOND OWNER");
        require(
            BondNFT(nft).bondContract(bondId) == address(this),
            "DeiBond: NFT NOT SUPPORTED"
        );
        Bond memory bond = bonds[bondId];
        require(
            bond.duration + bond.startTime > block.timestamp,
            "DeiBond: BOND IS EXPIRED"
        );
        soldBond -= bond.amount;
        bonds[bondId].amount = 0;
        uint256 escapeAmount = IPrematurityExit(preMaturityExitCalculator)
            .getPrematurityAmount(bondId, nft);
        IERC20(entryToken).safeTransfer(msg.sender, escapeAmount);
        emit PrematureWithdraw(bondId);
    }

    function maturityExit(uint256 bondId) external whenNotPaused {
        address owner = BondNFT(nft).ownerOf(bondId);
        require(owner == msg.sender, "DeiBond: SENDER IS NOT BOND OWNER");
        require(
            BondNFT(nft).bondContract(bondId) == address(this),
            "DeiBond: NFT NOT SUPPORTED"
        );
        Bond memory bond = bonds[bondId];
        require(
            bond.duration + bond.startTime < block.timestamp,
            "DeiBond: BOND IS NOT EXPIRED"
        );
        uint256 deusPrice = IOracle(oracle).getPrice();
        uint256 deusAmount = claimableDeus(bondId, deusPrice);
        require(deusAmount == 0, "DeiBond: DID NOT CLAIM YET");
        uint256 bondAmount = bond.amount;
        soldBond -= bondAmount;
        bonds[bondId].amount = 0;
        uint256 exitTokenAmount;
        if (
            IERC20Metadata(entryToken).decimals() <
            IERC20Metadata(exitToken).decimals()
        ) {
            uint256 pow = IERC20Metadata(exitToken).decimals() -
                IERC20Metadata(entryToken).decimals();
            exitTokenAmount = bondAmount * 10**pow;
        } else {
            uint256 pow = IERC20Metadata(entryToken).decimals() -
                IERC20Metadata(exitToken).decimals();
            exitTokenAmount = bondAmount / 10**pow;
        }
        IERC20(exitToken).safeTransfer(msg.sender, exitTokenAmount);
        emit MaturityExitBond(bondId);
    }

    /* ========== VIEWS ========== */

    function bondsOfOwner(address user)
        external
        view
        returns (Bond[] memory, uint256[] memory)
    {
        uint256[] memory tokens = BondNFT(nft).tokensOf(user);
        Bond[] memory bondsOfUser = new Bond[](tokens.length);
        uint256 j = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (BondNFT(nft).bondContract(tokens[i]) == address(this)) {
                bondsOfUser[j++] = bonds[tokens[i]];
            }
        }
        return (bondsOfUser, tokens);
    }

    function getApy() external view returns (uint256 apyValue) {
        apyValue = IApy(apyCalculator).getApy();
    }

    function claimableDeus(uint256 bondId, uint256 deusPrice)
        public
        view
        returns (uint256 deusAmount)
    {
        Bond memory bond = bonds[bondId];
        uint256 currentTimestamp;
        uint256 endTimestamp = bond.startTime + bond.duration;
        if (block.timestamp > endTimestamp) {
            currentTimestamp = endTimestamp;
        } else {
            currentTimestamp = block.timestamp;
        }
        uint256 numberOfClaims = (currentTimestamp - bond.startTime) /
            claimInterval -
            (bond.lastClaimTimestamp - bond.startTime) /
            claimInterval;
        uint256 totalClaims = bond.duration / claimInterval;
        uint256 claimableDeusValue = (bond.amount * numberOfClaims * bond.apy) /
            (totalClaims * 1e18);
        deusAmount =
            (claimableDeusValue *
                (10**(18 - IERC20Metadata(entryToken).decimals())) *
                1e18) /
            deusPrice;
    }
}

// Dar panahe Khoda
