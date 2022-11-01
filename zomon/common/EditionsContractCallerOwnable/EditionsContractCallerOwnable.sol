// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../../state/Editions/IEditions.sol";

contract EditionsContractCallerOwnable is Ownable {
    IEditions public editionsContract;

    constructor(address _editionsContractAddress) {
        setEditionsContract(_editionsContractAddress);
    }

    function setEditionsContract(address _address) public onlyOwner {
        IEditions candidateContract = IEditions(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.IS_EDITIONS_CONTRACT(),
            "CONTRACT_ADDRES_IS_NOT_AN_EDITIONS_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        editionsContract = candidateContract;
    }
}
