// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../tokens/ZOMON/IZomon.sol";
import "../../tokens/ZOMON/IZomonStruct.sol";

import "../../tokens/GOLD/IGold.sol";

import "../../common/FundsManagementOwnable/FundsManagementOwnable.sol";
import "../../common/ZomonContractCallerOwnable/ZomonContractCallerOwnable.sol";
import "../../common/GoldContractCallerOwnable/GoldContractCallerOwnable.sol";

contract SacrificeZomon is
    FundsManagementOwnable,
    ZomonContractCallerOwnable,
    GoldContractCallerOwnable
{
    address public constant NATIVE_TOKEN_ADDRESS =
        0x0000000000000000000000000000000000001010;

    constructor(address _zomonContractAddress, address _goldContractAddress)
        ZomonContractCallerOwnable(_zomonContractAddress)
        GoldContractCallerOwnable(_goldContractAddress)
    {}

    function sacrifice(uint256 _zomonTokenId) external {
        require(
            zomonContract.ownerOf(_zomonTokenId) == _msgSender(),
            "ONLY_ZOMON_OWNER_ALLOWED"
        );

        require(
            zomonContract.getApproved(_zomonTokenId) == address(this) ||
                zomonContract.isApprovedForAll(_msgSender(), address(this)),
            "ZOMON_NOT_APPROVED"
        );

        Zomon memory zomon = zomonContract.getZomon(_zomonTokenId);

        uint256 innerTokenBalance = zomonContract.getCurrentInnerTokenBalance(
            _zomonTokenId
        );

        require(innerTokenBalance > 0, "ZOMON_DOES_NOT_CONTAIN_INNER_TOKEN");

        zomonContract.burn(_zomonTokenId);

        // Handle native token
        if (zomon.innerTokenAddress == NATIVE_TOKEN_ADDRESS) {
            require(
                address(this).balance >= innerTokenBalance,
                "NOT_ENOUGH_FUNDS"
            );

            (bool success, ) = _msgSender().call{value: innerTokenBalance}("");
            require(success, "SENDING_FUNDS_FAILED");

            return;
        }

        // Handle gold token
        if (zomon.innerTokenAddress == address(goldContract)) {
            goldContract.mint(_msgSender(), innerTokenBalance);
            return;
        }

        // Handle any other token as an ERC20
        require(
            IERC20(zomon.innerTokenAddress).balanceOf(address(this)) >=
                innerTokenBalance,
            "NOT_ENOUGH_FUNDS"
        );
        require(
            IERC20(zomon.innerTokenAddress).transfer(
                _msgSender(),
                innerTokenBalance
            ),
            "SENDING_FUNDS_FAILED"
        );
    }
}
