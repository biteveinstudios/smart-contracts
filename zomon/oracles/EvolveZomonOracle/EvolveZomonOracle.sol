// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../common/FundsManagementAccessControl/FundsManagementAccessControl.sol";

import "../../tokens/ZOMON/IZomonStruct.sol";

import "./IEvolveZomonOracleCaller.sol";

contract EvolveZomonOracle is FundsManagementAccessControl {
    bool public constant IS_EVOLVE_ZOMON_ORACLE = true;

    bytes32 public constant REQUESTER_ROLE = keccak256("REQUESTER_ROLE");
    bytes32 public constant REPORTER_ROLE = keccak256("REPORTER_ROLE");

    mapping(address => uint256) private _requestIdNonceByAccount;

    mapping(uint256 => bool) private _pendingRequests;

    event RequestedZomonEvolve(
        uint256 indexed requestId,
        address indexed callerAddress,
        address indexed to,
        uint256 zomonTokenId,
        uint256[] copiesZomonTokenIds
    );
    event ReportedZomonEvolve(
        uint256 indexed requestId,
        address indexed callerAddress,
        address indexed to,
        uint256 zomonTokenId,
        uint256[] copiesZomonTokenIds,
        Zomon zomonData
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // Emits the event to trigger the oracle
    function requestZomonEvolve(
        address _to,
        uint256 _zomonTokenId,
        uint256[] calldata _copiesZomonTokenIds
    ) external onlyRole(REQUESTER_ROLE) returns (uint256) {
        _requestIdNonceByAccount[_msgSender()]++;

        uint256 requestId = _getRequestId(_msgSender());

        _pendingRequests[requestId] = true;

        emit RequestedZomonEvolve(
            requestId,
            _msgSender(),
            _to,
            _zomonTokenId,
            _copiesZomonTokenIds
        );

        return requestId;
    }

    // Calls the oracle caller back with the evolved Zomon data computed by the oracle
    function reportZomonEvolve(
        uint256 _requestId,
        address _callerAddress,
        address _to,
        uint256 _zomonTokenId,
        uint256[] calldata _copiesZomonTokenIds,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external onlyRole(REPORTER_ROLE) {
        require(_pendingRequests[_requestId], "REQUEST_ID_IS_NOT_PENDING");

        delete _pendingRequests[_requestId];

        IEvolveZomonOracleCaller callerContractInstance = IEvolveZomonOracleCaller(
                _callerAddress
            );

        require(
            callerContractInstance.IS_EVOLVE_ZOMON_ORACLE_CALLER(),
            "CALLER_ADDRESS_IS_NOT_AN_EVOLVE_ZOMON_ORACLE_CALLER_CONTRACT_INSTANCE"
        );

        emit ReportedZomonEvolve(
            _requestId,
            _callerAddress,
            _to,
            _zomonTokenId,
            _copiesZomonTokenIds,
            _zomonData
        );

        callerContractInstance.evolveCallback(
            _requestId,
            _to,
            _zomonTokenId,
            _copiesZomonTokenIds,
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
