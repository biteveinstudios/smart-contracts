// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../../common/FundsManagementOwnable/FundsManagementOwnable.sol";

import "../../tokens/ZOMON/IZomonStruct.sol";

import "./IEvolveZomonOracle.sol";

abstract contract EvolveZomonOracleCaller is
    ReentrancyGuard,
    FundsManagementOwnable
{
    bool public constant IS_EVOLVE_ZOMON_ORACLE_CALLER = true;

    IEvolveZomonOracle public evolveZomonOracleContract;

    mapping(uint256 => bool) internal _pendingEvolveZomonRequests;

    constructor(address _evolveZomonOracleContractAddress) {
        setEvolveZomonOracleContractAddress(_evolveZomonOracleContractAddress);
    }

    function setEvolveZomonOracleContractAddress(address _address)
        public
        onlyOwner
    {
        IEvolveZomonOracle candidateContract = IEvolveZomonOracle(_address);

        // Verify the contract is the one we expect
        require(candidateContract.IS_EVOLVE_ZOMON_ORACLE());

        // Set the new contract address
        evolveZomonOracleContract = candidateContract;
    }

    // Entry point
    function _callEvolveZomonOracle(
        address _to,
        uint256 _zomonTokenId,
        uint256[] calldata _copiesZomonTokenIds
    ) internal nonReentrant returns (uint256) {
        uint256 requestId = evolveZomonOracleContract.requestZomonEvolve(
            _to,
            _zomonTokenId,
            _copiesZomonTokenIds
        );
        _pendingEvolveZomonRequests[requestId] = true;
        return requestId;
    }

    // Exit point, to be implemented by the use case contract
    function evolveCallback(
        uint256 _requestId,
        address _to,
        uint256 _zomonTokenId,
        uint256[] calldata _copiesZomonTokenIds,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external virtual;
}
