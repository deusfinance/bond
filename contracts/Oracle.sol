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
// ==================== Oracle ===================
// ==============================================
// DEUS Finance: https://github.com/deusfinance

// Primary Author(s)
// Mmd: https://github.com/mmd-mostafaee
// Vahid: https://github.com/vahid-dev
// Kazem: https://github.com/kazemghareghani

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IMuonV02.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router02.sol";

/// @title Oracle Contract
/// @author DEUS Finance
/// @notice To verify signatures
/// @dev Using Muon contract to verify signatures
contract Oracle is AccessControl, IOracle {
    address public spookyPair;
    address public spookyV2Router;
    address public ftmUsdPriceFeed;
    address public muon; // Muon contract address
    uint32 public appId; // muon app id
    uint256 public minimumRequiredSignatures; // minimum signatures required to verify a signature
    uint256 public validEpoch; // signatures expiration time in seconds
    uint256 public onChainThreshold;
    uint256 public muonThreshold;

    uint256 private price;

    uint256 public lastPriceUpdate;

    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE"); // setter role

    constructor(
        address spookyPair_,
        address spookyV2Router_,
        address ftmUsdPriceFeed_,
        address muon_,
        uint32 appId_,
        uint256 minimumRequiredSignatures_,
        uint256 validEpoch_,
        uint256 onChainThreshold_,
        uint256 muonThreshold_,
        address admin,
        address setter
    ) {
        require(
            spookyPair_ != address(0) &&
            spookyV2Router_ != address(0) && 
            ftmUsdPriceFeed_ != address(0) &&
            muon_ != address(0) &&
            admin != address(0) &&
            setter != address(0),
            "Oracle: ZERO_ADDRESS_DETECTED"
        );

        spookyPair = spookyPair_;
        spookyV2Router = spookyV2Router_;
        ftmUsdPriceFeed = ftmUsdPriceFeed_;
        muon = muon_;
        appId = appId_;
        validEpoch = validEpoch_;
        onChainThreshold = onChainThreshold_;
        muonThreshold = muonThreshold_;

        minimumRequiredSignatures = minimumRequiredSignatures_;

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(SETTER_ROLE, setter);
    }

    /// @notice sets muon contract address
    /// @param muon_ address of the Muon contract
    function setMuon(address muon_) external onlyRole(SETTER_ROLE) {
        emit SetMuon(muon, muon_);
        muon = muon_;
    }

    /// @notice sets muon app id
    /// @param appId_ muon app id
    function setAppId(uint32 appId_) external onlyRole(SETTER_ROLE) {
        emit SetAppId(appId, appId_);
        appId = appId_;
    }

    /// @notice sets minimum signatures required to verify a signature
    /// @param minimumRequiredSignatures_ number of signatures required to verify a signature
    function setMinimumRequiredSignatures(uint256 minimumRequiredSignatures_)
        external
        onlyRole(SETTER_ROLE)
    {
        emit SetMinimumRequiredSignatures(
            minimumRequiredSignatures,
            minimumRequiredSignatures_
        );
        minimumRequiredSignatures = minimumRequiredSignatures_;
    }

    /// @notice sets signatures expiration time in seconds
    /// @param validEpoch_ signatures expiration time in seconds
    function setValidEpoch(uint256 validEpoch_) external onlyRole(SETTER_ROLE) {
        emit SetValidEpoch(validEpoch, validEpoch_);
        validEpoch = validEpoch_;
    }

    /// @notice Sets price for given collateral
    /// @param signature signature to verify
    function setPrice(Signature memory signature) external {
        require(
            signature.sigs.length >= minimumRequiredSignatures,
            "Oracle: INSUFFICIENT_SIGNATURES"
        );
        require(
            signature.timestamp + validEpoch >= block.timestamp,
            "Oracle: SIGNATURE_EXPIRED"
        );

        require(signature.timestamp > lastPriceUpdate, "ORACLE: INVALID_SIGNATURE");

        uint256 onChainPrice = getOnChainPrice();
        uint256 diff = onChainPrice < signature.price
            ? (onChainPrice * 1e18) / signature.price
            : (signature.price * 1e18) / onChainPrice;
        require(1e18 - diff < muonThreshold, "ORACLE: PRICE_GAP");

        bytes32 hash = keccak256(
            abi.encodePacked(appId, signature.price, signature.timestamp)
        );

        require(
            IMuonV02(muon).verify(
                signature.reqId,
                uint256(hash),
                signature.sigs
            ),
            "Oracle: UNVERIFIED_SIGNATURES"
        );

        price = signature.price;
        lastPriceUpdate = block.timestamp;
    }

    /// @notice returns on chain LP price
    /// @dev Only used by frontend
    function getOnChainPrice() public view returns (uint256) {
        (uint256 wftmReserve, uint256 deusReserve, ) = IUniswapV2Pair(
            spookyPair
        ).getReserves();

        (, int256 ftmPrice_, , , ) = AggregatorV3Interface(ftmUsdPriceFeed)
            .latestRoundData();

        uint256 ftmPrice = uint256(ftmPrice_);
        uint256 deusFtm = (wftmReserve * 1e18) / deusReserve;

        return ((deusFtm * ftmPrice * 1e10) / 1e18);
    }

    /// @notice Returns price
    /// @return price of collateral
    function getPrice() external view returns (uint256) {
        require(
            lastPriceUpdate + validEpoch >= block.timestamp,
            "Oracle: PRICE_EXPIRED"
        );
        require(
            lastPriceUpdate < block.timestamp,
            "Oracle: GET_PRICE_NOT_ALLOWED"
        );

        uint256 onChainPrice = getOnChainPrice();
        uint256 diff = onChainPrice < price
            ? (onChainPrice * 1e18) / price
            : (price * 1e18) / onChainPrice;
        require(1e18 - diff < onChainThreshold, "ORACLE: ONCHAIN_PRICE_GAP");

        return price;
    }
}
