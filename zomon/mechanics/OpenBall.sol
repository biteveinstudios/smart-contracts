// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../interfaces/IBall.sol";
import "../interfaces/IZomon.sol";
import "../interfaces/IRune.sol";

import "../interfaces/IZomonStruct.sol";
import "../interfaces/IRuneStruct.sol";

import "../oracles/BallGachaponOracleCaller.sol";

contract OpenBall is BallGachaponOracleCaller {
    IBall public ballContract;
    IZomon public zomonContract;
    IRune public runeContract;

    constructor(
        address _ballContractAddress,
        address _zomonContractAddress,
        address _runeContractAddress,
        address _ballGachaponOracleContractAddress
    ) BallGachaponOracleCaller(_ballGachaponOracleContractAddress) {
        setBallContract(_ballContractAddress);
        setZomonContract(_zomonContractAddress);
        setRuneContract(_runeContractAddress);
    }

    /* External contracts management */
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

    function setZomonContract(address _address) public onlyOwner {
        IZomon candidateContract = IZomon(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.IS_ZOMON_CONTRACT(),
            "CONTRACT_ADDRES_IS_NOT_A_ZOMON_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        zomonContract = candidateContract;
    }

    function setRuneContract(address _address) public onlyOwner {
        IRune candidateContract = IRune(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.IS_RUNE_CONTRACT(),
            "CONTRACT_ADDRES_IS_NOT_A_RUNE_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        runeContract = candidateContract;
    }

    // Entry point
    function openBall(uint256 _tokenId) external {
        require(
            ballContract.ownerOf(_tokenId) == _msgSender(),
            "ONLY_BALL_OWNER_ALLOWED"
        );

        require(
            ballContract.getApproved(_tokenId) == address(this),
            "BALL_NOT_APPROVED"
        );

        _callBallGachaponOracle(_tokenId, _msgSender());
    }

    // Oracle callback
    function callback(
        uint256 _requestId,
        uint256 _tokenId,
        address _to,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData,
        RunesMint calldata _runesData
    ) external override nonReentrant {
        // Only oracle should be able to call
        require(
            _msgSender() == address(ballGachaponOracleContract),
            "NOT_AUTHORIZED"
        );

        // Ensure this is a legitimate callback request
        require(
            _pendingBallGachaponRequests[_requestId],
            "REQUEST_ID_IS_NOT_PENDING"
        );

        // Remove the request from pending requests
        delete _pendingBallGachaponRequests[_requestId];

        // Burn ball
        ballContract.burn(_tokenId);

        // Mint Zomon
        zomonContract.mint(_to, _tokenId, _zomonTokenURI, _zomonData);

        // Mint Runes
        runeContract.mintBatch(_to, _runesData.ids, _runesData.amounts, "");
    }
}
