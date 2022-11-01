// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/GOLD/IGold.sol";

import "../../common/FundsManagementAccessControl/FundsManagementAccessControl.sol";

contract ClaimGold is FundsManagementAccessControl {
    bytes32 public constant CLAIMER_ROLE = keccak256("CLAIMER_ROLE");

    uint256 public claimIntervalHours = 24;

    IGold public goldContract;

    mapping(address => uint256) private _lastClaimedTimestampByAddress;

    event ClaimedGold(address indexed claimant, uint256 amount);

    constructor(address _goldContractAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        setGoldContract(_goldContractAddress);
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

    function setGoldContract(address _address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IGold candidateContract = IGold(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.IS_GOLD_CONTRACT(),
            "CONTRACT_ADDRES_IS_NOT_A_GOLD_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        goldContract = candidateContract;
    }

    function matchIsClaimAvailable(address _address)
        public
        view
        returns (bool)
    {
        return block.timestamp >= getNextClaimTimestamp(_address);
    }

    function claim(address _to, uint256 _amount)
        external
        onlyRole(CLAIMER_ROLE)
    {
        require(matchIsClaimAvailable(_to), "CLAIM_NOT_AVAILABLE");

        _lastClaimedTimestampByAddress[_to] = block.timestamp;

        goldContract.mint(_to, _amount);

        emit ClaimedGold(_to, _amount);
    }
}
