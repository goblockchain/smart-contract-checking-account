// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IFactory.sol";
import "./interfaces/ISmartAccount.sol";
import "./helpers/Errors.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

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
    uint public lastUpdatedAt;
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

    // TODO: complexity is too big. Remember: modularity
    /*
    function init(
        uint userId,
        string calldata user,
        address[] calldata admins,
        uint minAllocation,
        bool acceptsERC20Tokens,
        address[] calldata sortedPermittedERC20Tokens,
        bool acceptsERC721Tokens,
        address[] calldata sortedPermittedERC721Tokens,
        bool acceptsERC1155Tokens,
        address[] calldata sortedPermittedERC1155Tokens,
        uint percentageFromAllocation,
        address[] calldata paymentTokens
    ) external override returns (bool) {}
    */

    function allocate(uint256 tokenIndex, uint256 amount) external {}

    function allocateDelegate(
        uint256 tokenIndex,
        uint256 amount,
        address to
    ) external override {}

    function allocateWithPermit(
        uint256 tokenIndex,
        uint256 amount,
        uint256 deadline,
        bool includesNonce,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {}

    function batchAllocateWithPermit(
        uint256[] calldata tokenIndexes,
        uint256[] calldata amounts,
        uint256[] calldata deadlines,
        bool[] calldata includesNonce,
        uint256[] calldata nonces,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) external override {}

    function update(int amount) external returns (int) {
        if (amount > 0) credit += amount;
        if (amount < 0) credit -= amount; //int does not underflow
        lastUpdatedAt = block.timestamp;
        return credit;
    }

    function cease(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory data
    ) external override {}

    function skim(address token, address to) external override returns (bool) {}

    function setPaymentTokens(
        address paymentTokens,
        uint tokenType
    ) external override returns (address[] memory newPaymentTokens) {}

    function setPermittedERC20Tokens(
        address tokenAddress
    ) external override returns (address[] memory newPermittedERC20Tokens) {}

    function setPermittedERC721Tokens(
        address tokenAddress
    ) external override returns (address[] memory newPermittedERC721Tokens) {}

    function setPermittedERC1155Tokens(
        address tokenAddress
    ) external override returns (address[] memory) {}

    function setPercentageFromAllocation(
        uint percentageFromAllocation
    ) external override returns (uint newPercentageFromAllocation) {}

    function setUseDefault(bool _useDefault) external override returns (bool) {
        useDefault = _useDefault;
    }
}
