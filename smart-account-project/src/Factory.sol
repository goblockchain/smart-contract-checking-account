// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IFactory.sol";
import "./interfaces/ISmartAccount.sol";
import "./helpers/Errors.sol";

contract Factory is ISAFactory {
    uint256 public number;

    /*╔═════════════════════════════╗
      ║       STATE VARIABLES       ║
      ╚═════════════════════════════╝*/
    /// @inheritdoc ISAFactory
    address[] admins;

    /// @inheritdoc ISAFactory
    mapping(address => bool) admin;
    /// @inheritdoc ISAFactory
    mapping(address => bool) users;

    /// @inheritdoc ISAFactory
    mapping(address => address) smartAccount;
    /// @inheritdoc ISAFactory
    mapping(uint => bool) active;

    enum TokenStandard {
        isERC20, // 0
        isERC721, // 1
        isERC1155 // 2
    }

    // maps a tokenIndex to a tokenStandard
    mapping(uint => uint) tokenIndexToStandard;

    constructor() {}

    /*╔═════════════════════════════╗
      ║        VIEW FUNCTIONS       ║
      ╚═════════════════════════════╝*/

    /// @inheritdoc ISAFactory
    function scores(
        address[] calldata _users
    ) external view returns (int[] memory scores) {
        uint arrLength = _users.length;
        for (uint i; i < arrLength; ) {
            scores[i] = ISmartAccount(smartAccount[_users[i]]).score();
            unchecked {
                ++i;
            }
        }
    }

    function credits(
        address[] calldata _users
    ) external view returns (int[] memory credits) {
        uint arrLength = _users.length;
        for (uint i; i < arrLength; ) {
            // if not a user, revert.
            if (!users[_users[i]]) revert Errors.InvalidUser((_users[i]));
            // if a user, but no smartAccount, revert.
            if (smartAccount[_users[i]] == address(0))
                revert Errors.InvalidUser((_users[i]));
            // if user && smartAccount, get credit.
            credits[i] = ISmartAccount(smartAccount[_users[i]]).credit();
            unchecked {
                ++i;
            }
        }
    }

    /*╔═════════════════════════════╗
      ║      BATCH FUNCTIONS        ║
      ╚═════════════════════════════╝*/

    /// @inheritdoc ISAFactory
    function batchPause(address[] calldata _users) external {
        _isAdmin(msg.sender);
        uint length = _users.length;
        for (uint i; i < length; ) {
            // if not a user, revert.
            if (!users[_users[i]]) revert Errors.InvalidUser((_users[i]));
            // if a user, but no smartAccount, revert.
            if (smartAccount[_users[i]] == address(0))
                revert Errors.InvalidUser((_users[i]));
            // if user && smartAccount, pause.
            ISmartAccount(smartAccount[_users[i]]).pause();
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ISAFactory
    function batchUnpause(address[] calldata _users) external {
        _isAdmin(msg.sender);
        uint length = _users.length;
        for (uint i; i < length; ) {
            // if not a user, revert.
            if (!users[_users[i]]) revert Errors.InvalidUser((_users[i]));
            // if a user, but no smartAccount, revert.
            if (smartAccount[_users[i]] == address(0))
                revert Errors.InvalidUser((_users[i]));
            // if user && smartAccount, pause.
            ISmartAccount(smartAccount[_users[i]]).unpause();
            unchecked {
                ++i;
            }
        }
    }

    function batchUpdate(
        address[] memory _users,
        int[] calldata _liabilities
    ) external {
        _isAdmin(msg.sender);
        uint length = _users.length;
        if (length != _liabilities.length) revert Errors.ArrayLengthMismatch();
        for (uint i; i < length; ) {
            // if not a user, revert.
            if (!users[_users[i]]) revert Errors.InvalidUser((_users[i]));
            // if a user, but no smartAccount, revert.
            if (smartAccount[_users[i]] == address(0))
                revert Errors.InvalidUser((_users[i]));
            // if user && smartAccount, update.
            ISmartAccount(smartAccount[_users[i]]).update(_liabilities[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ISAFactory
    function batchSetSmartAccounts(
        address[] calldata _users,
        address[] calldata _newSmartAccounts
    ) external returns (bool) {
        _isAdmin(msg.sender);

        // effects
        uint length = _users.length;
        for (uint i; i < length; ) {
            // if not a user, revert.
            if (!users[_users[i]]) revert Errors.InvalidUser((_users[i]));
            // if a user, but no smartAccount, revert.
            if (smartAccount[_users[i]] == address(0))
                revert Errors.InvalidUser((_users[i]));
            // if a user && smartAccount, set new one.
            smartAccount[_users[i]] = _newSmartAccounts[i];
            unchecked {
                ++i;
            }
        }

        //TODO: move funds from older to newer smartAccount.
    }

    /*╔═════════════════════════════╗
      ║       ADMIN FUNCTIONS       ║
      ╚═════════════════════════════╝*/

    /// @inheritdoc ISAFactory
    function addAdmin(
        address _admin
    ) external returns (address[] memory newAdmins) {
        _isAdmin(msg.sender);
        admin[_admin] = true;
        admins.push(_admin);
        // external and public functions can't return storage references.
        newAdmins = admins;
    }

    /// @inheritdoc ISAFactory
    /// @dev it works even if there's still one admin.
    function removeAdmin(
        address _admin
    ) external returns (address[] memory newAdmins) {
        _isAdmin(msg.sender);
        if (!admin[_admin]) revert Errors.InvalidCalldata();
        admin[_admin] = false;

        // remove admin from array without making address(0) an admin.
        // find its index
        uint index = _findIndex(_admin);

        // replace its position with last admin
        admins[index] = admins[admins.length - 1];

        // remove duplicate last admin
        admins.pop();

        // external and public functions can't return storage references.
        newAdmins = admins;
    }

    function _findIndex(address _admin) internal returns (uint) {
        uint length = admins.length;
        for (uint i; i < length; ) {
            if (admins[i] == _admin) {
                return i;
            }
            unchecked {
                ++i;
            }
        }
    }

    /*╔═════════════════════════════╗
      ║   ACCESS CONTROL FUNCTIONS  ║
      ╚═════════════════════════════╝*/

    function _isAdmin(address _sender) private {
        if (!admin[_sender]) revert Errors.ForbiddenSender();
    }
}
