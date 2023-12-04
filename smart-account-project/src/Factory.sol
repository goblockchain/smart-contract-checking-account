// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IFactory.sol";
import "./interfaces/ISmartAccount.sol";
import "./helpers/Errors.sol";
import "./helpers/TransferHelper.sol";
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

    uint256 constant MAX_ADMINS = 15;

    mapping(address => bool) private _admins;

    mapping(address => bool) private _users;

    mapping(address => address) private _smartAccount;

    ///@dev maps a tokenIndex to a tokenStandard
    mapping(address => uint) private _tokensType;

    mapping(address => bool) private _tokensERC20ToAllocate;
    mapping(address => bool) private _tokensERC721ToAllocate;
    mapping(address => bool) private _tokensERC1155ToAllocate;

    ///@dev maps token to percentage from allocation that will be transformed into credit.
    mapping(address => uint) private cutForERC20;
    mapping(address => uint) private cutForERC721;
    mapping(address => uint) private cutForERC1155;

    uint public minimumAllocation;
    uint public percentageFromAllocation;

    uint private unlocked = 1;

    /*╔═════════════════════════════╗
      ║         ENUM/EVENTS         ║
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
        /// @dev Native crypto (ETH/MATIC) are NOT stablecoins. This, for sure, could be used as a payment method, but it's better for an user to `swap` his native for an allowed payment token on a DEX and then pay using his tokens - since we have control over that as the price does NOT fluctuates considerably.
        revert Errors.ReceivedNative();
    }

    /// @notice the function below as is MUST NOT be used in production. This is only a demo for a presentation
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external lock returns (bytes4) {
        // NOTE: This is not yet safe. A malicious `msg.sender` can call this function with a registered `from` address, etc.
        // if (_smartAccount[from] == address(0)) revert Errors.NotAUser(from);
        require(_tokensType[msg.sender] == uint(TokenStandard.isERC1155), "!3");
        revertIfZeroAddress(_smartAccount[from]);
        if (!_users[from]) revert Errors.InvalidUser(from);

        ISmartAccount(_smartAccount[from]).update(1000);
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
        // NOTE: This is not yet safe. A malicious `msg.sender` can call this function with a registered `from` address, etc.
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
        // NOTE: This is not yet safe. A malicious `msg.sender` can call this function with a registered `from` address, etc.
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
        /// @dev this avoids errors when factory calls SA.
        admins.push(address(this));
        _admins[address(this)] = true;

        _create(_firstUser, _firstUserName);
    }

    /*╔═════════════════════════════╗
      ║        VIEW FUNCTIONS       ║
      ╚═════════════════════════════╝*/

    function version() external pure returns (string memory) {
        return "v0";
    }

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
        return credits;
    }

    function smartAccount(address user) external view returns (address) {
        return _smartAccount[user];
    }

    function tokenToStandard(address token) external view returns (uint) {
        if (_tokensType[token] == 0) revert Errors.InvalidToken(token);
        return _tokensType[token];
    }

    function tokensERC20AllowedAsAllocation(
        address token
    ) external view returns (bool) {
        return _tokensERC20ToAllocate[token];
    }

    function tokensERC20AllowedAsAllocation(
        address token
    ) external view returns (bool) {
        return _tokensERC721ToAllocate[token];
    }

    function tokensERC20AllowedAsAllocation(
        address token
    ) external view returns (bool) {
        return _tokensERC1155ToAllocate[token];
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

    function adminUpdate(
        address[] memory users,
        int[] calldata _liabilities
    ) external lock {
        _isAdmin(msg.sender);
        uint length = users.length;
        if (length != _liabilities.length) revert Errors.ArrayLengthMismatch();
        for (uint i; i < length; ) {
            revertifZeroAddress(users[i]);
            // if not a user
            if (!_users[users[i]]) revert Errors.InvalidUser(users[i]);
            // if no smart account for user, revert.
            revertifZeroAddress(_smartAccount[users[i]]);
            ISmartAccount(_smartAccount[users[i]]).update(_liabilities[i]);
            unchecked {
                ++i;
            }
        }
    }

    /*╔═════════════════════════════╗
      ║        SET FUNCTIONS        ║
      ╚═════════════════════════════╝*/
    ///@dev Have external functions as entrypoint, but logic inside internal functions.
    function setMinAllocation(uint minAllocation) external returns (uint) {
        _admin(msg.sender);
        _setMinAllocation(minAllocation);
        return minimumAllocation;
    }

    function _setMinAllocation(uint minAllocation) internal {
        minimumAllocation = minAllocation;
    }

    function setAllowedERC20Tokens(
        address[] calldata tokenAddresses,
        bool[] calldata allow
    ) external returns (bool) {
        _admin(msg.sender);
        uint length = tokenAddresses.length;
        if (length != allow.length) revert Errors.ArrayLengthMismatch();
        for (uint i; i < length; ) {
            _setAllowedERC20Token(tokenAddresses[i], allow[i]);
            unchecked {
                ++i;
            }
        }
        // if it reaches to this stage, everything has gone well. Otherwise, it's been reverted.
        return true;
    }

    function _setAllowedERC20Token(address token, bool allow) internal {
        revertifZeroAddress(token);
        _tokensERC20ToAllocate[token] = allow;
        if (allow) _tokensType[_token] == uint(TokenStandard.isERC20);
        if (!allow) _tokensType[_token] == uint(TokenStandard.isNothing);
    }

    function setAllowedERC721Tokens(
        address[] tokenAddresses,
        bool[] calldata allow
    ) external returns (bool) {
        _admin(msg.sender);
        uint length = tokenAddresses.length;
        if (length != allow.length) revert Errors.ArrayLengthMismatch();
        for (uint i; i < length; ) {
            _setAllowedERC721Token(tokenAddresses[i], allow[i]);
            unchecked {
                ++i;
            }
        }
        return true;
    }

    function _setAllowedERC721Token(address token, bool allow) internal {
        revertifZeroAddress(token);
        _tokensERC721ToAllocate[token] = allow;
        if (allow) _tokensType[_token] == uint(TokenStandard.isERC721);
        if (!allow) _tokensType[_token] == uint(TokenStandard.isNothing);
    }

    function setAllowedERC1155Tokens(
        address[] calldata tokenAddresses,
        bool[] calldata allow
    ) external returns (bool) {
        _admin(msg.sender);
        uint length = tokenAddresses.length;
        if (length != allow.length) revert Errors.ArrayLengthMismatch();
        for (uint i; i < length; ) {
            _setAllowedERC1155Tokens(tokenAddresses[i], allow[i]);
            unchecked {
                ++i;
            }
        }
        return true;
    }

    function _setAllowedERC1155Tokens(address token, bool allow) internal {
        revertifZeroAddress(token);
        _tokensERC1155ToAllocate[token] = allow;
        if (allow) _tokensType[_token] == uint(TokenStandard.isERC1155);
        if (!allow) _tokensType[_token] == uint(TokenStandard.isNothing);
    }

    function setCutFromAllocationForTokens(
        address[] calldata tokens,
        uint[] calldata percentages
    ) external returns (bool) {
        _isAdmin(msg.sender);
        uint length = tokens.length;
        if (length != percentages.length) revert Errors.ArrayLengthMismatch();
        for (uint i; length; ) {
            revertIfZeroAddress(tokens[i]);
            // check token's registered
            if (_tokensType[tokens[i]] == uint(TokenStandard.isNothing))
                revert Errors.InvalidToken(tokens[i]);
            /// @dev if percentage is 0, then token will not be accepted for allocations to avoid mistaken allocations.
            _setCutForToken(tokens[i], percentages);
            unchecked {
                ++i;
            }
        }
        return true;
    }

    function _setCutForToken(address token, uint percentage) internal {
        if (_tokensType[tokens[i]] == uint(TokenStandard.isERC20))
            cutForERC20[token] = percentage;
        if (_tokensType[tokens[i]] == uint(TokenStandard.isERC721))
            cutForERC721[token] = percentage;
        if (_tokensType[tokens[i]] == uint(TokenStandard.isERC1155))
            cutForERC1155[token] = percentage;
    }

    function _setPercentageFromAllocation(uint percentage) internal {
        percentageFromAllocation = percentage;
    }

    /**
     * TODO: think whether the allowed to deposit should be the same as the allowed to pay in.

    function setPaymentTokens(
        address paymentTokens,
        uint tokenType
    ) external returns (address[] memory newPaymentTokens) {}
     */

    function setSmartAccounts(
        address[] calldata users,
        address[] calldata smartAccounts
    ) external returns (bool) {
        _isAdmin(msg.sender);
        uint length = users.length;
        if (length != smartAccounts.length) revert Errors.ArrayLengthMismatch();
        for (uint i; i < length; ) {
            revertifZeroAddress(users[i]);
            revertifZeroAddress(smartAccounts[i]);
            // if not a user
            if (!_users[users[i]]) revert Errors.InvalidUser(users[i]);
            // if no smart account for user, revert.
            revertifZeroAddress(_smartAccount[users[i]]);
            _setSmartAccount(user[i], smartAccounts[i]);
            unchecked {
                ++i;
            }
        }
        return true;
    }

    function _setSmartAccount(address user, address smartAccount) internal {
        _smartAccount[user] = smartAccount;
    }

    /*╔═════════════════════════════╗
      ║       ADMIN FUNCTIONS       ║
      ╚═════════════════════════════╝*/

    /// @inheritdoc ISAFactory
    function setAdmins(address[] calldata admins) external lock returns (bool) {
        _isAdmin(msg.sender);
        uint length = admins.length;
        for (uint i; i < length; ) {
            revertifZeroAddress(admins[i]);
            _setAdmin(admins[i]);
            unchecked {
                ++i;
            }
        }

        // TODO: emit an event
    }

    function _setAdmin(address admin) internal {
        _admins[admin] = true;
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

    function registerTokens(
        address[] calldata _tokens,
        uint256[] calldata _types
    ) external returns (bool) {
        _isAdmin(msg.sender);
        uint length = _tokens.length;
        if (length != _types.length) revert Errors.ArrayLengthMismatch();
        for (uint i; i < length; ) {
            /// @dev below reverts if _types[i] > 3.
            revertIfZeroAddress(_tokens[i]);
            _registerToken(_tokens[i], _types[i]);
            unchecked {
                ++i;
            }
        }
        return true;
    }

    function _registerToken(address token, uint _type) internal {
        _tokensType[token] = uint(TokenStandard(_type));
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

    // TODO: apply `lock` modifier.
    function move(
        address _token,
        address _to,
        uint _id,
        uint _amount
    ) external lock returns (bool) {
        _isAdmin(msg.sender);
        if (_token == address(0)) {
            TransferHelper.safeTransferETH(_to, address(this).balance);
        } else if (_tokensType[_token] == uint(TokenStandard.isERC20)) {
            moveERC20(_token, _to, _amount);
        } else if (_tokensType[_token] == uint(TokenStandard.isERC721)) {
            moveERC721(_token, _to, _id);
        } else {
            if (_tokensType[_token] != uint(TokenStandard.isERC1155))
                revert Errors.InvalidToken(_token);
            moveERC1155(_token, _to, _id, _amount);
        }
        return true;
    }

    /*╔═════════════════════════════╗
      ║        CHECK FUNCTIONS      ║
      ╚═════════════════════════════╝*/

    function ifZeroRevert(uint amount) private {
        if (amount == 0) revert Errors.AmountIsZero();
    }

    function revertifZeroAddress(address token) private {
        if (token == address(0)) revert Errors.AddressIsZero();
    }

    /*╔═════════════════════════════╗
      ║    INTERNAL MOVE FUNCTIONS  ║
      ╚═════════════════════════════╝*/

    function moveERC20(address _token, address _to, uint256 _amount) private {
        TransferHelper.safeTransfer(_token, _to, _amount);
    }

    function moveERC721(address _token, address _to, uint256 _id) private {
        TransferHelper.safeTransferERC721From(_token, address(this), _to, _id);
    }

    function moveERC1155(
        address _token,
        address _to,
        uint256 _id,
        uint256 _amount
    ) private {
        TransferHelper.safeTransferERC1155From(
            _token,
            address(this),
            _to,
            _id,
            _amount
        );
    }

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
