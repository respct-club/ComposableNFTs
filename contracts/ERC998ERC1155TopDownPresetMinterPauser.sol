// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "./ERC998ERC1155TopDown.sol";

/**
 * @dev {ERC998} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC998ERC1155TopDownPresetMinterPauser is
    Context,
    AccessControl,
    ERC998ERC1155TopDown,
    Pausable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 composableCount;
    address[] public indexedComposableId;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * Token URIs will be autogenerated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     * @param csnftPrice creators snft marketplace price
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 csnftPrice
    ) public ERC998ERC1155TopDown(name, symbol, baseURI, csnftPrice) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates a new token for `to`. The token URI autogenerated based on
     * the base URI passed at construction and the token ID.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 tokenId) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC721: must have minter role to mint"
        );
        require(tokenId > composableCount);

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(to, tokenId);
        indexedComposableId[tokenId] = msg.sender;
        composableCount++;
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC721PresetMinterPauserAutoId: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC721PresetMinterPauserAutoId: must have pauser role to unpause"
        );
        _unpause();
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(!paused(), "ERC721Pausable: token transfer while paused");

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _beforeChildTransfer(
        address operator,
        uint256 fromTokenId,
        address to,
        address childContract,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        require(!paused(), "ERC998Pausable: child transfer while paused");

        super._beforeChildTransfer(
            operator,
            fromTokenId,
            to,
            childContract,
            ids,
            amounts,
            data
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;
///@dev handle Batch receiving function - !!!!

/// @notice create tier supply and attach to composable
import "@openzeppelin/contracts/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";

/*
    erc1155.mint(admin, multiTokenTier0, multiTokenMaxSuply, "0x");
    erc1155.safeTransferFrom(admin, erc998.address, multiTokenTier0, 1, web3.utils.encodePacked(composable1));

*/
contract ERC1155TierUpgradePresetMinterPauser is ERC1155PresetMinterPauser {
    bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))

    constructor(string memory tierUri)
        public
        ERC1155PresetMinterPauser(tierUri)
    {}

    // function _mintTier(CSNFTContract csnftContract, uint tierId, bytes data ) private {
    //     uint256 amt = 1;
    //     _mint(csnftContract.address, tierId,1, data);
    // }

    function upgradeSNFT(
        address from, // where the tier is being trnsfered from  (we're minting)
        address csnftContract,
        uint256 tierId,
        bytes calldata data // web3.utils.encodePacked(composableId)
    ) external payable {
        //add tier checks

        require(tierId > 0 || balanceOf(msg.sender, tierId - 1) == 1);

        // 0 address
        require(
            csnftContract != address(0),
            "ERC998: transfer to the zero address"
        );
        // caller  of composable is owner of composable or is approved to transfer composable ,
        address operator = _msgSender();

        _mint(csnftContract, tierId, 1, data);
    }
}
