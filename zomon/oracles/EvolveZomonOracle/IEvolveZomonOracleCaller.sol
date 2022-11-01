// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/ZOMON/IZomonStruct.sol";

interface IEvolveZomonOracleCaller {
    function IS_EVOLVE_ZOMON_ORACLE_CALLER() external pure returns (bool);

    function evolveCallback(
        uint256 _requestId,
        address _to,
        uint256 _zomonTokenId,
        uint256[] calldata _copiesZomonTokenIds,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external;
}
