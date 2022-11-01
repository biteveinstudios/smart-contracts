// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../../common/FundsManagementOwnable/FundsManagementOwnable.sol";

import "../../tokens/ZOMON/IZomonStruct.sol";

import "./ISyncZomonOracle.sol";

abstract contract SyncZomonOracleCaller is
    ReentrancyGuard,
    FundsManagementOwnable
{
    bool public constant IS_SYNC_ZOMON_ORACLE_CALLER = true;

    ISyncZomonOracle public syncZomonOracleContract;

    mapping(uint256 => bool) internal _pendingSyncZomonRequests;

    constructor(address _syncZomonOracleContractAddress) {
        setSyncZomonOracleContractAddress(_syncZomonOracleContractAddress);
    }

    function setSyncZomonOracleContractAddress(address _address)
        public
        onlyOwner
    {
        ISyncZomonOracle candidateContract = ISyncZomonOracle(_address);

        // Verify the contract is the one we expect
        require(candidateContract.IS_SYNC_ZOMON_ORACLE());

        // Set the new contract address
        syncZomonOracleContract = candidateContract;
    }

    // Entry point for level sync
    function _callSyncZomonLevelOracle(address _to, uint256 _zomonTokenId)
        internal
        nonReentrant
        returns (uint256)
    {
        uint256 requestId = syncZomonOracleContract.requestZomonLevelSync(
            _to,
            _zomonTokenId
        );
        _pendingSyncZomonRequests[requestId] = true;
        return requestId;
    }

    // Entry point for one time pre presale sync
    function _callSyncZomonOneTimePrePresaleOracle(
        address _to,
        uint256 _zomonTokenId
    ) internal nonReentrant returns (uint256) {
        uint256 requestId = syncZomonOracleContract
            .requestZomonOneTimePrePresaleSync(_to, _zomonTokenId);
        _pendingSyncZomonRequests[requestId] = true;
        return requestId;
    }

    // Exit point
    function syncCallback(
        uint256 _requestId,
        address _to,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external virtual;
}
