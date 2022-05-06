// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

interface IEditions {
    function IS_EDITIONS_CONTRACT() external pure returns (bool);

    function getCurrentSetIdEdition(uint16 _setId)
        external
        view
        returns (uint8 _currentSetIdEdition);

    function getCurrentSetIdEditionItemsCount(uint16 _setId)
        external
        view
        returns (uint256 _currentSetIdItemsCount);

    function increaseCurrentSetIdEditionItemsCount(uint16 _setId)
        external
        returns (uint8 _currentSetIdEdition);
}
