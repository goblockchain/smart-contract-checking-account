// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IFactory.sol";
import "./interfaces/ISmartAccount.sol";
import "./helpers/Errors.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title SmartAccount
 * @author Caio Sá
 * @notice This contract should be as optimized as possible because the company will be deploying it for each user coming in, since it will represent each user's account. However, it should also be understandable for users to perform their own due diligence.
 */

contract SmartAccount is ISmartAccount {
    using SafeERC20 for IERC20;
    ISAFactory factory;

    /*╔═════════════════════════════╗
      ║       STATE VARIABLES       ║
      ╚═════════════════════════════╝*/

    /// @inheritdoc ISmartAccount
    string public name;
    int public credit;
    int public score;
    uint public maxCredit;
    uint public lastUpdatedTimestamp;
    bool public useDefault;

    uint private unlocked = 1;
    bool private paused;

    modifier lock() {
        if (unlocked != 1) revert Errors.Locked();
        unlocked = 0;
        _;
        unlocked = 1;
    }

    /// @dev using this to avoid spending much gas on OZ.Pausable big modifiers.
    modifier stop() {
        if (paused) revert Errors.Paused();
        _;
    }

    constructor(string memory _name) {
        name = _name;
        factory = ISAFactory(msg.sender);
    }

    /*╔═════════════════════════════╗
      ║   ACCESS CONTROL FUNCTIONS  ║
      ╚═════════════════════════════╝*/

    function auth(address account) private {
        if (!factory.admin(account)) revert Errors.ForbiddenSender();
    }

    /*╔═════════════════════════════╗
      ║        VIEW FUNCTIONS       ║
      ╚═════════════════════════════╝*/

    /// @inheritdoc ISmartAccount
    function admin(address account) external view returns (bool) {
        return factory.admin(account);
    }

    function tokenToStandard(address _token) external view returns (uint) {
        return factory.tokenToStandard(_token);
    }

    /*╔═════════════════════════════╗
      ║      ADMIN FUNCTIONS        ║
      ╚═════════════════════════════╝*/

    /// @inheritdoc ISmartAccount
    function pause() external {
        auth(msg.sender);
        paused = true;
    }

    /// @inheritdoc ISmartAccount
    function unpause() external {
        auth(msg.sender);
        paused = false;
    }
}
