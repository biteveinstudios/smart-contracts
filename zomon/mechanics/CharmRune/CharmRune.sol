// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/RUNE/IRune.sol";
import "../../tokens/RUNE/IRuneStruct.sol";

import "../../common/FundsManagementOwnable/FundsManagementOwnable.sol";
import "../../common/RuneContractCallerOwnable/RuneContractCallerOwnable.sol";
import "../../common/ChainlinkPriceFeedCallerOwnable/ChainlinkPriceFeedCallerOwnable.sol";

contract CharmRune is
    FundsManagementOwnable,
    RuneContractCallerOwnable,
    ChainlinkPriceFeedCallerOwnable
{
    /// @dev - 18 decimals USD amount
    uint256 private _batchedCharmPrice;
    uint256 private _batchedSuperCharmPrice;

    event BatchedCharmPriceUpdate(
        uint256 previousBatchedCharmPrice,
        uint256 batchedCharmPrice
    );
    event BatchedSuperCharmPriceUpdated(
        uint256 previousBatchedSuperCharmPrice,
        uint256 batchedSuperCharmPrice
    );

    event CharmedTwice(
        address indexed buyer,
        uint256 indexed runeServerId,
        uint256 price
    );
    event CharmedThreeTimes(
        address indexed buyer,
        uint256 indexed runeServerId,
        uint256 price
    );

    constructor(
        address _runeContractAddress,
        address _chainlinkMaticUsdPriceFeedAddress,
        uint256 _initialBatchedCharmPrice,
        uint256 _initialBatchedSuperCharmPrice
    )
        RuneContractCallerOwnable(_runeContractAddress)
        ChainlinkPriceFeedCallerOwnable(_chainlinkMaticUsdPriceFeedAddress)
    {
        setBatchedCharmPrice(_initialBatchedCharmPrice);
        setBatchedSuperCharmPrice(_initialBatchedSuperCharmPrice);
    }

    function setBatchedCharmPrice(uint256 _newBatchedCharmPrice)
        public
        onlyOwner
    {
        emit BatchedCharmPriceUpdate(_batchedCharmPrice, _newBatchedCharmPrice);
        _batchedCharmPrice = _newBatchedCharmPrice;
    }

    function setBatchedSuperCharmPrice(uint256 _newBatchedSuperCharmPrice)
        public
        onlyOwner
    {
        emit BatchedSuperCharmPriceUpdated(
            _batchedSuperCharmPrice,
            _newBatchedSuperCharmPrice
        );
        _batchedSuperCharmPrice = _newBatchedSuperCharmPrice;
    }

    function batchedCharmPrice() public view returns (uint256) {
        return (_batchedCharmPrice * 10**18) / _getLatestPrice(18);
    }

    function batchedSuperCharmPrice() public view returns (uint256) {
        return (_batchedSuperCharmPrice * 10**18) / _getLatestPrice(18);
    }

    function charm(uint256 _runeServerId) external {
        Rune memory rune = runeContract.getRune(_runeServerId);

        require(rune.charmedRuneServerId > 0, "RUNE_CANNOT_BE_CHARMED");

        require(
            runeContract.balanceOf(_msgSender(), _runeServerId) >=
                rune.runesCountToCharm,
            "NOT_ENOUGH_RUNES"
        );

        runeContract.burn(_msgSender(), _runeServerId, rune.runesCountToCharm);

        runeContract.mint(_msgSender(), rune.charmedRuneServerId, 1, "");
    }

    function charmTwice(uint256 _runeServerId) external payable {
        Rune memory rune = runeContract.getRune(_runeServerId);

        require(rune.charmedRuneServerId > 0, "RUNE_CANNOT_BE_CHARMED");

        Rune memory charmedRune = runeContract.getRune(
            rune.charmedRuneServerId
        );

        require(
            charmedRune.charmedRuneServerId > 0,
            "RUNE_CANNOT_BE_CHARMED_TWICE"
        );

        Rune memory charmedTwiceRune = runeContract.getRune(
            charmedRune.charmedRuneServerId
        );

        uint256 price = charmedTwiceRune.charmedRuneServerId > 0
            ? batchedCharmPrice()
            : batchedSuperCharmPrice();

        require(msg.value >= price, "VALUE_TOO_LOW");

        uint256 leftovers = msg.value - price;

        if (leftovers > 0) {
            (bool success, ) = _msgSender().call{value: leftovers}("");
            require(success, "LEFTOVERS_REFUND_FAILED");
        }

        uint256 requiredRunes = uint256(charmedRune.runesCountToCharm) *
            uint256(rune.runesCountToCharm);

        require(
            runeContract.balanceOf(_msgSender(), _runeServerId) >=
                requiredRunes,
            "NOT_ENOUGH_RUNES"
        );

        emit CharmedTwice(_msgSender(), _runeServerId, price);

        runeContract.burn(_msgSender(), _runeServerId, requiredRunes);

        runeContract.mint(_msgSender(), charmedRune.charmedRuneServerId, 1, "");
    }

    function charmThreeTimes(uint256 _runeServerId) external payable {
        Rune memory rune = runeContract.getRune(_runeServerId);

        require(rune.charmedRuneServerId > 0, "RUNE_CANNOT_BE_CHARMED");

        Rune memory charmedRune = runeContract.getRune(
            rune.charmedRuneServerId
        );

        require(
            charmedRune.charmedRuneServerId > 0,
            "RUNE_CANNOT_BE_CHARMED_TWICE"
        );

        Rune memory charmedTwiceRune = runeContract.getRune(
            charmedRune.charmedRuneServerId
        );

        require(
            charmedTwiceRune.charmedRuneServerId > 0,
            "RUNE_CANNOT_BE_CHARMED_THREE_TIMES"
        );

        uint256 price = batchedSuperCharmPrice();

        require(msg.value >= price, "VALUE_TOO_LOW");

        uint256 leftovers = msg.value - price;

        if (leftovers > 0) {
            (bool success, ) = _msgSender().call{value: leftovers}("");
            require(success, "LEFTOVERS_REFUND_FAILED");
        }

        uint256 requiredRunes = uint256(charmedTwiceRune.runesCountToCharm) *
            uint256(charmedRune.runesCountToCharm) *
            uint256(rune.runesCountToCharm);

        require(
            runeContract.balanceOf(_msgSender(), _runeServerId) >=
                requiredRunes,
            "NOT_ENOUGH_RUNES"
        );

        emit CharmedThreeTimes(_msgSender(), _runeServerId, price);

        runeContract.burn(_msgSender(), _runeServerId, requiredRunes);

        runeContract.mint(
            _msgSender(),
            charmedTwiceRune.charmedRuneServerId,
            1,
            ""
        );
    }
}
