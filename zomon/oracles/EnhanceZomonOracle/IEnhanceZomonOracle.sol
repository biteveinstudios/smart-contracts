// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/ZOMON/IZomonStruct.sol";

interface IEnhanceZomonOracle {
    function IS_ENHANCE_ZOMON_ORACLE() external returns (bool);

    function requestZomonPremiumEnhance(
        address _to,
        uint256 _zomonTokenId,
        uint256 _targetLevel
    ) external returns (uint256);

    function reportZomonEnhance(
        uint256 _requestId,
        address _callerAddress,
        address _to,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external;
}
