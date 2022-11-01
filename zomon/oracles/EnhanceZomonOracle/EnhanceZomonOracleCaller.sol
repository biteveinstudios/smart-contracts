// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../../common/FundsManagementOwnable/FundsManagementOwnable.sol";

import "../../tokens/ZOMON/IZomonStruct.sol";

import "./IEnhanceZomonOracle.sol";

abstract contract EnhanceZomonOracleCaller is
    ReentrancyGuard,
    FundsManagementOwnable
{
    bool public constant IS_ENHANCE_ZOMON_ORACLE_CALLER = true;

    IEnhanceZomonOracle public enhanceZomonOracleContract;

    mapping(uint256 => bool) internal _pendingEnhanceZomonRequests;

    constructor(address _enhanceZomonOracleContractAddress) {
        setEnhanceZomonOracleContractAddress(
            _enhanceZomonOracleContractAddress
        );
    }

    function setEnhanceZomonOracleContractAddress(address _address)
        public
        onlyOwner
    {
        IEnhanceZomonOracle candidateContract = IEnhanceZomonOracle(_address);

        // Verify the contract is the one we expect
        require(candidateContract.IS_ENHANCE_ZOMON_ORACLE());

        // Set the new contract address
        enhanceZomonOracleContract = candidateContract;
    }

    // Entry point for level sync
    function _callEnhancePremiumOracle(
        address _to,
        uint256 _zomonTokenId,
        uint256 _targetLevel
    ) internal nonReentrant returns (uint256) {
        uint256 requestId = enhanceZomonOracleContract
            .requestZomonPremiumEnhance(_to, _zomonTokenId, _targetLevel);
        _pendingEnhanceZomonRequests[requestId] = true;
        return requestId;
    }

    // Exit point
    function enhanceCallback(
        uint256 _requestId,
        address _to,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external virtual;
}
