// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/ZOMON/IZomonStruct.sol";

interface IEngraveRuneOracle {
    function IS_ENGRAVE_RUNE_ORACLE() external returns (bool);

    function requestRuneEngrave(
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId
    ) external returns (uint256);

    function reportRuneEngrave(
        uint256 _requestId,
        address _callerAddress,
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external;

    function requestRuneDisengrave(
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId
    ) external returns (uint256);

    function reportRuneDisengrave(
        uint256 _requestId,
        address _callerAddress,
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external;
}
