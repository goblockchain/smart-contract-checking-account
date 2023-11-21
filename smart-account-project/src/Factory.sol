// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IFactory.sol";
import "./interfaces/ISmartAccount.sol";
import "./helpers/Errors.sol";
import "./SmartAccount.sol";

/**
 * @title Factory
 * @author Caio Sá
 * @notice This is the contract responsible for managing and creating the SmartAccount contracts.
 */

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
    mapping(address => uint) tokenToStandard;

    uint private unlocked = 1;

    modifier lock() {
        if (unlocked != 1) revert Errors.Locked();
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() {
        // make the factory itself an `admin`
        admins.push(address(this));
        admin[address(this)] = true;
    }

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
    function batchPause(address[] calldata _users) external lock {
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
    function batchUnpause(address[] calldata _users) external lock {
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
    ) external lock {
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
    ) external lock returns (bool) {
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
    ) external lock returns (address[] memory newAdmins) {
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
    ) external lock returns (address[] memory newAdmins) {
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

    /*╔═════════════════════════════╗
      ║     FROM FACTORY FUNCTIONS  ║
      ╚═════════════════════════════╝*/

    /// @dev derive user's address from user's signature (v,r,s).
    function create(
        string calldata _user,
        address[] calldata admins,
        uint minAllocation,
        bool acceptERC20Tokens,
        address[] calldata permittedERC20Tokens,
        bool acceptERC721Tokens,
        address[] calldata permittedERC721Tokens,
        bool acceptERC1155Tokens,
        address[] calldata permittedERC1155Tokens,
        uint percentageFromAllocation,
        address[] calldata paymentTokens,
        bool includesNonce, // some tokens, like DAI seem to have a nonce in their permit functions.
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool useDefault
    ) external lock returns (address user, address smartAccount) {
        if (useDefault) {
            _create(_user, includesNonce, nonce, v, r, s);
        } else {
            // use custom values
            // deploy user's SmartAccount from here.
        }
    }

    function _create(
        string calldata _user,
        bool hasNonce,
        uint nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private {
        // use default values
        // deploy SmartAccount from here.
    }
}
