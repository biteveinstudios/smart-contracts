// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../../common/FundsManagementOwnable/FundsManagementOwnable.sol";

import "../../tokens/BALL/IBallStruct.sol";

import "./IBallBuyOracle.sol";

abstract contract BallBuyOracleCaller is
    Ownable,
    ReentrancyGuard,
    FundsManagementOwnable
{
    bool public constant IS_BALL_BUY_ORACLE_CALLER = true;

    IBallBuyOracle public ballBuyOracleContract;

    mapping(uint256 => bool) internal _pendingBallBuyRequests;

    constructor(address _initialBallBuyOracleContractAddress) {
        setBallBuyOracleContractAddress(_initialBallBuyOracleContractAddress);
    }

    /* External contracts management */
    function setBallBuyOracleContractAddress(address _address)
        public
        onlyOwner
    {
        IBallBuyOracle candidateContract = IBallBuyOracle(_address);

        // Verify the contract is the one we expect
        require(candidateContract.IS_BALL_BUY_ORACLE());

        // Set the new contract address
        ballBuyOracleContract = candidateContract;
    }

    // Entry point
    function _callBallBuyOracle(
        address _to,
        uint16 _machineServerId,
        uint16 _amount,
        uint256 _ticketTokenId,
        bool _isGoldBuy
    ) internal nonReentrant returns (uint256) {
        uint256 requestId = ballBuyOracleContract.requestBallBuy(
            _to,
            _machineServerId,
            _amount,
            _ticketTokenId,
            _isGoldBuy
        );
        _pendingBallBuyRequests[requestId] = true;
        return requestId;
    }

    // Exit point, to be implemented by the use case contract
    function callback(
        uint256 _requestId,
        address _to,
        string calldata _ballTokenURIPrefix,
        BallMintData[] calldata _ballsMintData,
        uint256 _ticketTokenId,
        bool _isGoldBuy
    ) external virtual;
}
