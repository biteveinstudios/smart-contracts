// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

import "./common/FundsManagementAccessControl.sol";

import "./interfaces/IRuneStruct.sol";

contract RUNE is AccessControl, FundsManagementAccessControl, ERC1155Burnable {
    bool public constant IS_RUNE_CONTRACT = true;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(uint256 => Rune) private _runes;

    event RuneCreated(
        uint256 indexed runeId,
        string name,
        uint16 indexed setId
    );

    // We pass and empty string for token URI because RUNES are all ERC-20 tokens
    constructor() ERC1155("") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function exists(uint256 _serverId) public view returns (bool) {
        return _runes[_serverId].serverId > 0; // if no value yet, integers are 0, server id must be bigger to be valid
    }

    function getRune(uint256 _serverId) external view returns (Rune memory) {
        require(exists(_serverId), "SERVER_ID_DOES_NOT_EXIST");

        return _runes[_serverId];
    }

    function createRune(Rune calldata _runeData)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_runeData.serverId > 0, "SERVER_ID_NOT_VALID");
        require(exists(_runeData.serverId) == false, "RUNE_ALREADY_EXISTS");

        _runes[_runeData.serverId] = Rune(
            _runeData.serverId,
            _runeData.setId,
            _runeData.typeId,
            _runeData.charmedRuneServerId,
            _runeData.runesCountToCharm,
            _runeData.name
        );

        emit RuneCreated(_runeData.serverId, _runeData.name, _runeData.setId);
    }

    function mint(
        address _to,
        uint256 _serverId,
        uint256 _amount,
        bytes calldata _data
    ) external onlyRole(MINTER_ROLE) {
        require(exists(_serverId), "RUNE_DOES_NOT_EXIST");

        _mint(_to, _serverId, _amount, _data);
    }

    function mintBatch(
        address _to,
        uint256[] calldata _serverIds,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < _serverIds.length; i++) {
            require(exists(_serverIds[i]), "RUNE_DOES_NOT_EXIST");
        }

        _mintBatch(_to, _serverIds, _amounts, _data);
    }

    /* Solidity overrides */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
