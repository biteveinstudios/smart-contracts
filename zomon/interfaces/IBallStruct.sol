// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

struct Ball {
    uint16 serverId;
    uint16 setId;
    uint8 edition;
    uint16 minRunes;
    uint16 maxRunes;
    bool isShiny;
    string name;
}

struct BallMintData {
    uint16 serverId;
    uint16 setId;
    // no edition
    uint16 minRunes;
    uint16 maxRunes;
    bool isShiny;
    string name;
}
