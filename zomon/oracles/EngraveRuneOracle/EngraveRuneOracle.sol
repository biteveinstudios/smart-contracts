// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../common/FundsManagementAccessControl/FundsManagementAccessControl.sol";

import "../../tokens/ZOMON/IZomonStruct.sol";

import "./IEngraveRuneOracleCaller.sol";

contract EngraveRuneOracle is FundsManagementAccessControl {
    bool public constant IS_ENGRAVE_RUNE_ORACLE = true;

    bytes32 public constant REQUESTER_ROLE = keccak256("REQUESTER_ROLE");
    bytes32 public constant REPORTER_ROLE = keccak256("REPORTER_ROLE");

    mapping(address => uint256) private _requestIdNonceByAccount;

    mapping(uint256 => bool) private _pendingRequests;

    event RequestedRuneEngrave(
        uint256 indexed requestId,
        address indexed callerAddress,
        address indexed to,
        uint256 runeServerId,
        uint256 zomonTokenId
    );
    event ReportedRuneEngrave(
        uint256 indexed requestId,
        address indexed callerAddress,
        address indexed to,
        uint256 runeServerId,
        uint256 zomonTokenId,
        Zomon zomonData
    );

    event RequestedRuneDisengrave(
        uint256 indexed requestId,
        address indexed callerAddress,
        address indexed to,
        uint256 runeServerId,
        uint256 zomonTokenId
    );
    event ReportedRuneDisengrave(
        uint256 indexed requestId,
        address indexed callerAddress,
        address indexed to,
        uint256 runeServerId,
        uint256 zomonTokenId,
        Zomon zomonData
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // Emits the event to trigger the oracle
    function requestRuneEngrave(
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId
    ) external onlyRole(REQUESTER_ROLE) returns (uint256) {
        _requestIdNonceByAccount[_msgSender()]++;

        uint256 requestId = _getRequestId(_msgSender());

        _pendingRequests[requestId] = true;

        emit RequestedRuneEngrave(
            requestId,
            _msgSender(),
            _to,
            _runeServerId,
            _zomonTokenId
        );

        return requestId;
    }

    // Calls the oracle caller back with the engraved Zomon data computed by the oracle
    function reportRuneEngrave(
        uint256 _requestId,
        address _callerAddress,
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external onlyRole(REPORTER_ROLE) {
        require(_pendingRequests[_requestId], "REQUEST_ID_IS_NOT_PENDING");

        delete _pendingRequests[_requestId];

        IEngraveRuneOracleCaller callerContractInstance = IEngraveRuneOracleCaller(
                _callerAddress
            );

        require(
            callerContractInstance.IS_ENGRAVE_RUNE_ORACLE_CALLER(),
            "CALLER_ADDRESS_IS_NOT_AN_ENGRAVE_RUNE_ORACLE_CALLER_CONTRACT_INSTANCE"
        );

        emit ReportedRuneEngrave(
            _requestId,
            _callerAddress,
            _to,
            _runeServerId,
            _zomonTokenId,
            _zomonData
        );

        callerContractInstance.engraveCallback(
            _requestId,
            _to,
            _runeServerId,
            _zomonTokenId,
            _zomonTokenURI,
            _zomonData
        );
    }

    // Emits the event to trigger the oracle
    function requestRuneDisengrave(
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId
    ) external onlyRole(REQUESTER_ROLE) returns (uint256) {
        _requestIdNonceByAccount[_msgSender()]++;

        uint256 requestId = _getRequestId(_msgSender());

        _pendingRequests[requestId] = true;

        emit RequestedRuneDisengrave(
            requestId,
            _msgSender(),
            _to,
            _runeServerId,
            _zomonTokenId
        );

        return requestId;
    }

    // Calls the oracle caller back with the disengraved Zomon data computed by the oracle
    function reportRuneDisengrave(
        uint256 _requestId,
        address _callerAddress,
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external onlyRole(REPORTER_ROLE) {
        require(_pendingRequests[_requestId], "REQUEST_ID_IS_NOT_PENDING");

        delete _pendingRequests[_requestId];

        IEngraveRuneOracleCaller callerContractInstance = IEngraveRuneOracleCaller(
                _callerAddress
            );

        require(
            callerContractInstance.IS_ENGRAVE_RUNE_ORACLE_CALLER(),
            "CALLER_ADDRESS_IS_NOT_AN_ENGRAVE_RUNE_ORACLE_CALLER_CONTRACT_INSTANCE"
        );

        emit ReportedRuneDisengrave(
            _requestId,
            _callerAddress,
            _to,
            _runeServerId,
            _zomonTokenId,
            _zomonData
        );

        callerContractInstance.disengraveCallback(
            _requestId,
            _to,
            _runeServerId,
            _zomonTokenId,
            _zomonTokenURI,
            _zomonData
        );
    }

    function _getRequestId(address _sender) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(_sender, _requestIdNonceByAccount[_sender])
                )
            );
    }
}
