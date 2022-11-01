// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/ZOMON/IZomonStruct.sol";

interface ISyncZomonOracle {
    function IS_SYNC_ZOMON_ORACLE() external returns (bool);

    function requestZomonLevelSync(address _to, uint256 _zomonTokenId)
        external
        returns (uint256);

    function reportZomonLevelSync(
        uint256 _requestId,
        address _callerAddress,
        address _to,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external;

    function requestZomonOneTimePrePresaleSync(
        address _to,
        uint256 _zomonTokenId
    ) external returns (uint256);

    function reportZomonOneTimePrePresaleSync(
        uint256 _requestId,
        address _callerAddress,
        address _to,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external;
}
