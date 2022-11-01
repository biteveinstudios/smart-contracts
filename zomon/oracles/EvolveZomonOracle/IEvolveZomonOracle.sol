// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/ZOMON/IZomonStruct.sol";

interface IEvolveZomonOracle {
    function IS_EVOLVE_ZOMON_ORACLE() external returns (bool);

    function requestZomonEvolve(
        address _to,
        uint256 _zomonTokenId,
        uint256[] calldata _copiesZomonTokenIds
    ) external returns (uint256);

    function reportZomonEvolve(
        uint256 _requestId,
        address _callerAddress,
        address _to,
        uint256 _zomonTokenId,
        uint256[] calldata _copiesZomonTokenIds,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external;
}
