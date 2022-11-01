// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/ZOMON/IZomonStruct.sol";

import "../../common/ZomonContractCallerOwnable/ZomonContractCallerOwnable.sol";

import "../../oracles/SyncZomonOracle/SyncZomonOracleCaller.sol";

contract SyncZomon is ZomonContractCallerOwnable, SyncZomonOracleCaller {
    constructor(
        address _zomonContractAddress,
        address _syncZomonOracleContractAddress
    )
        ZomonContractCallerOwnable(_zomonContractAddress)
        SyncZomonOracleCaller(_syncZomonOracleContractAddress)
    {}

    function syncLevel(uint256 _zomonTokenId) external {
        // Check sender has Zomon
        require(
            zomonContract.ownerOf(_zomonTokenId) == _msgSender(),
            "ONLY_ZOMON_OWNER_ALLOWED"
        );

        // Check Zomon is approved
        require(
            zomonContract.getApproved(_zomonTokenId) == address(this) ||
                zomonContract.isApprovedForAll(_msgSender(), address(this)),
            "ZOMON_NOT_APPROVED"
        );

        _callSyncZomonLevelOracle(_msgSender(), _zomonTokenId);
    }

    function syncOneTimePrePresale(uint256 _zomonTokenId) external {
        // Check sender has Zomon
        require(
            zomonContract.ownerOf(_zomonTokenId) == _msgSender(),
            "ONLY_ZOMON_OWNER_ALLOWED"
        );

        // Check Zomon is approved
        require(
            zomonContract.getApproved(_zomonTokenId) == address(this) ||
                zomonContract.isApprovedForAll(_msgSender(), address(this)),
            "ZOMON_NOT_APPROVED"
        );

        Zomon memory zomon = zomonContract.getZomon(_zomonTokenId);

        // Checks Zomon needs this sync
        require(
            zomon.isShiny == false && zomon.maxLevelInnerTokenBalance == 0,
            "ZOMON_NOT_VALID_FOR_ONE_TIME_PRE_PRESALE_SYNC"
        );

        _callSyncZomonOneTimePrePresaleOracle(_msgSender(), _zomonTokenId);
    }

    function syncCallback(
        uint256 _requestId,
        address _to,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external override nonReentrant {
        // Only oracle should be able to call
        require(
            _msgSender() == address(syncZomonOracleContract),
            "NOT_AUTHORIZED"
        );

        // Ensure this is a legitimate callback request
        require(
            _pendingSyncZomonRequests[_requestId],
            "REQUEST_ID_IS_NOT_PENDING"
        );

        // Remove the request from pending requests
        delete _pendingSyncZomonRequests[_requestId];

        // Burn Zomon
        zomonContract.burn(_zomonTokenId);

        // Mint Zomon
        zomonContract.mint(_to, _zomonTokenId, _zomonTokenURI, _zomonData);
    }
}
