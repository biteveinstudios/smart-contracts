// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/ZOMON/IZomonStruct.sol";

interface IEngraveRuneOracleCaller {
    function IS_ENGRAVE_RUNE_ORACLE_CALLER() external pure returns (bool);

    function engraveCallback(
        uint256 _requestId,
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external;

    function disengraveCallback(
        uint256 _requestId,
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external;
}
