// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IFactory.sol";
import "./interfaces/ISmartAccount.sol";
import "./helpers/Errors.sol";
import "./SmartAccount.sol";
import "../lib/openzeppelin-contracts/contracts/metatx/ERC2771Forwarder.sol";
import "../lib/openzeppelin-contracts/contracts/metatx/ERC2771Context.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title Factory
 * @author Caio Sá
 * @notice This is the contract responsible for managing and creating the SmartAccount contracts.
 */

// contract Factory is ISAFactory, ERC2771Forwarder, ERC2771Context {
contract Factory is ISAFactory, IERC721Receiver, IERC1155Receiver {
    /*╔═════════════════════════════╗
      ║       STATE VARIABLES       ║
      ╚═════════════════════════════╝*/
    address[] public admins;

    /// @inheritdoc ISAFactory
    mapping(address => bool) public admin;
    /// @inheritdoc ISAFactory
    mapping(address => bool) public users;

    /// @inheritdoc ISAFactory
    mapping(address => address) public smartAccount;

    // maps a tokenIndex to a tokenStandard
    mapping(address => uint) public tokenToStandard;

    uint private unlocked = 1;

    enum TokenStandard {
        isERC20, // 0
        isERC721, // 1
        isERC1155 // 2
    }

    modifier lock() {
        if (unlocked != 1) revert Errors.Locked();
        unlocked = 0;
        _;
        unlocked = 1;
    }

    /*╔═════════════════════════════╗
      ║      CALLBACK FUNCTIONS     ║
      ╚═════════════════════════════╝*/
    receive() external payable {
        ISmartAccount(smartAccount[msg.sender]).update(
            (int256(msg.value / 1 ether) * 1000)
        );
    }

    /// @notice the function below as is MUST NOT be used in production. This is only a demo for a presentation
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        ISmartAccount(smartAccount[from]).update(1000);
        require(uint(TokenStandard.isERC1155) == 2, "!2");
        tokenToStandard[msg.sender] = uint(TokenStandard.isERC1155);
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        ISmartAccount(smartAccount[from]).update(1000);
        tokenToStandard[msg.sender] = uint(TokenStandard.isERC1155);
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    /// @notice the function below as is MUST NOT be used in production. This is only a demo for a presentation
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        tokenToStandard[msg.sender] = uint(TokenStandard.isERC721);
        require(uint(TokenStandard.isERC721) == 1, "!1");
        ISmartAccount(smartAccount[from]).update(1000);
        return IERC721Receiver.onERC721Received.selector;
    }

    // constructor() ERC2771Forwarder("Factory") ERC2771Context(address(this)) {
    constructor(address _firstUser, string memory _firstUserName) {
        //   deployer is `admin`
        admins.push(msg.sender);
        admin[msg.sender] = true;

        // make the factory itself an `admin`
        admins.push(address(this));
        admin[address(this)] = true;

        _create(_firstUser, _firstUserName);
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
      ║        SET FUNCTIONS        ║
      ╚═════════════════════════════╝*/

    function setMinAllocation(
        uint userId,
        uint minAllocation
    ) external returns (uint newMinAllocation) {}

    function setPermittedERC20Tokens(
        address tokenAddress
    ) external returns (address[] memory newPermittedERC20Tokens) {}

    function setPermittedERC721Tokens(
        address tokenAddress
    ) external returns (address[] memory newPermittedERC721Tokens) {}

    function setPermittedERC1155Tokens(
        address tokenAddress
    ) external returns (address[] memory) {}

    function setPercentageFromAllocation(
        uint percentageFromAllocation
    ) external returns (uint newPercentageFromAllocation) {}

    function setPaymentTokens(
        address paymentTokens,
        uint tokenType
    ) external returns (address[] memory newPaymentTokens) {}

    function setSmartAccount(
        uint userId,
        address newSmartAccount
    ) external returns (bool) {}

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

    function punish(uint[] calldata usersIds, int amounts) external {}

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
        address _user,
        string calldata _username,
        uint minAllocation,
        bool acceptERC20Tokens,
        address[] calldata permittedERC20Tokens,
        bool acceptERC721Tokens,
        address[] calldata permittedERC721Tokens,
        bool acceptERC1155Tokens,
        address[] calldata permittedERC1155Tokens,
        uint percentageFromAllocation,
        address[] calldata paymentTokens
    ) external lock returns (address user, address smartAccount) {
        return (_user, _create(_user, _username));
    }

    function _create(
        address _user,
        string calldata _name
    ) private returns (address) {
        // deploy SmartAccount here.
        smartAccount[_user] = address(
            new SmartAccount{salt: keccak256(abi.encode(_user))}(_name)
        );
        users[_user] = true;
        return smartAccount[_user];
    }

    function move(
        address _token,
        address _to,
        uint _id
    ) external override returns (bool) {
        _isAdmin(msg.sender);
        if (_token == address(0)) _to.call{value: address(this).balance}("");
    }

    function deactivate(
        uint userId,
        bool refund
    ) external override returns (bool) {}

    function batchSetSmartAccounts(
        uint[] calldata _users,
        address[] calldata _newSmartAccounts
    ) external returns (bool) {}

    function create(
        string calldata user,
        uint minAllocation,
        bool acceptERC20Tokens,
        address[] calldata permittedERC20Tokens,
        bool acceptERC721Tokens,
        address[] calldata permittedERC721Tokens,
        bool acceptERC1155Tokens,
        address[] calldata permittedERC1155Tokens,
        uint percentageFromAllocation,
        address[] calldata paymentTokens,
        bool includesNonce,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool useDefault
    ) external override returns (address _user, address smartAccount) {}
}
