// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../BALL/IBallStruct.sol";

interface IGold is IERC20 {
    function IS_GOLD_CONTRACT() external pure returns (bool);

    function mint(address _to, uint256 _amount) external;

    function burnFrom(address _account, uint256 _amount) external;
}
