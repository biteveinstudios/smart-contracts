// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

struct Ticket {
    uint16 serverId;
    address redeemContractAddress;
    uint256 expirationDate; // 0 = never expires
    string name;
}
