// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/BALL/IBallStruct.sol";

interface IBallBuyOracleCaller {
    function IS_BALL_BUY_ORACLE_CALLER() external pure returns (bool);

    function callback(
        uint256 _requestId,
        address _to,
        string calldata _ballTokenURIPrefix,
        BallMintData[] calldata _ballsMintData,
        uint256 _ticketTokenId,
        bool _isGoldBuy
    ) external;
}
