// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../../tokens/GOLD/IGold.sol";

contract GoldContractCallerOwnable is Ownable {
    IGold public goldContract;

    constructor(address _goldContractAddress) {
        setGoldContract(_goldContractAddress);
    }

    function setGoldContract(address _address) public onlyOwner {
        IGold candidateContract = IGold(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.IS_GOLD_CONTRACT(),
            "CONTRACT_ADDRES_IS_NOT_A_GOLD_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        goldContract = candidateContract;
    }
}
