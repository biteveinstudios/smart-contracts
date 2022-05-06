// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../interfaces/IBall.sol";
import "../interfaces/IBallStruct.sol";
import "../interfaces/IEditions.sol";
import "../interfaces/ITicket.sol";

import "../oracles/BallBuyOracleCaller.sol";

contract GAO is BallBuyOracleCaller {
    bool public constant IS_GAO_CONTRACT = true;

    uint16 machineServerId;

    bool public isOpen;

    IEditions public editionsContract;
    IBall public ballContract;
    ITicket public ticketContract;

    uint256 public singleItemPrice;
    uint256 public packItemPrice;

    event MachineServerIdUpdated(uint256 machineServerId);
    event SingleItemPriceUpdated(uint256 singleItemPrice);
    event PackItemPriceUpdated(uint256 packItemPrice);
    event SingleItemBought(address indexed buyer, uint256 price);
    event PackItemBought(address indexed buyer, uint256 price);
    event TicketRedeemed(uint256 indexed ticketTokenId);

    constructor(
        uint16 _machineServerId,
        bool _isOpen,
        address _editionsContractAddress,
        address _ballContractAddress,
        address _ticketContractAddress,
        uint256 _singleItemPrice,
        uint256 _packItemPrice,
        address _ballBuyOracleContractAddress
    ) BallBuyOracleCaller(_ballBuyOracleContractAddress) {
        setMachineServerId(_machineServerId);
        setIsOpen(_isOpen);
        setEditionsContractAddress(_editionsContractAddress);
        setBallContract(_ballContractAddress);
        setTicketContract(_ticketContractAddress);
        setSingleItemPrice(_singleItemPrice);
        setPackItemPrice(_packItemPrice);
    }

    /* Parameters management */
    function setMachineServerId(uint16 _machineServerId) public onlyOwner {
        machineServerId = _machineServerId;
        emit MachineServerIdUpdated(_machineServerId);
    }

    function setIsOpen(bool _isOpen) public onlyOwner {
        isOpen = _isOpen;
    }

    function setEditionsContractAddress(address _address) public onlyOwner {
        IEditions candidateContract = IEditions(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.IS_EDITIONS_CONTRACT(),
            "CONTRACT_ADDRES_IS_NOT_AN_EDITIONS_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        editionsContract = candidateContract;
    }

    function setBallContract(address _address) public onlyOwner {
        IBall candidateContract = IBall(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.IS_BALL_CONTRACT(),
            "CONTRACT_ADDRES_IS_NOT_A_BALL_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        ballContract = candidateContract;
    }

    function setTicketContract(address _address) public onlyOwner {
        ITicket candidateContract = ITicket(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.IS_TICKET_CONTRACT(),
            "CONTRACT_ADDRES_IS_NOT_A_TICKET_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        ticketContract = candidateContract;
    }

    function setSingleItemPrice(uint256 _singleItemPrice) public onlyOwner {
        singleItemPrice = _singleItemPrice;
        emit SingleItemPriceUpdated(_singleItemPrice);
    }

    function setPackItemPrice(uint256 _packItemPrice) public onlyOwner {
        packItemPrice = _packItemPrice;
        emit PackItemPriceUpdated(_packItemPrice);
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
        require(isOpen, "SALE_IS_NOT_OPEN");

        emit SingleItemBought(_to, singleItemPrice);

        _callBallBuyOracle(_to, machineServerId, 1, 0);
    }

    function _buyPack(address _to) private {
        require(isOpen, "SALE_IS_NOT_OPEN");

        emit PackItemBought(_to, packItemPrice);

        _callBallBuyOracle(_to, machineServerId, 5, 0);
    }

    /* Entry points */
    function buySingle() external payable {
        require(msg.value == singleItemPrice, "VALUE_INCORRECT");

        _buySingle(_msgSender());
    }

    function buyPack() external payable {
        require(msg.value == packItemPrice, "VALUE_INCORRECT");

        _buyPack(_msgSender());
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

        _callBallBuyOracle(_msgSender(), machineServerId, 1, _ticketTokenId);
    }

    // Oracle callback
    function callback(
        uint256 _requestId,
        address _to,
        string calldata _ballTokenURIPrefix,
        BallMintData[] calldata _ballsMintData,
        uint256 _ticketTokenId
    ) external override nonReentrant {
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

        // Burn ticket if any
        if (_ticketTokenId > 0) {
            emit TicketRedeemed(_ticketTokenId);
            ticketContract.burn(_ticketTokenId);
        }
    }
}
