// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./common/FundsManagementAccessControl.sol";

import "./interfaces/ITicketStruct.sol";

contract TICKET is
    Ownable,
    AccessControl,
    FundsManagementAccessControl,
    ERC721URIStorage,
    ERC721Burnable
{
    bool public constant IS_TICKET_CONTRACT = true;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(uint256 => Ticket) private _tickets;

    constructor() ERC721("Zomon gachapon ticket", "TICKET") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        // Save gas for the first minter: https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
        _tokenIds.increment();
    }

    function getTicket(uint256 _tokenId) external view returns (Ticket memory) {
        require(_exists(_tokenId), "TOKEN_ID_DOES_NOT_EXIST");
        return _tickets[_tokenId];
    }

    function mint(
        address _to,
        string calldata _tokenURIPrefix,
        Ticket calldata _ticketData
    ) external onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 mintTokenId = _tokenIds.current();

        _tickets[mintTokenId] = Ticket(
            _ticketData.serverId,
            _ticketData.redeemContractAddress,
            _ticketData.expirationDate,
            _ticketData.name
        );

        string memory _tokenURI = string(
            abi.encodePacked(_tokenURIPrefix, Strings.toString(mintTokenId))
        );

        _mint(_to, mintTokenId);
        _setTokenURI(mintTokenId, _tokenURI);

        _tokenIds.increment();

        return mintTokenId;
    }

    /* Solidity overrides */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
