// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IRune is IERC1155 {
    function IS_RUNE_CONTRACT() external pure returns (bool);

    function mint(
        address to,
        uint256 serverId,
        uint256 amount,
        bytes calldata data
    ) external;

    function mintBatch(
        address to,
        uint256[] calldata serverIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
