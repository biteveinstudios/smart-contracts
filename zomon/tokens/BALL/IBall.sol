// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./IBallStruct.sol";

interface IBall is IERC721 {
    function IS_BALL_CONTRACT() external pure returns (bool);

    function getBall(uint256 _tokenId) external view returns (Ball memory);

    function mint(
        address _to,
        string calldata _tokenURIPrefix,
        Ball calldata _ballData
    ) external returns (uint256);

    function burn(uint256 _tokenId) external;
}
