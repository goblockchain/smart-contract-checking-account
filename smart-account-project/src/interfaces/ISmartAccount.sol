// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

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

    /// @notice mapping of user's current credit (>0) or debt (<0) at any given time.
    function credit() external view returns (int);

    /// @notice user's max credit calculated from user's allocation. Consequentially, it is also the maxDebt for a user.
    function maxCredit() external view returns (uint256);

    /// @notice it increases each time the user `payback()`. It diminishes when user doesn't inccurs debt multiple times. It can be used futurely for giving a usr specific rewards according to his/her score.
    function score() external view returns (int);

    /// @notice it returns the last timestamp the SA was updated.
    /// @dev important for accountability to check whether all SAs in factory have all be updated around the same time.
    function lastUpdateTimestamp() external view returns (uint);

    /// it returns token address from tokenIndex.
    /// @param token token of which index we want.
    function tokenIndex(address token) external view returns (uint256);

    /// @notice public mapping of tokenID -> token address in SmartAccount. Addresses are put into tokenIndex after sorting them in factory. These are the allowed tokens to be used as a allocation.
    function tokenAddress(uint256 tokenIndex) external view returns (address);

    /// @notice callable by SAFactory. It sets the config options for the Smart Account and registers tokens in tokens addresses.
    /// @dev since the SA itself will pull the tokens from the user, user's approval of tokens to this contract should be handled inside the allocateWithPermit function.
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

    /// @notice storage variable that is either true or false. Use default values already registered in this Factory contract for the `create` function. If false, params should be given. If true, params can be of any value and they will be discarded.
    /// @dev I thought of having all users use the same value, but as it is done in the TradFi industry, users are categorized into certain thresholds - there's the Itau, but there's also the Itau Personalité, for example. So, a customization should be made possible. So, functions sould be also be accessible to be modified by admins in SA.
    function useDefault() external view returns (bool);

    /*╔═════════════════════════════╗
      ║      ADMIN FUNCTIONS        ║
      ╚═════════════════════════════╝*/

    /// @notice used by user to allocate funds and get debts. Make it have a `lock` modifier.
    function allocate(uint256 tokenIndex, uint256 amount) external;

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
    function update(int amount) external;

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
