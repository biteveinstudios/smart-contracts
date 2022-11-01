// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/BALL/IBall.sol";
import "../../tokens/BALL/IBallStruct.sol";
import "../../tokens/TICKET/ITicket.sol";

import "../../state/Editions/IEditions.sol";

import "../../common/BallContractCallerOwnable/BallContractCallerOwnable.sol";
import "../../common/TicketContractCallerOwnable/TicketContractCallerOwnable.sol";
import "../../common/GoldContractCallerOwnable/GoldContractCallerOwnable.sol";
import "../../common/EditionsContractCallerOwnable/EditionsContractCallerOwnable.sol";
import "../../common/ChainlinkPriceFeedCallerOwnable/ChainlinkPriceFeedCallerOwnable.sol";

import "../../oracles/BallBuyOracle/BallBuyOracleCaller.sol";

contract Machine is
    BallContractCallerOwnable,
    TicketContractCallerOwnable,
    GoldContractCallerOwnable,
    EditionsContractCallerOwnable,
    BallBuyOracleCaller,
    ChainlinkPriceFeedCallerOwnable
{
    bool public constant IS_MACHINE_CONTRACT = true;

    uint16 public machineServerId;

    bool public isOpen;
    bool public isTicketOpen;

    /// @dev - 18 decimals USD amount
    uint256 private _singleItemPrice;
    uint256 private _packItemPrice;

    /// @dev - 18 decimals GOLD amount
    uint256 public singleItemGoldPrice;
    uint256 public packItemGoldPrice;

    event MachineServerIdUpdated(
        uint16 previousMachineServerId,
        uint16 machineServerId
    );
    event IsOpenUpdated(bool previousIsOpen, bool isOpen);
    event IsTicketOpenUpdated(bool previousIsTicketOpen, bool isTicketOpen);
    event SingleItemPriceUpdated(
        uint256 previousSingleItemPrice,
        uint256 singleItemPrice
    );
    event PackItemPriceUpdated(
        uint256 previousPackItemPrice,
        uint256 packItemPrice
    );
    event SingleItemGoldPriceUpdated(
        uint256 previousSingleItemGoldPrice,
        uint256 singleItemGoldPrice
    );
    event PackItemGoldPriceUpdated(
        uint256 previousPackItemGoldPrice,
        uint256 packItemGoldPrice
    );
    event SingleItemBought(address indexed buyer, uint256 price);
    event PackItemBought(address indexed buyer, uint256 price);
    event SingleItemGoldBought(address indexed buyer, uint256 price);
    event PackItemGoldBought(address indexed buyer, uint256 price);
    event TicketRedeemed(
        address indexed redeemer,
        uint256 indexed ticketTokenId
    );

    struct InitialPrices {
        uint256 singleItemPrice;
        uint256 packItemPrice;
        uint256 singleItemGoldPrice;
        uint256 packItemGoldPrice;
    }

    constructor(
        uint16 _machineServerId,
        bool _isOpen,
        bool _isTicketOpen,
        InitialPrices memory _initialPrices,
        address _ballContractAddress,
        address _ticketContractAddress,
        address _goldContractAddress,
        address _editionsContractAddress,
        address _ballBuyOracleContractAddress,
        address _chainlinkMaticUsdPriceFeedAddress
    )
        BallContractCallerOwnable(_ballContractAddress)
        TicketContractCallerOwnable(_ticketContractAddress)
        GoldContractCallerOwnable(_goldContractAddress)
        EditionsContractCallerOwnable(_editionsContractAddress)
        BallBuyOracleCaller(_ballBuyOracleContractAddress)
        ChainlinkPriceFeedCallerOwnable(_chainlinkMaticUsdPriceFeedAddress)
    {
        setMachineServerId(_machineServerId);
        setIsOpen(_isOpen);
        setIsTicketOpen(_isTicketOpen);
        setSingleItemPrice(_initialPrices.singleItemPrice);
        setPackItemPrice(_initialPrices.packItemPrice);
        setSingleItemGoldPrice(_initialPrices.singleItemGoldPrice);
        setPackItemGoldPrice(_initialPrices.packItemGoldPrice);
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

    function setIsTicketOpen(bool _newIsTicketOpen) public onlyOwner {
        emit IsTicketOpenUpdated(isTicketOpen, _newIsTicketOpen);
        isTicketOpen = _newIsTicketOpen;
    }

    function setSingleItemPrice(uint256 _newSingleItemPrice) public onlyOwner {
        emit SingleItemPriceUpdated(_singleItemPrice, _newSingleItemPrice);
        _singleItemPrice = _newSingleItemPrice;
    }

    function setPackItemPrice(uint256 _newPackItemPrice) public onlyOwner {
        emit PackItemPriceUpdated(_packItemPrice, _newPackItemPrice);
        _packItemPrice = _newPackItemPrice;
    }

    function setSingleItemGoldPrice(uint256 _newSingleItemGoldPrice)
        public
        onlyOwner
    {
        emit SingleItemGoldPriceUpdated(
            singleItemGoldPrice,
            _newSingleItemGoldPrice
        );
        singleItemGoldPrice = _newSingleItemGoldPrice;
    }

    function setPackItemGoldPrice(uint256 _newPackItemGoldPrice)
        public
        onlyOwner
    {
        emit PackItemGoldPriceUpdated(packItemGoldPrice, _newPackItemGoldPrice);
        packItemGoldPrice = _newPackItemGoldPrice;
    }

    /* Getters */
    function singleItemPrice() public view returns (uint256) {
        return (_singleItemPrice * 10**18) / _getLatestPrice(18);
    }

    function packItemPrice() public view returns (uint256) {
        return (_packItemPrice * 10**18) / _getLatestPrice(18);
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

    function _buySingle(address _to) private {
        require(isOpen, "MACHINE_IS_NOT_OPEN");

        _callBallBuyOracle(_to, machineServerId, 1, 0, false);
    }

    function _buyPack(address _to) private {
        require(isOpen, "MACHINE_IS_NOT_OPEN");

        _callBallBuyOracle(_to, machineServerId, 5, 0, false);
    }

    function _redeemTicket(address _to, uint256 _ticketTokenId) private {
        require(isTicketOpen, "TICKET_MACHINE_IS_NOT_OPEN");

        _callBallBuyOracle(_to, machineServerId, 1, _ticketTokenId, false);
    }

    function _buySingleGold(address _to) private {
        require(isOpen, "MACHINE_IS_NOT_OPEN");

        _callBallBuyOracle(_to, machineServerId, 1, 0, true);
    }

    function _buyPackGold(address _to) private {
        require(isOpen, "MACHINE_IS_NOT_OPEN");

        _callBallBuyOracle(_to, machineServerId, 5, 0, true);
    }

    /* Entry points */
    function buySingle() external payable {
        uint256 price = singleItemPrice();

        require(msg.value >= price, "VALUE_TOO_LOW");

        uint256 leftovers = msg.value - price;

        if (leftovers > 0) {
            (bool success, ) = _msgSender().call{value: leftovers}("");
            require(success, "LEFTOVERS_REFUND_FAILED");
        }

        emit SingleItemBought(_msgSender(), price);

        _buySingle(_msgSender());
    }

    function buyPack() external payable {
        uint256 price = packItemPrice();

        require(msg.value >= price, "VALUE_TOO_LOW");

        uint256 leftovers = msg.value - price;

        if (leftovers > 0) {
            (bool success, ) = _msgSender().call{value: leftovers}("");
            require(success, "LEFTOVERS_REFUND_FAILED");
        }

        emit PackItemBought(_msgSender(), price);

        _buyPack(_msgSender());
    }

    function buySingleGold() external {
        require(
            goldContract.balanceOf(_msgSender()) >= singleItemGoldPrice,
            "NOT_ENOUGH_GOLD"
        );

        goldContract.burnFrom(_msgSender(), singleItemGoldPrice);

        emit SingleItemGoldBought(_msgSender(), singleItemGoldPrice);

        _buySingleGold(_msgSender());
    }

    function buyPackGold() external {
        require(
            goldContract.balanceOf(_msgSender()) >= packItemGoldPrice,
            "NOT_ENOUGH_GOLD"
        );

        goldContract.burnFrom(_msgSender(), packItemGoldPrice);

        emit PackItemGoldBought(_msgSender(), packItemGoldPrice);

        _buyPackGold(_msgSender());
    }

    function redeemTicket(uint256 _ticketTokenId) external {
        Ticket memory ticket = ticketContract.getTicket(_ticketTokenId);

        require(
            ticket.redeemContractAddress == address(this),
            "TICKET_IS_NOT_FOR_THIS_CONTRACT"
        );

        require(
            ticket.expirationDate == 0 ||
                ticket.expirationDate >= block.timestamp,
            "TICKET_IS_EXPIRED"
        );

        require(
            ticketContract.ownerOf(_ticketTokenId) == _msgSender(),
            "ONLY_TICKET_OWNER_ALLOWED"
        );

        require(
            ticketContract.getApproved(_ticketTokenId) == address(this),
            "TICKET_NOT_APPROVED"
        );

        emit TicketRedeemed(_msgSender(), _ticketTokenId);

        _redeemTicket(_msgSender(), _ticketTokenId);
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

        // Burn ticket if any
        if (_ticketTokenId > 0) {
            ticketContract.burn(_ticketTokenId);
        }

        // Mint Balls
        for (uint256 i = 0; i < _ballsMintData.length; i++) {
            _mintBall(_to, _ballTokenURIPrefix, _ballsMintData[i]);
        }
    }
}
