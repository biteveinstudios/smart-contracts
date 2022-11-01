// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/RUNE/IRune.sol";
import "../../tokens/RUNE/IRuneStruct.sol";

import "../../common/FundsManagementOwnable/FundsManagementOwnable.sol";
import "../../common/RuneContractCallerOwnable/RuneContractCallerOwnable.sol";

contract CharmRune is FundsManagementOwnable, RuneContractCallerOwnable {
    constructor(address _runeContractAddress)
        RuneContractCallerOwnable(_runeContractAddress)
    {}

    function charm(uint256 _runeServerId) external {
        Rune memory rune = runeContract.getRune(_runeServerId);

        require(
            runeContract.balanceOf(_msgSender(), _runeServerId) >=
                rune.runesCountToCharm,
            "NOT_ENOUGH_RUNES"
        );

        require(rune.charmedRuneServerId > 0, "CHARM_CANNOT_BE_CHARMED");

        runeContract.burn(_msgSender(), _runeServerId, rune.runesCountToCharm);

        runeContract.mint(_msgSender(), rune.charmedRuneServerId, 1, "");
    }
}
