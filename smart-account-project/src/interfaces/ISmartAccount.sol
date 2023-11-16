// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

interface ISmartAccount {
    /// @notice company's name.
    function name() external view returns (string memory);

    /// @notice checks whether `account` is an authorized for the company
    /// @param account to verify
    function auth(address account) external view returns (bool);

    /// @notice mapping of user's current credit (>0) or debt (<0).
    /// @param usr user for credit or debt to be retrieved.
    function credit(address usr) external view returns (int);

    /// @notice mapping of user's max credit calculated from user's allocation. Consequentially, it is also the maxDebt for a user.
    /// @param usr user for which max credit is retrieved.
    function maxCredit(address usr) external view returns (uint256);

    /// @notice it increases each time the user `payback()`. It diminishes when user doesn't inccurs debt multiple times. It can be used futurely for giving a usr specific rewards according to his/her score.
    function score(address usr) external view returns (int);

    /// @notice callable by factory. It sets the config options for the Smart Account and registers tokens in tokens addresses.
    function init(
        uint companyId,
        string calldata company,
        address[] calldata companyAdmins,
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

    /// it returns token address from tokenIndex.
    /// @param token token of which index we want.
    function tokenIndex(address token) external view returns (uint256);

    /// @notice public mapping of tokenID -> token address in SmartAccount. Addresses are put into tokenIndex after sorting them in factory. These are the allowed tokens to be used as a allocation.
    function tokenAddress(uint256 tokenIndex) external view returns (address);

    /// @notice gets a token from tokenIndex and check whether it's a erc20 (0), erc721(1) or erc1155(2).
    /// @param tokenIndex index of token.
    function tokenIndexToType(uint256 tokenIndex) external view returns (uint);

    /// @notice used by user to allocate funds and get debts. Make it have a `lock` modifier.
    function allocate(uint256 tokenIndex, uint256 amount) external;

    /// @notice it permits a user to give his credits to another user, but the debt will be calculated against the delegator, not the delegatee.
    function allocateDelegate(
        uint256 tokenIndex,
        uint256 amount,
        address to
    ) external;

    /// Main function called by the company (or goblockchain?) to pull user funds to this contract and give him credit. `nonReentrant` function, but allowed to be called in different times for the same user to give him compound credit.
    /// @param tokenIndex token to allocate
    /// @param amount amount of token to allocate
    /// @param deadline deadline for token to be allocated.
    /// @param includesNonce does the token include a nonce (e.g. DAI)
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

    /// @notice only to be called by company's contract address. It's called when company updates the states of the user according to their usage of the credit card off-chain. It can be called in batches to avoid block-max-gas-limit revert error in the chain being used.
    /// @param users user for state to be updated. Must be already a user whose allocated tokens in the SmartAccount.
    /// @param amounts debt or credit of user in a given time. It is used to update the `credit` mapping.
    function update(address[] memory users, int[] calldata amounts) external;

    /// @notice used by user to cease his/her participation in the protocol
    function cease(uint8 v, bytes32 r, bytes32 s, bytes memory data) external;

    /// @notice used by company to cease a user's participation in the protocol.
    function cease(address usr) external;

    /// @notice pause companies' mains functionalities. Callable only by Factory on deactivate.
    function pause() external;

    /// @notice unpauses company's mains functionalities. Callable only by Factory on activate.
    function unpause() external;

    /// @notice function callable by company to withdraw any tokens directly transferred to this contract by accident or leftovers from solidity's rounding arithmetic. If token to be withdrawn is the zero address, withdraw ether from contract.
    /// @param token token to be withdrawn.
    /// @param to to whom it should be given to, possibly being the user who sent it by accident.
    function skim(address token, address to) external returns (bool);

    /// @notice We still need to decide how to penalize the user on-chain. This is fundamental to how the protocol will work. If the user does not fear being penalized, (s)he won't have any fear of incurring debt sequentially. One of the ways to do it on chain is to dimish user's score.
    /// @param users users to be punished.
    /// @param amounts amounts in which each user is to be punished.
    function punish(address[] calldata users, uint amounts) external;
}
