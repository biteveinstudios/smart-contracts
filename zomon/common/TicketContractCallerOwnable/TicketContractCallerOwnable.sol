// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../../tokens/TICKET/ITicket.sol";

contract TicketContractCallerOwnable is Ownable {
    ITicket public ticketContract;

    constructor(address _ticketContractAddress) {
        setTicketContract(_ticketContractAddress);
    }

    function setTicketContract(address _address) public onlyOwner {
        ITicket candidateContract = ITicket(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.IS_TICKET_CONTRACT(),
            "CONTRACT_ADDRES_IS_NOT_A_TICKET_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        ticketContract = candidateContract;
    }
}
