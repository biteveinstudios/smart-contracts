// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./common/FundsManagementAccessControl.sol";

import "./interfaces/IBallStruct.sol";

contract BALL is
    Ownable,
    AccessControl,
    FundsManagementAccessControl,
    ERC721URIStorage,
    ERC721Burnable
{
    bool public constant IS_BALL_CONTRACT = true;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(uint256 => Ball) private _balls;

    constructor() ERC721("Zomon ball", "BALL") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        // Direct access is not recommended, but it's safe to do here and it saves 100 increments gas
        _tokenIds._value = 101;
    }

    function getBall(uint256 _tokenId) external view returns (Ball memory) {
        require(_exists(_tokenId), "TOKEN_ID_DOES_NOT_EXIST");
        return _balls[_tokenId];
    }

    function mint(
        address _to,
        string calldata _tokenURIPrefix,
        Ball calldata _ballData
    ) external onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 mintTokenId = _tokenIds.current();

        _balls[mintTokenId] = Ball(
            _ballData.serverId,
            _ballData.setId,
            _ballData.edition,
            _ballData.minRunes,
            _ballData.maxRunes,
            _ballData.isShiny,
            _ballData.name
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
