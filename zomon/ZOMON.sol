// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "./common/FundsManagementAccessControl.sol";

import "./interfaces/IZomonStruct.sol";

contract ZOMON is
    Ownable,
    AccessControl,
    FundsManagementAccessControl,
    ERC721URIStorage,
    ERC721Burnable
{
    bool public constant IS_ZOMON_CONTRACT = true;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(uint256 => Zomon) private _zomons;

    constructor() ERC721("Zomon creature", "ZOMON") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function getZomon(uint256 _tokenId) public view returns (Zomon memory) {
        require(_exists(_tokenId), "TOKEN_ID_DOES_NOT_EXIST");
        return _zomons[_tokenId];
    }

    function mint(
        address _to,
        uint256 _tokenId,
        string calldata _tokenURI,
        Zomon calldata _zomonData
    ) external onlyRole(MINTER_ROLE) {
        _zomons[_tokenId] = Zomon(
            _zomonData.serverId,
            _zomonData.setId,
            _zomonData.edition,
            _zomonData.rarityId,
            _zomonData.genderId,
            _zomonData.zodiacSignId,
            _zomonData.skillId,
            _zomonData.leaderSkillId,
            _zomonData.canLevelUp,
            _zomonData.canEvolve,
            _zomonData.level,
            _zomonData.evolution,
            _zomonData.hp,
            _zomonData.attack,
            _zomonData.defense,
            _zomonData.critical,
            _zomonData.evasion,
            _zomonData.isShiny,
            _zomonData.shinyBoostedStat,
            _zomonData.maxLevel,
            _zomonData.maxRunesCount,
            _zomonData.generation,
            _zomonData.innerTokenDecimals,
            _zomonData.typesIds,
            _zomonData.diceFacesIds,
            _zomonData.runesIds,
            _zomonData.name,
            _zomonData.innerTokenAddress,
            _zomonData.minLevelInnerTokenBalance,
            _zomonData.maxLevelInnerTokenBalance
        );

        _mint(_to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
    }

    // Inner token balance = min_balance + (max_balance - min_balance) * POW((current_level - 1) / (max_level - 1)), 2)
    //
    // Min and max inner token balances have decimals applied, however level division might end up in float numbers, so we need to apply the same precision
    // As we have a POW of factor 2, we need to apply to either apply DECIMALS / 2 inside the POW and DECIMALS outside, or apply DECIMALS inside and DECIMALS * 2 outside
    // Applying DECIMALS * 2 is risky because of potential overflows (Solidity has 77 bits of precision), so we are rounding if the DECIMALS / 2 when required as it's not harmful.
    //
    // The final formula is:
    //
    // Inner token balance = (min_balance * 10**(decimals) + (max_balance - min_balance) * POW((current_level - 1) * 10**(decimals / 2 + decimals % 2) / (max_level - 1)), 2)) / 10**(decimals)
    //
    // An example of why this is equivalent when using floating precision:
    //
    // min_balance = 1; max_balance = 10; current_level = 5; max_level = 10; decimals = 2
    //
    // 1 + (10 - 1) * ((5 - 1) / (10 - 1))**2 = 1 + 9 * 0.1975... = 2.7777...
    // (1 * 10**2 + (10 - 1) * ((5 - 1) * 10**(2/2 + 2%2) / (10 - 1))**2) / 10**2 = (100 + 9 * 19.75...) / 10**2 = 277.77... / 10**2 = 2.7777...
    function getCurrentInnerTokenBalance(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Zomon memory zomon = getZomon(_tokenId);

        return
            (zomon.minLevelInnerTokenBalance *
                10**(zomon.innerTokenDecimals) +
                (zomon.maxLevelInnerTokenBalance -
                    zomon.minLevelInnerTokenBalance) *
                ((((zomon.level - 1) *
                    10 **
                        (
                            (zomon.innerTokenDecimals /
                                2 +
                                (zomon.innerTokenDecimals % 2))
                        )) / (zomon.maxLevel - 1))**2)) /
            10**(zomon.innerTokenDecimals);
    }

    /* Solidity overrides */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
