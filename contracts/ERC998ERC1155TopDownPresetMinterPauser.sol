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
    using SafeMath for uint256;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    mapping(uint256 => uint256) tierIdtoUpgradeCost; // 1,2,3 ...  cost to upgrade to tier1, tier2, tier3...
    mapping(address => uint256) public ownerToComposableId;
    uint mintCost = 2 ether;
    address payable owner;
    uint256 composableCount;
    uint256 public totalSupply = 100; 

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * Token URIs will be autogenerated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 _fEngagementPoints // at 115 tierId 0
    ) public ERC998ERC1155TopDown(name, symbol, baseURI) {
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        owner = payable(msg.sender);
        composableCount = 0;
        tierIdtoUpgradeCost[1] = _fEngagementPoints;
    }

    /// @notice manually add tier upgrade prices
    function setTierUpgradeCost(uint256 _tierId, uint256 _cost) public {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Unauthorized tier price setter"
        );

        tierIdtoUpgradeCost[_tierId] = _cost;
    }

    /// returns uint price of tier upgrade
    function getTierUpgradeCost(uint256 _tierId) public view returns (uint256) {
        uint256 cost = tierIdtoUpgradeCost[_tierId];
        return cost;
    }

    // function incrementTierId(address _to) private {
    //     ownerToTierId[_to] = _latestTierId;
    // }

    function getComposableId(address _owner) public view returns (uint256) {
        uint256 cid = ownerToComposableId[_owner];
        return cid;
    }

    function isUpgradeable(uint256 cid) public returns (bool) {
        // msg.sender is owner of the composable
        // has enough engagement points at tierId = 0
        // has sufficient engagement points at tid-1
        require(balanceOf(msg.sender) == 1);
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

    /// admin would be marketplace

    // >one account can only mint once

    /// @param to addres the SNFT is minted to
    function mint() public virtual {
        // require(
        //     hasRole(MINTER_ROLE, _msgSender()),
        //     "ERC721: must have minter role to mint"
        // );
        require(msg.value == mintCost, "ERC721: must pay the mint cost");
        require(balanceOf(msg.sender) == 0, "ERC721: cannot own same token twice");

        uint256 tokenId = composableCount + 1; //totalSupply()

        require(tokenId <= totalSupply, 'ERC721: minting would cause overflow');
        // require()); // implement safemath

        // // We cannot just use balanceOf to create the new tokenId because tokens
        // // can be burned (destroyed), so we need a separate counter.
        _mint(msg.sender, tokenId);
        ownerToComposableId[msg.sender] = tokenId;
        // ownerToTierId[to] = 0; // level0
        composableCount = tokenId;
        payable(owner).transfer(msg.value);
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

    function changeTotalSupply(uint256 value) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "Unauthorized total supply setter");
        totalSupply = value;
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
