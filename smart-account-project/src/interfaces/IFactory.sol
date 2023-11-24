// SPDX-License-Identifier: SEE LICENSE IN LICENSE
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
    function move(
        address _token,
        address _to,
        uint _id
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
        uint userId,
        address newSmartAccount
    ) external returns (bool);

    /*╔═════════════════════════════╗
      ║      BATCH FUNCTIONS        ║
      ╚═════════════════════════════╝*/

    /// @notice to be used when new feature has come to the protocol. Funds need to be retrieved from old smart accounts to new ones through the skim() function inside this function.
    /// @param _users id of user
    /// @param _newSmartAccounts new address of the contract with the new feature.
    function batchSetSmartAccounts(
        address[] calldata _users,
        address[] calldata _newSmartAccounts
    ) external returns (bool);

    /* VISA-off
    function batchPause(address[] calldata _users) external;

    function batchUnpause(address[] calldata _users) external;
    */

    /*╔═════════════════════════════╗
      ║     TO CALL SA FUNCTIONS    ║
      ╚═════════════════════════════╝*/

    /// @notice callable only by goBlockchain. Have an id for each user. Sort permitted tokens to place them correctly in a tokenIndex mapping. address(0) must be the token of ID 0, so that we can avoid users passing in address(0) tokens. Like Uniswap, have a salt determined by specific user's address that can't be predicted, for example, using the custom name. Back/front-end needs to check whether there's a smart account for a user already. If not, make the user deposit the tokens in the factory, then user's funds are transferred to his smart account - to avoid company wasting gas if user requests a new factory to be created and (s)he doesn't deposit any tokens in the SA. Also, this is more efficient for the company because they don't have to pay two different txs. In its creation - or make another function specifically for this, the smartAccount needs to approve the the factory for a token to get its funds at anytime.
    /// @param user user's name that is on his card. If it's allowed in Brazil to have any nickname on a credit card, possibly make it be user's nickname.
    /// @param minAllocation min allowed allocation by user
    /// @param acceptERC20Tokens flag to allow/disallow erc20s allocations
    /// @param permittedERC20Tokens permitted erc20 tokens
    /// @param acceptERC721Tokens flag to allow/disallow erc721s allocations
    /// @param permittedERC721Tokens permitted erc721 tokens
    /// @param acceptERC1155Tokens flag to allow/disallow erc1155s allocations
    /// @param permittedERC1155Tokens permitted erc1155 tokens
    /// @param percentageFromAllocation percentage of allowcation given to user as credit.
    /// @param paymentTokens tokens allowed to be received as a payment for debt.
    /// @param includesNonce wether token includes nonce.
    /// @param nonce nonce if includesNonce is true.
    /// @param v sig param.
    /// @param r sig param.
    /// @param s sig param.
    /// @param useDefault the smartAccount should be customized or it should use the default values registered in the Factory. Set to true by default in back-end.
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
        bool includesNonce, // some tokens, like DAI seem to have a nonce in their permit functions.
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool useDefault
    ) external returns (address _user, address smartAccount);

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
    function users(address) external view returns (bool);

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
