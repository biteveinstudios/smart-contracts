// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../../common/FundsManagementOwnable/FundsManagementOwnable.sol";

import "../../tokens/ZOMON/IZomonStruct.sol";

import "./IEngraveRuneOracle.sol";

abstract contract EngraveRuneOracleCaller is
    ReentrancyGuard,
    FundsManagementOwnable
{
    bool public constant IS_ENGRAVE_RUNE_ORACLE_CALLER = true;

    IEngraveRuneOracle public engraveRuneOracleContract;

    mapping(uint256 => bool) internal _pendingEngraveRuneRequests;
    mapping(uint256 => bool) internal _pendingDisengraveRuneRequests;

    constructor(address _engraveRuneOracleContractAddress) {
        setEngraveRuneOracleContractAddress(_engraveRuneOracleContractAddress);
    }

    function setEngraveRuneOracleContractAddress(address _address)
        public
        onlyOwner
    {
        IEngraveRuneOracle candidateContract = IEngraveRuneOracle(_address);

        // Verify the contract is the one we expect
        require(candidateContract.IS_ENGRAVE_RUNE_ORACLE());

        // Set the new contract address
        engraveRuneOracleContract = candidateContract;
    }

    // Entry point for engraving
    function _callEngraveRuneOracle(
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId
    ) internal nonReentrant returns (uint256) {
        uint256 requestId = engraveRuneOracleContract.requestRuneEngrave(
            _to,
            _runeServerId,
            _zomonTokenId
        );
        _pendingEngraveRuneRequests[requestId] = true;
        return requestId;
    }

    // Exit point for engraving, to be implemented by the use case contract
    function engraveCallback(
        uint256 _requestId,
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external virtual;

    // Entry point for disengraving
    function _callDisengraveRuneOracle(
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId
    ) internal nonReentrant returns (uint256) {
        uint256 requestId = engraveRuneOracleContract.requestRuneDisengrave(
            _to,
            _runeServerId,
            _zomonTokenId
        );
        _pendingDisengraveRuneRequests[requestId] = true;
        return requestId;
    }

    // Exit point for disengraving, to be implemented by the use case contract
    function disengraveCallback(
        uint256 _requestId,
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external virtual;
}
