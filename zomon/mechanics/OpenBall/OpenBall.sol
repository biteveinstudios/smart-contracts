// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/BALL/IBall.sol";
import "../../tokens/ZOMON/IZomon.sol";
import "../../tokens/ZOMON/IZomonStruct.sol";
import "../../tokens/RUNE/IRune.sol";
import "../../tokens/RUNE/IRuneStruct.sol";

import "../../common/BallContractCallerOwnable/BallContractCallerOwnable.sol";
import "../../common/ZomonContractCallerOwnable/ZomonContractCallerOwnable.sol";
import "../../common/RuneContractCallerOwnable/RuneContractCallerOwnable.sol";

import "../../oracles/BallGachaponOracle/BallGachaponOracleCaller.sol";

contract OpenBall is
    BallGachaponOracleCaller,
    BallContractCallerOwnable,
    ZomonContractCallerOwnable,
    RuneContractCallerOwnable
{
    constructor(
        address _ballContractAddress,
        address _zomonContractAddress,
        address _runeContractAddress,
        address _ballGachaponOracleContractAddress
    )
        BallContractCallerOwnable(_ballContractAddress)
        ZomonContractCallerOwnable(_zomonContractAddress)
        RuneContractCallerOwnable(_runeContractAddress)
        BallGachaponOracleCaller(_ballGachaponOracleContractAddress)
    {}

    // Entry point
    function openBall(uint256 _tokenId) external {
        require(
            ballContract.ownerOf(_tokenId) == _msgSender(),
            "ONLY_BALL_OWNER_ALLOWED"
        );

        require(
            ballContract.getApproved(_tokenId) == address(this) ||
                ballContract.isApprovedForAll(_msgSender(), address(this)),
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
