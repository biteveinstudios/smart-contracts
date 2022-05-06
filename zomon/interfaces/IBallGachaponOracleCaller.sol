// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "./IZomonStruct.sol";
import "./IRuneStruct.sol";

interface IBallGachaponOracleCaller {
    function IS_BALL_GACHAPON_ORACLE_CALLER() external pure returns (bool);

    function callback(
        uint256 _requestId,
        uint256 _tokenId,
        address _to,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData,
        RunesMint calldata _runesData
    ) external;
}
