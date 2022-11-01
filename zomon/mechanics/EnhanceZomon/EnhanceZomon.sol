// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/ZOMON/IZomonStruct.sol";

import "../../common/ZomonContractCallerOwnable/ZomonContractCallerOwnable.sol";
import "../../common/ChainlinkPriceFeedCallerOwnable/ChainlinkPriceFeedCallerOwnable.sol";

import "../../oracles/EnhanceZomonOracle/EnhanceZomonOracleCaller.sol";

contract EnhanceZomon is
    ZomonContractCallerOwnable,
    EnhanceZomonOracleCaller,
    ChainlinkPriceFeedCallerOwnable
{
    /// @dev - target level => current level => 18 decimals USD amount
    mapping(uint256 => mapping(uint256 => uint256))
        private _enhancePremiumDollarsPrices;

    struct EnhancePremiumDollarsPrice {
        uint256 targetLevel;
        uint256 currentLevel;
        uint256 dollarsPrice; // 18 decimals USD amount
    }

    constructor(
        EnhancePremiumDollarsPrice[] memory _initialEnhancePremiumDollarsPrice,
        address _zomonContractAddress,
        address _enhanceZomonOracleContractAddress,
        address _chainlinkMaticUsdPriceFeedAddress
    )
        ZomonContractCallerOwnable(_zomonContractAddress)
        EnhanceZomonOracleCaller(_enhanceZomonOracleContractAddress)
        ChainlinkPriceFeedCallerOwnable(_chainlinkMaticUsdPriceFeedAddress)
    {
        setEnhancePremiumDollarsPrice(_initialEnhancePremiumDollarsPrice);
    }

    function setEnhancePremiumDollarsPrice(
        EnhancePremiumDollarsPrice[] memory _newEnhancePremiumDollarsPrice
    ) public onlyOwner {
        EnhancePremiumDollarsPrice memory enhancePremiumDollarsPrice;
        for (uint256 i = 0; i < _newEnhancePremiumDollarsPrice.length; i++) {
            enhancePremiumDollarsPrice = _newEnhancePremiumDollarsPrice[i];

            require(
                enhancePremiumDollarsPrice.dollarsPrice > 0,
                "ENHANCE_PREMIUM_DOLLARS_PRICE_IS_ZERO"
            );

            _enhancePremiumDollarsPrices[
                enhancePremiumDollarsPrice.targetLevel
            ][
                enhancePremiumDollarsPrice.currentLevel
            ] = enhancePremiumDollarsPrice.dollarsPrice;
        }
    }

    function _getZomonCurrentMaxLevel(Zomon memory _zomon)
        private
        pure
        returns (uint16)
    {
        if (_zomon.level == _zomon.maxLevel) {
            return _zomon.maxLevel;
        }

        if (_zomon.level < 20) {
            return 20;
        }

        uint16 currentMaxLevel = (_zomon.evolution + 1) * 10;

        if (currentMaxLevel >= _zomon.maxLevel) {
            return _zomon.maxLevel;
        }

        return currentMaxLevel;
    }

    function getEnhancePremiumPrice(uint256 _zomonTokenId)
        public
        view
        returns (uint256)
    {
        Zomon memory zomon = zomonContract.getZomon(_zomonTokenId);

        uint16 currentMaxLevel = _getZomonCurrentMaxLevel(zomon);

        uint256 dollarsPrice = _enhancePremiumDollarsPrices[currentMaxLevel][
            zomon.level
        ];

        require(dollarsPrice > 0, "ENHANCE_PREMIUM_DOLLARS_PRICE_NOT_SET");

        return (dollarsPrice * 10**18) / _getLatestPrice(18);
    }

    function enhancePremium(uint256 _zomonTokenId) external payable {
        uint256 price = getEnhancePremiumPrice(_zomonTokenId);

        require(msg.value >= price, "VALUE_TOO_LOW");

        uint256 leftovers = msg.value - price;

        if (leftovers > 0) {
            (bool success, ) = _msgSender().call{value: leftovers}("");
            require(success, "LEFTOVERS_REFUND_FAILED");
        }

        // Check sender has Zomon
        require(
            zomonContract.ownerOf(_zomonTokenId) == _msgSender(),
            "ONLY_ZOMON_OWNER_ALLOWED"
        );

        // Check Zomon is approved
        require(
            zomonContract.getApproved(_zomonTokenId) == address(this) ||
                zomonContract.isApprovedForAll(_msgSender(), address(this)),
            "ZOMON_NOT_APPROVED"
        );

        // Check Zomon can level up
        Zomon memory zomon = zomonContract.getZomon(_zomonTokenId);
        require(zomon.canLevelUp, "ZOMON_CANNOT_LEVEL_UP");

        _callEnhancePremiumOracle(
            _msgSender(),
            _zomonTokenId,
            _getZomonCurrentMaxLevel(zomon)
        );
    }

    function enhanceCallback(
        uint256 _requestId,
        address _to,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external override nonReentrant {
        // Only oracle should be able to call
        require(
            _msgSender() == address(enhanceZomonOracleContract),
            "NOT_AUTHORIZED"
        );

        // Ensure this is a legitimate callback request
        require(
            _pendingEnhanceZomonRequests[_requestId],
            "REQUEST_ID_IS_NOT_PENDING"
        );

        // Remove the request from pending requests
        delete _pendingEnhanceZomonRequests[_requestId];

        // Burn Zomon
        zomonContract.burn(_zomonTokenId);

        // Mint Zomon
        zomonContract.mint(_to, _zomonTokenId, _zomonTokenURI, _zomonData);
    }
}
