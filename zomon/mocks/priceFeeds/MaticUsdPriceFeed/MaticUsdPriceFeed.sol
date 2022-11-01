// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MaticUsdPriceFeed is AggregatorV3Interface {
    int256 public constant HARDCODED_PRICE = 50000000; // 0.5 USD

    function decimals() external pure override returns (uint8) {
        return 8;
    }

    function description() external pure override returns (string memory) {
        return "Mock MATIC / USD price feed";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            _roundId,
            HARDCODED_PRICE,
            block.timestamp,
            block.timestamp,
            _roundId
        );
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, HARDCODED_PRICE, block.timestamp, block.timestamp, 0);
    }
}
