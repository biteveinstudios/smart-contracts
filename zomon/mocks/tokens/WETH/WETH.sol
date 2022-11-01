// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETH is ERC20 {
    constructor(uint256 initialSupply) ERC20("Bite Vein WETH mock", "WETH") {
        _mint(msg.sender, initialSupply);
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}
