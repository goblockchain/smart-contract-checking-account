// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title Storage
 * @author Caio Sá
 * @notice Contract that has all the storage variables used by Factory.
 */

import "./Checks.sol";

contract Storage is Checks {
    uint internal unlocked = 1;

    modifier lock() {
        if (unlocked != 1) revert Errors.Locked();
        unlocked = 0;
        _;
        unlocked = 1;
    }

    /*╔═════════════════════════════╗
      ║       STORAGE VARIABLES     ║
      ╚═════════════════════════════╝*/

    ///@dev finds if some address is an admin.
    mapping(address => bool) internal _admins;

    ///@dev finds if some address is an user.
    mapping(address => bool) internal _users;

    ///@dev finds if smart account address from an user.
    mapping(address => address) internal _smartAccount;

    /*╔═════════════════════════════╗
      ║--------TOKENS TYPES---------║
      ║        IsNothing: 0         ║
      ║        ERC20: 1             ║
      ║        ERC721: 2            ║
      ║        ERC1155: 3           ║
      ╚═════════════════════════════╝*/
    ///@dev maps a token address to a tokenStandard.
    mapping(address => uint) internal _tokensType;

    ///@dev shows whether an erc20 address is allowed as allocation.
    mapping(address => bool) internal _tokensERC20ToAllocate;

    ///@dev shows whether an erc721 address is allowed as allocation.
    mapping(address => bool) internal _tokensERC721ToAllocate;

    ///@dev shows whether an erc1155 address is allowed as allocation.
    mapping(address => bool) internal _tokensERC1155ToAllocate;

    ///@dev maps ERC20 token to percentage from allocation that will be transformed into credit.
    mapping(address => uint) internal _cutForERC20;

    ///@dev maps ERC721 token to percentage from allocation that will be transformed into credit.
    mapping(address => uint) internal _cutForERC721;

    ///@dev maps ERC1155 token to percentage from allocation that will be transformed into credit.
    mapping(address => uint) internal _cutForERC1155;

    /// @dev min amount for certain token.
    mapping(address => uint) internal _minAllocationForERC20Token;

    /// @dev min amount for certain token.
    mapping(address => uint) internal _minAllocationForERC721Token;

    /// @dev min amount for certain token.
    mapping(address => uint) internal _minAllocationForERC1155Token;

    /// @dev enum to store token types.
    enum TokenStandard {
        isNothing, // 0
        isERC20, // 1
        isERC721, // 2
        isERC1155 // 3
    }

    /*╔═════════════════════════════╗
      ║   ACCESS CONTROL FUNCTIONS  ║
      ╚═════════════════════════════╝*/

    function _isAdmin(address _sender) internal {
        if (!_admins[_sender]) revert Errors.ForbiddenSender();
    }
}
