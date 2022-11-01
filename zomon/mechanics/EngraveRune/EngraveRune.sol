// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/ZOMON/IZomonStruct.sol";

import "../../common/RuneContractCallerOwnable/RuneContractCallerOwnable.sol";
import "../../common/ZomonContractCallerOwnable/ZomonContractCallerOwnable.sol";

import "../../oracles/EngraveRuneOracle/EngraveRuneOracleCaller.sol";

contract EngraveRune is
    RuneContractCallerOwnable,
    ZomonContractCallerOwnable,
    EngraveRuneOracleCaller
{
    constructor(
        address _runeContractAddress,
        address _zomonContractAddress,
        address _engraveRuneOracleContractAddress
    )
        RuneContractCallerOwnable(_runeContractAddress)
        ZomonContractCallerOwnable(_zomonContractAddress)
        EngraveRuneOracleCaller(_engraveRuneOracleContractAddress)
    {}

    function _matchZomonHasFreeRuneSlot(Zomon memory _zomon)
        internal
        pure
        returns (bool)
    {
        uint8 previousEvolutionsSlots = (_zomon.evolution - 1) *
            _zomon.maxRunesCount;

        return
            _zomon.runesIds.length <
            previousEvolutionsSlots + _zomon.maxRunesCount;
    }

    function engrave(uint256 _runeServerId, uint256 _zomonTokenId) external {
        // Check sender has Rune
        require(
            runeContract.balanceOf(_msgSender(), _runeServerId) >= 1,
            "RUNE_NOT_OWNED"
        );

        // Check Rune is approved
        require(
            runeContract.isApprovedForAll(_msgSender(), address(this)),
            "RUNE_NOT_APPROVED"
        );

        // Check sender has Zomon
        require(
            zomonContract.ownerOf(_zomonTokenId) == _msgSender(),
            "ONLY_ZOMON_OWNER_ALLOWED"
        );

        // Check Zomon is approved
        require(
            zomonContract.getApproved(_zomonTokenId) == address(this) ||
                zomonContract.isApprovedForAll(_msgSender(), address(this)),
            "ZOMON_NOT_APPROVED"
        );

        Zomon memory zomon = zomonContract.getZomon(_zomonTokenId);

        // Check Zomon has a free rune slot
        require(
            _matchZomonHasFreeRuneSlot(zomon),
            "ZOMON_DOES_NOT_HAVE_FREE_RUNE_SLOT"
        );

        _callEngraveRuneOracle(_msgSender(), _runeServerId, _zomonTokenId);
    }

    function engraveCallback(
        uint256 _requestId,
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external override nonReentrant {
        // Only oracle should be able to call
        require(
            _msgSender() == address(engraveRuneOracleContract),
            "NOT_AUTHORIZED"
        );

        // Ensure this is a legitimate callback request
        require(
            _pendingEngraveRuneRequests[_requestId],
            "REQUEST_ID_IS_NOT_PENDING"
        );

        // Remove the request from pending requests
        delete _pendingEngraveRuneRequests[_requestId];

        // Burn Rune
        runeContract.burn(_to, _runeServerId, 1);

        // Burn Zomon
        zomonContract.burn(_zomonTokenId);

        // Mint Zomon
        zomonContract.mint(_to, _zomonTokenId, _zomonTokenURI, _zomonData);
    }

    function _matchZomonHasRune(Zomon memory _zomon, uint16 _runeServerId)
        internal
        pure
        returns (bool)
    {
        uint256 previousEvolutionsSlots = (_zomon.evolution - 1) *
            _zomon.maxRunesCount;

        for (
            uint256 i = previousEvolutionsSlots;
            i < _zomon.runesIds.length;
            i++
        ) {
            if (_zomon.runesIds[i] == _runeServerId) {
                return true;
            }
        }

        return false;
    }

    function disengrave(uint256 _runeServerId, uint256 _zomonTokenId) external {
        // Check sender has Zomon
        require(
            zomonContract.ownerOf(_zomonTokenId) == _msgSender(),
            "ONLY_ZOMON_OWNER_ALLOWED"
        );

        // Check Zomon is approved
        require(
            zomonContract.getApproved(_zomonTokenId) == address(this) ||
                zomonContract.isApprovedForAll(_msgSender(), address(this)),
            "ZOMON_NOT_APPROVED"
        );

        Zomon memory zomon = zomonContract.getZomon(_zomonTokenId);

        // Check Zomon has rune
        require(
            _matchZomonHasRune(zomon, uint16(_runeServerId)),
            "ZOMON_DOES_NOT_HAVE_RUNE"
        );

        _callDisengraveRuneOracle(_msgSender(), _runeServerId, _zomonTokenId);
    }

    function disengraveCallback(
        uint256 _requestId,
        address _to,
        uint256 _runeServerId,
        uint256 _zomonTokenId,
        string calldata _zomonTokenURI,
        Zomon calldata _zomonData
    ) external override nonReentrant {
        // Only oracle should be able to call
        require(
            _msgSender() == address(engraveRuneOracleContract),
            "NOT_AUTHORIZED"
        );

        // Ensure this is a legitimate callback request
        require(
            _pendingDisengraveRuneRequests[_requestId],
            "REQUEST_ID_IS_NOT_PENDING"
        );

        // Remove the request from pending requests
        delete _pendingDisengraveRuneRequests[_requestId];

        // Burn Zomon
        zomonContract.burn(_zomonTokenId);

        // Mint Zomon
        zomonContract.mint(_to, _zomonTokenId, _zomonTokenURI, _zomonData);

        // Mint Rune
        runeContract.mint(_to, _runeServerId, 1, "");
    }
}
