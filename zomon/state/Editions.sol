// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Editions is AccessControl {
    bool public constant IS_EDITIONS_CONTRACT = true;

    bytes32 public constant SET_ID_EDITIONS_MANAGER_ROLER =
        keccak256("SET_ID_EDITIONS_MANAGER_ROLER");

    bytes32 public constant SET_ID_EDITIONS_INCREASER_ROLE =
        keccak256("SET_ID_EDITIONS_INCREASER_ROLE");

    mapping(uint256 => uint256) private _currentEditionBySetId;
    mapping(uint256 => uint256) private _currentEditionItemsCountBySetId;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(SET_ID_EDITIONS_MANAGER_ROLER, _msgSender());
    }

    function setSetsIdsCurrentEdition(
        uint16[] calldata _setIds,
        uint256[] calldata _currentSetsIdsEditions
    ) external onlyRole(SET_ID_EDITIONS_MANAGER_ROLER) {
        for (uint256 i = 0; i < _setIds.length; i++) {
            _currentEditionBySetId[_setIds[i]] = _currentSetsIdsEditions[i];
        }
    }

    function _getEditionSize(uint8 _edition)
        private
        pure
        returns (uint256 _editionSize)
    {
        return uint256(_edition) * 100;
    }

    function getCurrentSetIdEdition(uint16 _setId)
        public
        view
        returns (uint8 _currentSetIdEdition)
    {
        uint256 currentEdition = _currentEditionBySetId[_setId];

        require(currentEdition > 0, "SET_ID_CURRENT_EDITION_NOT_SET");

        return uint8(currentEdition);
    }

    function getCurrentSetIdEditionItemsCount(uint16 _setId)
        public
        view
        returns (uint256 _currentSetIdItemsCount)
    {
        return _currentEditionItemsCountBySetId[_setId];
    }

    function increaseCurrentSetIdEditionItemsCount(uint16 _setId)
        external
        onlyRole(SET_ID_EDITIONS_INCREASER_ROLE)
        returns (uint8 _currentSetIdEdition)
    {
        uint8 currentSetIdEdition = getCurrentSetIdEdition(_setId);
        uint256 currentSetIdEditionItemsCount = getCurrentSetIdEditionItemsCount(
                _setId
            );

        if (
            currentSetIdEditionItemsCount + 1 ==
            _getEditionSize(currentSetIdEdition)
        ) {
            _currentEditionBySetId[_setId] = currentSetIdEdition + 1;
            _currentEditionItemsCountBySetId[_setId] = 0;

            return currentSetIdEdition + 1;
        }

        _currentEditionItemsCountBySetId[_setId] =
            currentSetIdEditionItemsCount +
            1;

        return currentSetIdEdition;
    }
}
