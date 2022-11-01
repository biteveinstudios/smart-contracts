// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/ZOMON/IZomon.sol";
import "../../tokens/ZOMON/IZomonStruct.sol";

import "../../common/FundsManagementOwnable/FundsManagementOwnable.sol";
import "../../common/ZomonContractCallerOwnable/ZomonContractCallerOwnable.sol";
import "../../common/RuneContractCallerOwnable/RuneContractCallerOwnable.sol";

import "../../oracles/EvolveZomonOracle/EvolveZomonOracleCaller.sol";

contract EvolveZomon is
    ZomonContractCallerOwnable,
    RuneContractCallerOwnable,
    EvolveZomonOracleCaller
{
    constructor(
        address _zomonContractAddress,
        address _runeContractAddress,
        address _evolveZomonOracleContractAddress
    )
        ZomonContractCallerOwnable(_zomonContractAddress)
        RuneContractCallerOwnable(_runeContractAddress)
        EvolveZomonOracleCaller(_evolveZomonOracleContractAddress)
    {}

    function evolve(
        uint256 _zomonTokenId,
        uint256[] calldata _copiesZomonTokenIds
    ) external {
        // Check sender is the owner of the Zomon to evolve
        require(
            zomonContract.ownerOf(_zomonTokenId) == _msgSender(),
            "ONLY_ZOMON_OWNER_ALLOWED"
        );

        // Check approval on Zomon to evolve and copies
        if (
            zomonContract.isApprovedForAll(_msgSender(), address(this)) == false
        ) {
            require(
                zomonContract.getApproved(_zomonTokenId) == address(this),
                "ZOMON_NOT_APPROVED"
            );

            for (uint256 i = 0; i < _copiesZomonTokenIds.length; i++) {
                require(
                    zomonContract.getApproved(_copiesZomonTokenIds[i]) ==
                        address(this),
                    "ZOMON_NOT_APPROVED"
                );
            }
        }

        Zomon memory zomon = zomonContract.getZomon(_zomonTokenId);

        // Check Zomon can evolve
        require(zomon.canEvolve, "ZOMON_CANNOT_EVOLVE");

        // Check enough Zomon copies (N copies are required at evolution N)
        require(
            _copiesZomonTokenIds.length == zomon.evolution,
            "NOT_ENOUGH_ZOMON_COPIES"
        );

        // Check sender is the owner of the Zomon copies to burn
        // Check all Zomon copies are of the same specifie of the Zomon to evolve
        // Check all Zomon copies are not shiny
        // Check all Zomon copies are unique
        for (uint256 i = 0; i < _copiesZomonTokenIds.length; i++) {
            uint256 zomonCopyTokenId = _copiesZomonTokenIds[i];

            require(
                zomonContract.ownerOf(zomonCopyTokenId) == _msgSender(),
                "ONLY_ZOMON_OWNER_ALLOWED"
            );

            Zomon memory zomonCopy = zomonContract.getZomon(zomonCopyTokenId);

            require(
                zomonCopy.serverId == zomon.serverId,
                "ZOMON_COPY_NOT_SAME_SPECIE"
            );
            require(
                zomonCopy.isShiny == false,
                "SHINY_ZOMONS_CANNOT_BE_USED_AS_COPIES"
            );

            for (uint256 j = 0; j < i; j++) {
                require(
                    zomonCopyTokenId != _copiesZomonTokenIds[j],
                    "ZOMON_COPY_NOT_UNIQUE"
                );
            }
        }

        _callEvolveZomonOracle(
            _msgSender(),
            _zomonTokenId,
            _copiesZomonTokenIds
        );
    }

    function evolveCallback(
        uint256 _requestId,
        address _to,
        uint256 _zomonTokenId,
        uint256[] calldata _copiesZomonTokenIds,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external override nonReentrant {
        // Only oracle should be able to call
        require(
            _msgSender() == address(evolveZomonOracleContract),
            "NOT_AUTHORIZED"
        );

        // Ensure this is a legitimate callback request
        require(
            _pendingEvolveZomonRequests[_requestId],
            "REQUEST_ID_IS_NOT_PENDING"
        );

        // Remove the request from pending requests
        delete _pendingEvolveZomonRequests[_requestId];

        for (uint256 i = 0; i < _copiesZomonTokenIds.length; i++) {
            Zomon memory zomonCopy = zomonContract.getZomon(
                _copiesZomonTokenIds[i]
            );

            // Return engraved runes
            uint8 maxRunesCount = zomonCopy.maxRunesCount;

            uint256 startIndex = uint256(
                (zomonCopy.evolution - 1) * maxRunesCount
            );
            uint256 maxIndex = startIndex + uint256(maxRunesCount);

            for (
                uint256 j = startIndex;
                j < maxIndex && j < zomonCopy.runesIds.length;
                j++
            ) {
                uint16 runeServerId = zomonCopy.runesIds[j];
                if (runeServerId != 0) {
                    runeContract.mint(_to, runeServerId, 1, "");
                }
            }

            // Burn Zomon
            zomonContract.burn(_copiesZomonTokenIds[i]);
        }

        // Burn Zomon
        zomonContract.burn(_zomonTokenId);

        // Mint Zomon with new data
        zomonContract.mint(_to, _zomonTokenId, _zomonTokenURI, _zomonData);
    }
}
