// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/ZOMON/IZomonStruct.sol";
import "../../tokens/RUNE/IRuneStruct.sol";

interface IBallGachaponOracle {
    function IS_BALL_GACHAPON_ORACLE() external returns (bool);

    function requestBallGachapon(uint256 _tokenId, address _to)
        external
        returns (uint256);

    function reportBallGachapon(
        uint256 _requestId,
        address _callerAddress,
        uint256 _ballTokenId,
        address _to,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData,
        RunesMint calldata _runesData
    ) external;
}
