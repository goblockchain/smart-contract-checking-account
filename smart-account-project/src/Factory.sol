// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IFactory.sol";
import "./interfaces/ISmartAccount.sol";
import "./helpers/TransferHelper.sol";
import {SmartAccount} from "./SmartAccount.sol";
import {AllowERC1155} from "./AllowERC1155.sol";
import {AllowERC721} from "./AllowERC721.sol";
import {Errors} from "./helpers/Errors.sol";

/**
 * @title Factory
 * @author Caio Sá
 * @notice This is the contract responsible for managing and creating the SmartAccount contracts.
 */

/**
 * TODO: Check contract order in inheritance on `Allows` contracts.
 * TODO: Check whether allowed allocation tokens should include payment tokens as well.
 * TODO: Emit events.
 * TODO: Parametrize everything.
 * TODO: Fuzz test percentages to avoid mistakes.
 */

contract Factory is AllowERC1155, AllowERC721, ISAFactory {
    /*╔═════════════════════════════╗
      ║         ENUM/EVENTS         ║
      ╚═════════════════════════════╝*/

    event CreditUpdated(
        address user,
        address smartAccount,
        int change,
        int credit
    );

    /*╔═════════════════════════════╗
      ║      CALLBACK FUNCTIONS     ║
      ╚═════════════════════════════╝*/
    receive() external payable {
        /// @dev Native crypto (ETH/MATIC) are NOT stablecoins. This, for sure, could be used as a payment method, but it's better for an user to `swap` his native for an allowed payment token on a DEX and then pay using his tokens - since we have control over that as the price does NOT fluctuates considerably.
        revert Errors.ReceivedNative();
    }

    /// @notice it's marked as payable to gas-optimize deploy.
    constructor(
        address[] memory admins,
        address[] memory _tokens,
        uint[] memory _types,
        uint[] memory _min,
        uint[] memory _cuts
    ) payable {
        // check.
        uint adminsLength = admins.length;

        // check all arrays related to tokens have the same length && cache their length.
        uint tokensLength = _tokens.length == _types.length &&
            _types.length == _min.length &&
            _min.length == _cuts.length
            ? _tokens.length
            : 0;

        // if not of the same length || arrays are empty, revert.
        if (tokensLength == 0) revert Errors.ArrayLengthMismatch();

        // set admins.
        _admins[msg.sender] = true;
        /// @dev this avoids errors when factory calls SA.
        _admins[address(this)] = true;
        for (uint i; i < adminsLength; ) {
            _setAdmin(admins[i]);
            unchecked {
                ++i;
            }
        }

        // set allowed ERC20 tokens.
        for (uint i; i < tokensLength; ) {
            if (_types[i] == uint(TokenStandard.isERC20))
                _setAllowedERC20Token(_tokens[i], true);
            if (_types[i] == uint(TokenStandard.isERC721))
                _setAllowedERC721Token(_tokens[i], true);
            if (_types[i] == uint(TokenStandard.isERC1155))
                _setAllowedERC1155Tokens(_tokens[i], true);
            unchecked {
                ++i;
            }
        }

        // set minimum allocation.
        for (uint i; i < tokensLength; ) {
            if (_types[i] == uint(TokenStandard.isERC20))
                _setMinAllocationForToken(_tokens[i], _types[i], _min[i]);
            if (_types[i] == uint(TokenStandard.isERC721))
                _setMinAllocationForToken(_tokens[i], _types[i], _min[i]);
            if (_types[i] == uint(TokenStandard.isERC1155))
                _setMinAllocationForToken(_tokens[i], _types[i], _min[i]);
            unchecked {
                ++i;
            }
        }

        // set cut from each allocation that will be turned into credit.
        for (uint i; i < tokensLength; ) {
            if (_types[i] == uint(TokenStandard.isERC20))
                _setCutForToken(_tokens[i], _types[i], _cuts[i]);
            if (_types[i] == uint(TokenStandard.isERC721))
                _setCutForToken(_tokens[i], _types[i], _cuts[i]);
            if (_types[i] == uint(TokenStandard.isERC1155))
                _setCutForToken(_tokens[i], _types[i], _cuts[i]);
            unchecked {
                ++i;
            }
        }
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
            revertIfZeroAddress(_smartAccount[users[i]]);
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

    function tokensERC721AllowedAsAllocation(
        address token
    ) external view returns (bool) {
        return _tokensERC721ToAllocate[token];
    }

    function tokensERC1155AllowedAsAllocation(
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
            revertIfZeroAddress(users[i]);
            // if not a user
            if (!_users[users[i]]) revert Errors.InvalidUser(users[i]);
            // if no smart account for user, revert.
            revertIfZeroAddress(_smartAccount[users[i]]);
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

    function setCutForTokens(
        address[] calldata tokenAddresses,
        uint[] calldata tokenTypes,
        uint[] calldata cuts
    ) external {
        _isAdmin(msg.sender);
        uint length = tokenAddresses.length;
        if (length != tokenTypes.length) revert Errors.ArrayLengthMismatch();
        if (tokenTypes.length != cuts.length)
            revert Errors.ArrayLengthMismatch();

        for (uint i; i < length; ) {
            revertIfZeroAddress(tokenAddresses[i]);
            // check type's correct.
            if (
                _tokensType[tokenAddresses[i]] != tokenTypes[i] ||
                tokenTypes[i] == uint(TokenStandard.isNothing)
            ) revert Errors.InvalidTokenType(tokenAddresses[i]);
            // set min allocation for token.
            _setCutForToken(tokenAddresses[i], tokenTypes[i], cuts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _setCutForToken(address token, uint _type, uint cut) internal {
        if (_type == uint(TokenStandard.isERC20)) _cutForERC20[token] = cut;
        if (_type == uint(TokenStandard.isERC721)) _cutForERC721[token] = cut;
        if (_type == uint(TokenStandard.isERC1155)) _cutForERC1155[token] = cut;
    }

    function setMinimumAllocationForTokens(
        address[] calldata tokenAddresses,
        uint[] calldata tokenTypes,
        uint[] calldata minAllocations
    ) external {
        _isAdmin(msg.sender);
        uint length = tokenAddresses.length;
        if (length != tokenTypes.length) revert Errors.ArrayLengthMismatch();
        if (tokenTypes.length != minAllocations.length)
            revert Errors.ArrayLengthMismatch();

        for (uint i; i < length; ) {
            // check type's correct.
            if (
                _tokensType[tokenAddresses[i]] != tokenTypes[i] ||
                tokenTypes[i] != uint(TokenStandard.isNothing)
            ) revert Errors.InvalidTokenType(tokenAddresses[i]);
            // set min allocation for token.
            _setMinAllocationForToken(
                tokenAddresses[i],
                tokenTypes[i],
                minAllocations[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    function _setMinAllocationForToken(
        address token,
        uint _type,
        uint minAmount
    ) internal {
        revertIfZeroAddress(token);
        if (_type == uint(TokenStandard.isERC20))
            _minAllocationForERC20Token[token] = minAmount;
        if (_type == uint(TokenStandard.isERC721))
            _minAllocationForERC721Token[token] = minAmount;
        if (_type == uint(TokenStandard.isERC1155))
            _minAllocationForERC1155Token[token] = minAmount;
    }

    function setAllowedERC20Tokens(
        address[] calldata tokenAddresses,
        bool[] calldata allow
    ) external returns (bool) {
        _isAdmin(msg.sender);
        uint length = tokenAddresses.length;
        if (length != allow.length) revert Errors.ArrayLengthMismatch();
        for (uint i; i < length; ) {
            /// @dev below reverts if token is zero address.
            _setAllowedERC20Token(tokenAddresses[i], allow[i]);
            unchecked {
                ++i;
            }
        }
        // if it reaches to this stage, everything has gone well. Otherwise, it's been reverted.
        return true;
    }

    function _setAllowedERC20Token(address token, bool allow) internal {
        revertIfZeroAddress(token);
        _tokensERC20ToAllocate[token] = allow;
        if (allow) _tokensType[token] == uint(TokenStandard.isERC20);
        if (!allow) _tokensType[token] == uint(TokenStandard.isNothing);
    }

    function setAllowedERC721Tokens(
        address[] calldata tokenAddresses,
        bool[] calldata allow
    ) external returns (bool) {
        _isAdmin(msg.sender);
        uint length = tokenAddresses.length;
        if (length != allow.length) revert Errors.ArrayLengthMismatch();
        for (uint i; i < length; ) {
            /// @dev below reverts if token is zero address.
            _setAllowedERC721Token(tokenAddresses[i], allow[i]);
            unchecked {
                ++i;
            }
        }
        return true;
    }

    function _setAllowedERC721Token(address token, bool allow) internal {
        revertIfZeroAddress(token);
        _tokensERC721ToAllocate[token] = allow;
        if (allow) _tokensType[token] == uint(TokenStandard.isERC721);
        if (!allow) _tokensType[token] == uint(TokenStandard.isNothing);
    }

    function setAllowedERC1155Tokens(
        address[] calldata tokenAddresses,
        bool[] calldata allow
    ) external returns (bool) {
        _isAdmin(msg.sender);
        uint length = tokenAddresses.length;
        if (length != allow.length) revert Errors.ArrayLengthMismatch();
        for (uint i; i < length; ) {
            /// @dev below reverts if token is zero address.
            _setAllowedERC1155Tokens(tokenAddresses[i], allow[i]);
            unchecked {
                ++i;
            }
        }
        return true;
    }

    function _setAllowedERC1155Tokens(address token, bool allow) internal {
        revertIfZeroAddress(token);
        _tokensERC1155ToAllocate[token] = allow;
        if (allow) _tokensType[token] == uint(TokenStandard.isERC1155);
        if (!allow) _tokensType[token] == uint(TokenStandard.isNothing);
    }

    function setSmartAccounts(
        address[] calldata users,
        address[] calldata smartAccounts
    ) external returns (bool) {
        _isAdmin(msg.sender);
        uint length = users.length;
        if (length != smartAccounts.length) revert Errors.ArrayLengthMismatch();
        for (uint i; i < length; ) {
            revertIfZeroAddress(users[i]);
            revertIfZeroAddress(smartAccounts[i]);
            // if not a user
            if (!_users[users[i]]) revert Errors.InvalidUser(users[i]);
            // if no smart account for user, revert.
            revertIfZeroAddress(_smartAccount[users[i]]);
            _setSmartAccount(users[i], smartAccounts[i]);
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

    function setAdmins(address[] calldata admins) external lock returns (bool) {
        _isAdmin(msg.sender);
        uint length = admins.length;
        for (uint i; i < length; ) {
            revertIfZeroAddress(admins[i]);
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
}
