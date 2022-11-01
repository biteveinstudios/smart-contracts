// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ITicketStruct.sol";

interface ITicket is IERC721 {
    function IS_TICKET_CONTRACT() external pure returns (bool);

    function getTicket(uint256 _tokenId) external view returns (Ticket memory);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function mint(
        address _to,
        string calldata _tokenURIPrefix,
        Ticket calldata _ticketData
    ) external returns (uint256);

    function burn(uint256 _tokenId) external;
}
