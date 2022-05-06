// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./IZomonStruct.sol";

interface IZomon is IERC721 {
    function IS_ZOMON_CONTRACT() external pure returns (bool);

    function mint(
        address _to,
        uint256 _tokenId,
        string memory _tokenURI,
        Zomon memory _zomonData
    ) external;
}
