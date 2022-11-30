// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/BALL/IBall.sol";
import "../../tokens/BALL/IBallStruct.sol";

import "../../state/Editions/IEditions.sol";

import "../../common/BallContractCallerOwnable/BallContractCallerOwnable.sol";
import "../../common/EditionsContractCallerOwnable/EditionsContractCallerOwnable.sol";
import "../../common/ChainlinkPriceFeedCallerOwnable/ChainlinkPriceFeedCallerOwnable.sol";

import "../../oracles/BallBuyOracle/BallBuyOracleCaller.sol";

contract ReleaseMachine is
    BallContractCallerOwnable,
    EditionsContractCallerOwnable,
    BallBuyOracleCaller,
    ChainlinkPriceFeedCallerOwnable
{
    bool public constant IS_RELEASE_MACHINE_CONTRACT = true;

    uint16 public machineServerId;

    bool public isOpen;

    /// @dev - 18 decimals USD amount
    uint256 private _releasePackItemPrice;

    event MachineServerIdUpdated(
        uint16 previousMachineServerId,
        uint16 machineServerId
    );
    event IsOpenUpdated(bool previousIsOpen, bool isOpen);
    event ReleasePackItemPriceUpdated(
        uint256 previousReleasePackItemPrice,
        uint256 releasePackItemPrice
    );
    event ReleasePackItemBought(address indexed buyer, uint256 price);

    constructor(
        uint16 _machineServerId,
        bool _isOpen,
        uint256 _initialReleasePackItemPrice,
        address _ballContractAddress,
        address _editionsContractAddress,
        address _ballBuyOracleContractAddress,
        address _chainlinkMaticUsdPriceFeedAddress
    )
        BallContractCallerOwnable(_ballContractAddress)
        EditionsContractCallerOwnable(_editionsContractAddress)
        BallBuyOracleCaller(_ballBuyOracleContractAddress)
        ChainlinkPriceFeedCallerOwnable(_chainlinkMaticUsdPriceFeedAddress)
    {
        setMachineServerId(_machineServerId);
        setIsOpen(_isOpen);
        setReleasePackItemPrice(_initialReleasePackItemPrice);
    }

    /* Parameters management */
    function setMachineServerId(uint16 _newMachineServerId) public onlyOwner {
        emit MachineServerIdUpdated(machineServerId, _newMachineServerId);
        machineServerId = _newMachineServerId;
    }

    function setIsOpen(bool _newIsOpen) public onlyOwner {
        emit IsOpenUpdated(isOpen, _newIsOpen);
        isOpen = _newIsOpen;
    }

    function setReleasePackItemPrice(uint256 _newPackReleaseItemPrice)
        public
        onlyOwner
    {
        emit ReleasePackItemPriceUpdated(
            _releasePackItemPrice,
            _newPackReleaseItemPrice
        );
        _releasePackItemPrice = _newPackReleaseItemPrice;
    }

    /* Getters */
    function releasePackItemPrice() public view returns (uint256) {
        return (_releasePackItemPrice * 10**18) / _getLatestPrice(18);
    }

    /* Helpers */
    function _mintBall(
        address _to,
        string memory _ballTokenURIPrefix,
        BallMintData memory _ballMintData
    ) private returns (uint256) {
        Ball memory ballData = Ball(
            _ballMintData.serverId,
            _ballMintData.setId,
            editionsContract.getCurrentSetIdEdition(_ballMintData.setId),
            _ballMintData.minRunes,
            _ballMintData.maxRunes,
            _ballMintData.isShiny,
            _ballMintData.name
        );

        editionsContract.increaseCurrentSetIdEditionItemsCount(ballData.setId);

        uint256 ballTokenId = ballContract.mint(
            _to,
            _ballTokenURIPrefix,
            ballData
        );

        return ballTokenId;
    }

    function _buyReleasePack(address _to) private {
        require(isOpen, "MACHINE_IS_NOT_OPEN");

        _callBallBuyOracle(_to, machineServerId, 100, 0, false);
    }

    /* Entry points */
    function buyReleasePack() external payable {
        uint256 price = releasePackItemPrice();

        require(price > 0, "PRICE_IS_ZERO");

        require(msg.value >= price, "VALUE_TOO_LOW");

        uint256 leftovers = msg.value - price;

        if (leftovers > 0) {
            (bool success, ) = _msgSender().call{value: leftovers}("");
            require(success, "LEFTOVERS_REFUND_FAILED");
        }

        emit ReleasePackItemBought(_msgSender(), price);

        _buyReleasePack(_msgSender());
    }

    // Oracle callback
    function callback(
        uint256 _requestId,
        address _to,
        string calldata _ballTokenURIPrefix,
        BallMintData[] calldata _ballsMintData,
        uint256 _ticketTokenId,
        bool _isGoldBuy
    ) external override nonReentrant {
        _ticketTokenId; // not used
        _isGoldBuy; // not used

        // Only oracle should be able to call
        require(
            _msgSender() == address(ballBuyOracleContract),
            "NOT_AUTHORIZED"
        );

        // Ensure this is a legitimate callback request
        require(
            _pendingBallBuyRequests[_requestId],
            "REQUEST_ID_IS_NOT_PENDING"
        );

        // Remove the request from pending requests
        delete _pendingBallBuyRequests[_requestId];

        // Mint Balls
        for (uint256 i = 0; i < _ballsMintData.length; i++) {
            _mintBall(_to, _ballTokenURIPrefix, _ballsMintData[i]);
        }
    }
}
