// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../common/FundsManagementOwnable/FundsManagementOwnable.sol";
import "../../common/TicketContractCallerOwnable/TicketContractCallerOwnable.sol";

import "../../sales/Machine/IMachine.sol";

contract TicketRemapRedeemer is
    FundsManagementOwnable,
    TicketContractCallerOwnable
{
    bool public constant IS_TICKET_REMAP_REDEEMER_CONTRACT = true;

    mapping(address => address) public redeemContractAddressRemaps;

    constructor(address _ticketContractAddress)
        TicketContractCallerOwnable(_ticketContractAddress)
    {}

    function setTicketRedeemContractAdddressRemap(
        address _ticketRedeemContractAddress,
        address _remapAddress
    ) external onlyOwner {
        redeemContractAddressRemaps[
            _ticketRedeemContractAddress
        ] = _remapAddress;
    }

    function redeemTicket(uint256 _ticketTokenId) external {
        Ticket memory ticket = ticketContract.getTicket(_ticketTokenId);

        require(
            redeemContractAddressRemaps[ticket.redeemContractAddress] !=
                address(0),
            "REDEEM_CONTRACT_ADDRESS_IS_NOT_REMAPPED"
        );

        string memory tokenURI = ticketContract.tokenURI(_ticketTokenId);

        ticketContract.burn(_ticketTokenId);

        uint256 newTicketTokenId = ticketContract.mint(
            address(this),
            tokenURI,
            Ticket(
                ticket.serverId,
                redeemContractAddressRemaps[ticket.redeemContractAddress],
                ticket.expirationDate,
                ticket.name
            )
        );

        ticketContract.approve(
            redeemContractAddressRemaps[ticket.redeemContractAddress],
            newTicketTokenId
        );

        IMachine(redeemContractAddressRemaps[ticket.redeemContractAddress])
            .redeemTicket(newTicketTokenId);
    }
}
