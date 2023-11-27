// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IFactory.sol";
import "./interfaces/ISmartAccount.sol";
import "./helpers/Errors.sol";
import "./SmartAccount.sol";
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

    mapping(address => bool) private _admins;

    mapping(address => bool) private _users;

    mapping(address => address) private _smartAccount;

    // maps a tokenIndex to a tokenStandard
    mapping(address => uint) private _tokensType;

    uint private unlocked = 1;

    /*╔═════════════════════════════╗
      ║           EVENTS            ║
      ╚═════════════════════════════╝*/

    event CreditUpdated(
        address user,
        address smartAccount,
        int change,
        int credit
    );

    enum TokenStandard {
        isNothing,
        isERC20, // 1
        isERC721, // 2
        isERC1155 // 3
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
        if (_smartAccount[msg.sender] == address(0))
            revert Errors.NotAUser(msg.sender);
        ISmartAccount(_smartAccount[msg.sender]).update(
            (int256(msg.value / 1 ether) * 1000)
        );

        emit CreditUpdated(
            msg.sender,
            _smartAccount[msg.sender],
            int256(msg.value / 1 ether) * 1000,
            ISmartAccount(_smartAccount[msg.sender]).credit()
        );
    }

    /// @notice the function below as is MUST NOT be used in production. This is only a demo for a presentation
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external lock returns (bytes4) {
        if (_smartAccount[from] == address(0)) revert Errors.NotAUser(from);
        ISmartAccount(_smartAccount[from]).update(1000);
        require(uint(TokenStandard.isERC1155) == 3, "!3");
        _tokensType[msg.sender] = uint(TokenStandard.isERC1155);
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
    ) external lock returns (bytes4) {
        if (_smartAccount[from] == address(0)) revert Errors.NotAUser(from);
        ISmartAccount(_smartAccount[from]).update(1000);
        _tokensType[msg.sender] = uint(TokenStandard.isERC1155);
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
    ) external lock returns (bytes4) {
        if (_smartAccount[from] == address(0)) revert Errors.NotAUser(from);
        _tokensType[msg.sender] = uint(TokenStandard.isERC721);
        require(uint(TokenStandard.isERC721) == 2, "!2");
        ISmartAccount(_smartAccount[from]).update(1000);
        return IERC721Receiver.onERC721Received.selector;
    }

    // constructor() ERC2771Forwarder("Factory") ERC2771Context(address(this)) {
    constructor(address _firstUser, string memory _firstUserName) {
        //   deployer is `admin`
        admins.push(msg.sender);
        _admins[msg.sender] = true;

        // make the factory itself an `admin`
        admins.push(address(this));
        _admins[address(this)] = true;

        _create(_firstUser, _firstUserName);
    }

    /*╔═════════════════════════════╗
      ║        VIEW FUNCTIONS       ║
      ╚═════════════════════════════╝*/

    /// @inheritdoc ISAFactory
    function scores(
        address[] calldata users
    ) external view returns (int[] memory scores) {
        uint arrLength = users.length;
        for (uint i; i < arrLength; ) {
            scores[i] = ISmartAccount(_smartAccount[users[i]]).score();
            unchecked {
                ++i;
            }
        }
    }

    function credits(
        address[] calldata users
    ) external view returns (int[] memory) {
        uint arrLength = users.length;
        int[] memory credits = new int[](arrLength);
        for (uint i; i < arrLength; ) {
            // if not a user, revert.
            if (!_users[users[i]]) revert Errors.InvalidUser((users[i]));
            // if a user, but no smartAccount, revert.
            if (_smartAccount[users[i]] == address(0))
                revert Errors.InvalidUser((users[i]));
            // if user && smartAccount, get credit.
            credits[i] = ISmartAccount(_smartAccount[users[i]]).credit();
            unchecked {
                ++i;
            }
        }
    }

    function smartAccount(address user) external view returns (address) {
        return _smartAccount[user];
    }

    function tokenToStandard(address token) external view returns (uint) {
        if (_tokensType[token] == 0) revert Errors.InvalidToken(token);
        return _tokensType[token];
    }

    function admin(address admin) external view returns (bool) {
        return _admins[admin];
    }

    function user(address user) external view returns (bool) {
        return _users[user];
    }

    /*╔═════════════════════════════╗
      ║      BATCH FUNCTIONS        ║
      ╚═════════════════════════════╝*/

    function batchUpdate(
        address[] memory users,
        int[] calldata _liabilities
    ) external lock {
        _isAdmin(msg.sender);
        uint length = users.length;
        if (length != _liabilities.length) revert Errors.ArrayLengthMismatch();
        for (uint i; i < length; ) {
            // if not a user, revert.
            if (!_users[users[i]]) revert Errors.InvalidUser((users[i]));
            // if a user, but no smartAccount, revert.
            if (_smartAccount[users[i]] == address(0))
                revert Errors.InvalidUser((users[i]));
            // if user && smartAccount, update.
            ISmartAccount(_smartAccount[users[i]]).update(_liabilities[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ISAFactory
    function batchSetSmartAccounts(
        address[] calldata users,
        address[] calldata _newSmartAccounts
    ) external lock returns (bool) {
        _isAdmin(msg.sender);

        // effects
        uint length = users.length;
        for (uint i; i < length; ) {
            // if not a user, revert.
            if (!_users[users[i]]) revert Errors.InvalidUser((users[i]));
            // if a user, but no smartAccount, revert.
            if (_smartAccount[users[i]] == address(0))
                revert Errors.InvalidUser((users[i]));
            // if a user && smartAccount, set new one.
            _smartAccount[users[i]] = _newSmartAccounts[i];
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
        address user,
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
        _admins[_admin] = true;
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
        if (!_admins[_admin]) revert Errors.InvalidCalldata();
        _admins[_admin] = false;

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
        if (!_admins[_sender]) revert Errors.ForbiddenSender();
    }

    /*╔═════════════════════════════╗
      ║     FROM FACTORY FUNCTIONS  ║
      ╚═════════════════════════════╝*/

    /// @dev derive user's address from user's signature (v,r,s).
    function create(
        address _user,
        string calldata _username
    ) external lock returns (address user, address smartAccount) {
        _isAdmin(msg.sender);
        return (_user, _create(_user, _username));
    }

    function registerSelf(
        string calldata userName
    ) external returns (address smartUserAccount) {
        if (_users[msg.sender]) revert Errors.InvalidUser(msg.sender);
        smartUserAccount = _create(msg.sender, userName);
        _users[msg.sender] = true;
        _smartAccount[msg.sender] = smartUserAccount;
    }

    function _create(
        address user,
        string memory _name
    ) private returns (address) {
        // deploy SmartAccount here.
        _smartAccount[user] = address(
            new SmartAccount{salt: keccak256(abi.encode(user))}(_name)
        );
        _users[user] = true;
        return _smartAccount[user];
    }

    function move(
        address _token,
        address _to,
        uint _id
    ) external override returns (bool) {
        _isAdmin(msg.sender);
        if (_token == address(0)) {
            (bool done, ) = _to.call{value: address(this).balance}("");
            if (!done) revert Errors.UnableToMove();
            return true;
        }
    }

    function deactivate(
        uint userId,
        bool refund
    ) external override returns (bool) {}

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
