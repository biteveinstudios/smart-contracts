// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

struct Zomon {
    /* 32 bytes pack */
    uint16 serverId;
    uint16 setId;
    uint8 edition;
    uint8 rarityId;
    uint8 genderId;
    uint8 zodiacSignId;
    uint16 skillId;
    uint16 leaderSkillId;
    bool canLevelUp;
    bool canEvolve;
    uint16 level;
    uint8 evolution;
    uint24 hp;
    uint24 attack;
    uint24 defense;
    uint24 critical;
    uint24 evasion;
    /*****************/
    bool isShiny;
    uint8 shinyBoostedStat; // 0 = none, 1 = hp, 2 = attack, 3 = defense, 4 = critical, 5 = evasion
    uint16 maxLevel;
    uint8 maxRunesCount;
    uint16 generation;
    uint8 innerTokenDecimals;
    uint8[] typesIds;
    uint16[] diceFacesIds;
    uint16[] runesIds;
    string name;
    address innerTokenAddress;
    uint256 minLevelInnerTokenBalance;
    uint256 maxLevelInnerTokenBalance;
}
