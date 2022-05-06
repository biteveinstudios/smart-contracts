// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../common/FundsManagementOwnable.sol";

import "../interfaces/IZomonStruct.sol";
import "../interfaces/IRuneStruct.sol";
import "../interfaces/IBallGachaponOracle.sol";

abstract contract BallGachaponOracleCaller is
    Ownable,
    ReentrancyGuard,
    FundsManagementOwnable
{
    bool public constant IS_BALL_GACHAPON_ORACLE_CALLER = true;

    IBallGachaponOracle public ballGachaponOracleContract;

    mapping(uint256 => bool) internal _pendingBallGachaponRequests;

    constructor(address _initialBallGachaponOracleContractAddress) {
        setBallGachaponOracleContractAddress(
            _initialBallGachaponOracleContractAddress
        );
    }

    /* External contracts management */
    function setBallGachaponOracleContractAddress(address _address)
        public
        onlyOwner
    {
        IBallGachaponOracle candidateContract = IBallGachaponOracle(_address);

        // Verify the contract is the one we expect
        require(candidateContract.IS_BALL_GACHAPON_ORACLE());

        // Set the new contract address
        ballGachaponOracleContract = candidateContract;
    }

    // Entry point
    function _callBallGachaponOracle(uint256 _tokenId, address _to)
        internal
        nonReentrant
        returns (uint256)
    {
        uint256 requestId = ballGachaponOracleContract.requestBallGachapon(
            _tokenId,
            _to
        );
        _pendingBallGachaponRequests[requestId] = true;
        return requestId;
    }

    // Exit point, to be implemented by the use case contract
    function callback(
        uint256 _requestId,
        uint256 _tokenId,
        address _to,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData,
        RunesMint calldata _runesData
    ) external virtual;
}
