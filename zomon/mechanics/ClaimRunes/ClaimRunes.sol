// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/RUNE/IRune.sol";

import "../../common/FundsManagementAccessControl/FundsManagementAccessControl.sol";

contract ClaimRunes is FundsManagementAccessControl {
    bytes32 public constant CLAIMER_ROLE = keccak256("CLAIMER_ROLE");

    uint256 public claimIntervalHours = 24;

    IRune public runeContract;

    mapping(address => uint256) private _lastClaimedTimestampByAddress;

    event ClaimedRunes(
        address indexed claimant,
        uint256[] serverIds,
        uint256[] amounts
    );

    constructor(address _runeContractAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        setRuneContract(_runeContractAddress);
    }

    function getNextClaimTimestamp(address _address)
        public
        view
        returns (uint256)
    {
        return
            _lastClaimedTimestampByAddress[_address] +
            claimIntervalHours *
            1 hours;
    }

    function setClaimIntervalHours(uint256 _hours)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        claimIntervalHours = _hours;
    }

    function setRuneContract(address _address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IRune candidateContract = IRune(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.IS_RUNE_CONTRACT(),
            "CONTRACT_ADDRES_IS_NOT_A_RUNE_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        runeContract = candidateContract;
    }

    function matchIsClaimAvailable(address _address)
        public
        view
        returns (bool)
    {
        return block.timestamp >= getNextClaimTimestamp(_address);
    }

    function claim(
        address _to,
        uint256[] calldata _serverIds,
        uint256[] calldata _amounts
    ) external onlyRole(CLAIMER_ROLE) {
        require(matchIsClaimAvailable(_to), "CLAIM_NOT_AVAILABLE");

        _lastClaimedTimestampByAddress[_to] = block.timestamp;

        runeContract.mintBatch(_to, _serverIds, _amounts, "");

        emit ClaimedRunes(_to, _serverIds, _amounts);
    }
}
