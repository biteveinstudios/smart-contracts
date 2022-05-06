// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "./IBallStruct.sol";

interface IBallBuyOracle {
    function IS_BALL_BUY_ORACLE() external returns (bool);

    function requestBallBuy(
        address _to,
        uint16 _machineServerId,
        uint16 _amount,
        uint256 _ticketTokenId
    ) external returns (uint256);

    function reportBallBuy(
        uint256 _requestId,
        address _callerAddress,
        address _to,
        string calldata _ballTokenURIPrefix,
        BallMintData[] calldata _ballsMintData,
        uint256 _ticketTokenId
    ) external;
}
