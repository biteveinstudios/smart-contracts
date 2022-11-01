// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChainlinkPriceFeedCallerOwnable is Ownable {
    AggregatorV3Interface internal _priceFeed;

    constructor(address _priceFeedAddress) {
        setPriceFeed(_priceFeedAddress);
    }

    function setPriceFeed(address _priceFeedAddress) public onlyOwner {
        _priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function _getLatestPrice(uint8 _decimals) internal view returns (uint256) {
        (, int256 price, , , ) = _priceFeed.latestRoundData();

        if (price <= 0) {
            return 0;
        }

        return _scalePrice(uint256(price), _priceFeed.decimals(), _decimals);
    }

    function _scalePrice(
        uint256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) private pure returns (uint256) {
        if (_priceDecimals < _decimals) {
            return _price * (10**(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / (10**(_priceDecimals - _decimals));
        }
        return _price;
    }
}
