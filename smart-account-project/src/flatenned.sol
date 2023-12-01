// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title ISAFactory
 * @author goBlockchain
 * @notice All these functions are to be called by admins only. This interface represents the functions in the Factory contract, which in turn represent the company. Each company will have a factory contract, generator of the Smart Account contract. The flow is as follows: 1) The company's admins call the Factory.someFunction() and this function calls the smartAccount. The smartAccount is then updated accordingly.
 */

interface ISAFactory {
    /*╔═════════════════════════════╗
      ║      ADMIN FUNCTIONS        ║
      ╚═════════════════════════════╝*/

    function addAdmin(
        address _admin
    ) external returns (address[] memory newAdmins);

    function removeAdmin(
        address _admin
    ) external returns (address[] memory newAdmins);

    /// @notice withdraws any tokens directly transferred to this contract or to any SA contract by accident. If token to be withdrawn is the zero address, withdraw ether from contract.
    /// @param _token token to be withdrawn.
    /// @param _to to whom it should be given to, possibly being the user who sent it by accident.
    /// @param _id id of token if it's an NFT.
    /// @param _amount amount of token, if applicable.
    function move(
        address _token,
        address _to,
        uint _id,
        uint _amount
    ) external returns (bool);

    /// @notice it registers a token in case the token does not trigger a callback, like ERC20 tokens do not do.
    /// @param _tokens tokens addressess to be registered.
    /// @param _types token types that will represent the token.abi
    /// @dev _types must be 1 for ERC20, 2 for ERC721 and 3 for ERC1155
    function registerTokens(
        address[] calldata _tokens,
        uint256[] calldata _types
    ) external returns (bool);

    /// @notice Marks user as inactive and pauses Smart Account user's contract. Refunds should be given to users, if any. Callable by goBlockchain only.
    /// @param userId ID of user to inactivate.
    function deactivate(uint userId, bool refund) external returns (bool);

    /*╔═════════════════════════════╗
      ║        SET FUNCTIONS        ║
      ╚═════════════════════════════╝*/

    /// @notice it sets the minAllocation for a certain user. If userId == 0, then it sets the minAllocation for all future users.
    /// @param userId the user for which the minAllocation will change. If 0, change in factory, and ,therefore, for all future users.
    /// @param minAllocation min quantity of tokens the user will have to allocate in the Smart Account.
    function setMinAllocation(
        uint userId,
        uint minAllocation
    ) external returns (uint newMinAllocation);

    /// @notice callable by factory's admin. Registers a new token, making it possible for it to be used as an paymentMethod. Sorting should be handled inside this function and other tokens should be reorganized in their tokenIndexes. TokenType is also handled here: whether it's a erc20 (0), erc721(1) or erc1155(2).
    function setPermittedERC20Tokens(
        address tokenAddress
    ) external returns (address[] memory newPermittedERC20Tokens);

    /// @notice callable by factory's admin. Registers a new token, making it possible for it to be used as an paymentMethod. Sorting should be handled inside this function and other tokens should be reorganized in their tokenIndexes. TokenType is also handled here: whether it's a erc20 (0), erc721(1) or erc1155(2).
    function setPermittedERC721Tokens(
        address tokenAddress
    ) external returns (address[] memory newPermittedERC721Tokens);

    /// @notice callable by factory's admin. Registers a new token, making it possible for it to be used as an paymentMethod. Sorting should be handled inside this function and other tokens should be reorganized in their tokenIndexes. TokenType is also handled here: whether it's a erc20 (0), erc721(1) or erc1155(2).
    function setPermittedERC1155Tokens(
        address tokenAddress
    ) external returns (address[] memory);

    function setPercentageFromAllocation(
        uint percentageFromAllocation
    ) external returns (uint newPercentageFromAllocation);

    /// @notice callable by factory's admin. Registers a new token, making it possible for it to be used as an paymentMethod. Sorting should be handled inside this function and other tokens should be reorganized in their tokenIndexes.
    /// @param paymentTokens token for payment
    /// @param tokenType whether it's a erc20 (0), erc721(1) or erc1155(2).
    function setPaymentTokens(
        address paymentTokens,
        uint tokenType
    ) external returns (address[] memory newPaymentTokens);

    function setSmartAccount(
        address user,
        address newSmartAccount
    ) external returns (bool);

    /*╔═════════════════════════════╗
      ║      BATCH FUNCTIONS        ║
      ╚═════════════════════════════╝*/

    /// @notice to be used when new feature has come to the protocol. Funds need to be retrieved from old smart accounts to new ones through the skim() function inside this function.
    /// @param users id of user
    /// @param _newSmartAccounts new address of the contract with the new feature.
    function batchSetSmartAccounts(
        address[] calldata users,
        address[] calldata _newSmartAccounts
    ) external returns (bool);

    function registerSelf(string calldata userName) external returns (address);

    /* VISA-off
    function batchPause(address[] calldata _users) external;

    function batchUnpause(address[] calldata _users) external;
    */

    /*╔═════════════════════════════╗
      ║     TO CALL SA FUNCTIONS    ║
      ╚═════════════════════════════╝*/

    /// @notice callable only by goBlockchain. Have an id for each user. Sort permitted tokens to place them correctly in a tokenIndex mapping. address(0) must be the token of ID 0, so that we can avoid users passing in address(0) tokens. Like Uniswap, have a salt determined by specific user's address that can't be predicted, for example, using the custom name. Back/front-end needs to check whether there's a smart account for a user already. If not, make the user deposit the tokens in the factory, then user's funds are transferred to his smart account - to avoid company wasting gas if user requests a new factory to be created and (s)he doesn't deposit any tokens in the SA. Also, this is more efficient for the company because they don't have to pay two different txs. In its creation - or make another function specifically for this, the smartAccount needs to approve the the factory for a token to get its funds at anytime.
    /// @param user user's name that is on his card. If it's allowed in Brazil to have any nickname on a credit card, possibly make it be user's nickname.
    /// @param _username username to represent him in the contract.
    /// @return user address of user.
    /// @return smartAccount smartAccount created for user.
    function create(
        address _user,
        string calldata _username
    ) external returns (address user, address smartAccount);

    /// @notice Called to update users's SA liabilities. This function will probably be called once a month to update user's states. This function can be used or a direct call to an user's SA can be made through its `update` function, at any given time. 1) The user will have his credit updated only when he allocates - which will be available only through the front-end. If a user does not deposit anything more than his initial deposit, only the company will be able to update his credit based on his off-chain card usage & repayment.
    /// @dev Those who have debt will be the ones that have not paid their bills. They should be punish()ed according to the decided punition.
    /// @dev Those who have credit are probably those who've probably paid more than they should, in order to gain compound credit.
    /// @dev Those with a 0 are the ones who are neither in debt or in credit. They've paid their bills and are supposed to continue receiving credit for the following month.
    /// @param _users these are the target SA of each of the users whose liability is being updated.
    /// @param _liabilities this is the actual debt (<0) or credit(>0) the user has gained in at any time.
    function batchUpdate(
        address[] memory _users,
        int[] calldata _liabilities
    ) external;

    /// @notice We still need to decide how to penalize the user on-chain. This is fundamental to how the protocol will work. If the user does not fear being penalized, (s)he won't have any fear of incurring debt sequentially. One of the ways to do it on chain is to dimish user's score. The punish cannot take anymore tokens from the user by making them approve uint(-1) and us pulling them whenever the user's punished. The user may easily transfer his tokens to another account, making himself unpunished. So, we should actually use the tokens he has deposited in order to punish him. Question: 1) The contract will need to have been supplied with a good amount of ETH. If not, payments before the due date || parcial payments won't be supported because imagine the scenario where users come at different days to pay their bills but there's enough gas for the company to pay user's bills.
    /// @param usersIds users to be punished.
    /// @param amounts amounts in which each user is to be punished.
    function punish(uint[] calldata usersIds, int amounts) external;

    /*╔═════════════════════════════╗
      ║        VIEW FUNCTIONS       ║
      ╚═════════════════════════════╝*/

    /// @notice checks whether `account` is authorized to modify user's smart account.
    function admin(address) external view returns (bool);

    /// @notice helper mapping to retrieve a SA associated to an user.
    function smartAccount(address) external view returns (address);

    /// @notice helper mapping to make sure user is part of the protocol. Define if this will either mean user has deposited already or user has received their credit card.
    function user(address) external view returns (bool);

    /// @notice it retrieves users' scores for accountability.
    /// @param users user for which score will be checked.
    /// @return scores users scores to be retrieved.
    function scores(
        address[] calldata users
    ) external view returns (int[] memory scores);

    /// @notice gets a token from its address and check whether it's a erc20 (0), erc721(1) or erc1155(2).
    /// @param _token address of token.
    function tokenToStandard(address _token) external view returns (uint);
}

interface ISmartAccount {
    /*╔═════════════════════════════╗
      ║        VIEW FUNCTIONS       ║
      ╚═════════════════════════════╝*/

    /// @notice user's name.
    function name() external view returns (string memory);

    /// @notice checks whether `account` is authorized to modify user's smart account.
    /// @dev It should always match the current admins in SAFactory. So, avoid passing in constants, but always make a call to IFactory.admins().
    /// @param account to verify
    function admin(address account) external view returns (bool);

    /// @notice user's current credit (>0) or debt (<0) at any given time.
    function credit() external view returns (int);

    /// @notice user's max credit calculated from user's allocation. Consequentially, it is also the maxDebt for a user.
    function maxCredit() external view returns (uint256);

    /// @notice it increases each time the user `payback()`. It diminishes when user doesn't inccurs debt multiple times. It can be used futurely for giving a usr specific rewards according to his/her score.
    function score() external view returns (int);

    /// @notice it returns the last timestamp the SA was updated.
    /// @dev important for accountability to check whether all SAs in factory have all be updated around the same time.
    // function lastUpdatedTimestamp() external view returns (uint);

    /// @notice gets a token from its address and check whether it's a erc20 (0), erc721(1) or erc1155(2).
    /// @param _token address of token.
    function tokenToStandard(address _token) external view returns (uint);

    /// @notice callable by SAFactory. It sets the config options for the Smart Account and registers tokens in tokens addresses.
    /// @dev since the SA itself will pull the tokens from the user, user's approval of tokens to this contract should be handled inside the allocateWithPermit function.
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
    ) external returns (bool);
    */

    /// @notice storage variable that is either true or false. Use default values already registered in this Factory contract for the `create` function. If false, params should be given. If true, params can be of any value and they will be discarded.
    /// @dev I thought of having all users use the same value, but as it is done in the TradFi industry, users are categorized into certain thresholds - there's the Itau, but there's also the Itau Personalité, for example. So, a customization should be made possible. So, functions sould be also be accessible to be modified by admins in SA.
    function useDefault() external view returns (bool);

    /*╔═════════════════════════════╗
      ║      ADMIN FUNCTIONS        ║
      ╚═════════════════════════════╝*/

    /// @notice used by user to allocate funds and get debts. Make it have a `lock` modifier.
    // function allocate(uint256 tokenIndex, uint256 amount) external;

    /// @notice it permits a user to give his credits to another user, but the debt will be calculated against this SA, not the SA of the `to`.
    function allocateDelegate(
        uint256 tokenIndex,
        uint256 amount,
        address to
    ) external;

    /// Main function called by the company (or goblockchain?) to pull user funds to this contract and give him credit. `nonReentrant` function, but allowed to be called in different times for the same user to give him compound credit. Function uses the safeTransferFrom with permit functionality to pull tokens. This function can only be callable by the company. Why? Because precification needs to bae handled off-chain. If user calls this function directly, he can send any amount of a depretiated token and his credit can be updated, making it so that he'll have paid less than his bills. So, front-end determines precification, and the user can deposit it. Yes, he can deposit at anytime, however, he can't call it directly. To support  payments before the due data, anytime the user allocates, his credit is updated. To support direct payments, make an `if` statement that if it's not the company the `sender`, user will pay in a stablecoin - probably tether which is centralized and seems to maintain price at $1 always. Then do the math to convert to real - check whether there's a REAL-like stable coin on chain - and then do the math to roundup user payment onchain. Check whether the function implementation is protected against the company making the factory a user as well.
    /// @param tokenIndex token to allocate
    /// @param amount amount of token to allocate
    /// @param deadline deadline for token to be allocated.
    /// @param includesNonce does the token include a nonce (e.g. DAI) Check whether a nonce can be 0 - since it probably can't, use it as a param to identify that there's no nonce.
    /// @param nonce tx's nonce for token allocation, if any.
    /// @param v sig param
    /// @param r sig param
    /// @param s sig param
    function allocateWithPermit(
        uint256 tokenIndex,
        uint256 amount,
        uint256 deadline,
        bool includesNonce, // some tokens, like DAI seem to have a nonce in their permit functions.
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice Main function called by the company (or goblockchain?) to pull user funds to this contract and give him credit. `nonReentrant` function, but allowed to be called in different times for the same user to give him compound credit.
    /// @param tokenIndexes tokens the user want to allocate to receive credit. Must be in inside the permitted tokens addresses chosen by the company.
    /// @param amounts amounts of each token to be deposited.
    /// @param deadlines deadlines for the transfers to happen.
    /// @param includesNonce whether tokens use includes nonces
    /// @param nonces nonces for tokens. Choose an arbitrary number those who haven't nonces
    /// @param v sig param
    /// @param r sig param
    /// @param s sig param
    function batchAllocateWithPermit(
        uint256[] calldata tokenIndexes,
        uint256[] calldata amounts,
        uint256[] calldata deadlines,
        bool[] calldata includesNonce, // some tokens, like DAI seem to have a nonce in their permit functions.
        uint256[] calldata nonces,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) external;

    /// @notice only to be called by company's wallets addresses. It's called when company updates the states of the user according to their usage of the credit card off-chain. It can be called in batches to avoid block-max-gas-limit revert error in the chain being used.
    /// @param amount debt or credit of user in a given time. It is used to update the `credit` mapping.
    function update(int amount) external returns (int);

    /// @notice used by company to cease a user's participation in the protocol.
    function cease(uint8 v, bytes32 r, bytes32 s, bytes memory data) external;

    /// @notice pause SA' mains functionalities. Callable only by Factory on deactivate.
    function pause() external;

    /// @notice unpauses SA's mains functionalities. Callable only by Factory on activate.
    function unpause() external;

    /// @notice function callable by company to withdraw any tokens directly transferred to this contract by accident or leftovers from solidity's rounding arithmetic. If token to be withdrawn is the zero address, withdraw ether from contract. This function should be able to retrieve any balance from this smart account in case of a smart account upgrade so that funds can be transferred to the new one. Use safeTransfer function from SafeERC20 inside here to handle different tokens.
    /// @param token token to be withdrawn.
    /// @param to to whom it should be given to, possibly being the user who sent it by accident.
    function skim(address token, address to) external returns (bool);

    function setPaymentTokens(
        address paymentTokens,
        uint tokenType
    ) external returns (address[] memory newPaymentTokens);

    function setPermittedERC20Tokens(
        address tokenAddress
    ) external returns (address[] memory newPermittedERC20Tokens);

    function setPermittedERC721Tokens(
        address tokenAddress
    ) external returns (address[] memory newPermittedERC721Tokens);

    function setPermittedERC1155Tokens(
        address tokenAddress
    ) external returns (address[] memory);

    function setPercentageFromAllocation(
        uint percentageFromAllocation
    ) external returns (uint newPercentageFromAllocation);

    /// @notice it should be called within the `constructor` function saying wether it's gonna be true or false. Only callable by admins. Make the factory an admin as well.
    function setUseDefault(bool useDefault) external returns (bool);
}

library Errors {
    error ForbiddenSender();
    error InvalidCalldata();
    error InvalidUser(address user);
    error ArrayLengthMismatch();
    error Locked();
    error Paused();
    error InvalidToken(address token);
    error UnableToMove();
    error NotAUser(address nonUser);
}

/**
 * @notice helper methods for interacting with ETH/ERC721/ERC1155 tokens and sending ERC20s that do not consistently return true/false.
 * @dev inspired in the UniswapV2 TransferHelper library.
 */

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')))
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    /**
     * @notice safeTransfer ERC20 tokens.
     */
    function safeTransfer(address token, address to, uint256 value) internal {
        /// @dev bytes4(keccak256(bytes('transfer(address,uint256)')))
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    /**
     * @notice safeTransferFrom ERC20 tokens.
     */
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        /// @dev bytes4(keccak256(bytes('transferFrom(address,address,uint256)')))
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    /**
     * @notice safeTransfer ERC721 tokens.
     */
    function safeTransferERC721From(
        address token,
        address from,
        address to,
        uint id
    ) internal {
        ///@dev bytes4(keccak256('bytes(safeTransferFrom(address from, address to, uint256 tokenId))'))
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x42842e0e, from, to, id)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    /**
     * @notice safeTransfer ERC1155 tokens.
     */
    function safeTransferERC1155From(
        address token,
        address from,
        address to,
        uint id,
        uint256 value
    ) internal {
        /// @dev bytes4(keccak256(bytes('safeTransferFrom(address,address,uint256,uint256,bytes)')))
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xf242432a, from, to, id, value, "0x")
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    /**
     * @notice safeTransfer ETH.
     */
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

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

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/IERC1155Receiver.sol)

// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Interface that must be implemented by smart contracts in order to receive
 * ERC-1155 token transfers.
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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
        // @dev division should be performed last
        ISmartAccount(_smartAccount[msg.sender]).update(
            int256((msg.value * 30000) / 1 ether)
        );

        emit CreditUpdated(
            msg.sender,
            _smartAccount[msg.sender],
            int256((msg.value * 30000) / 1 ether),
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
        // NOTE: This is not yet safe. A malicious `msg.sender` can call this function with a registered `from` address, etc.
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
        return credits;
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

    function registerTokens(
        address[] calldata _tokens,
        uint256[] calldata _types
    ) external returns (bool) {
        _isAdmin(msg.sender);
        uint length = _tokens.length;
        if (length != _types.length) revert Errors.ArrayLengthMismatch();
        for (uint i; i < length; ) {
            // @dev below reverts if _types[i] > 3.
            _tokensType[_tokens[i]] = uint(TokenStandard(_types[i]));
            unchecked {
                ++i;
            }
        }
        return true;
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

    function deactivate(
        uint userId,
        bool refund
    ) external override returns (bool) {}

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

