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

    /*╔═════════════════════════════╗
      ║        SET FUNCTIONS        ║
      ╚═════════════════════════════╝*/

    /// @notice callable by factory's admin. Registers a new token, making it possible for it to be used as an paymentMethod. Sorting should be handled inside this function and other tokens should be reorganized in their tokenIndexes. TokenType is also handled here: whether it's a erc20 (0), erc721(1) or erc1155(2).
    function setAllowedERC20Tokens(
        address[] calldata tokenAddresses,
        bool[] calldata allow
    ) external returns (bool);

    /// @notice callable by factory's admin. Registers a new token, making it possible for it to be used as an paymentMethod. Sorting should be handled inside this function and other tokens should be reorganized in their tokenIndexes. TokenType is also handled here: whether it's a erc20 (0), erc721(1) or erc1155(2).
    function setAllowedERC721Tokens(
        address[] calldata tokenAddress,
        bool[] calldata allow
    ) external returns (bool);

    /// @notice callable by factory's admin. Registers a new token, making it possible for it to be used as an paymentMethod. Sorting should be handled inside this function and other tokens should be reorganized in their tokenIndexes. TokenType is also handled here: whether it's a erc20 (0), erc721(1) or erc1155(2).
    function setAllowedERC1155Tokens(
        address[] calldata tokenAddresses,
        bool[] calldata allow
    ) external returns (bool);

    /*╔═════════════════════════════╗
      ║      BATCH FUNCTIONS        ║
      ╚═════════════════════════════╝*/

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

    /// @notice Called to update users's SA liabilities. This function will probably be called once a month to update user's states. This function can be used or a direct call to an user's SA can be made through its `update` function, at any given time. 1) The user will have his credit updated only when he allocates - which will be available only through the front-end. If a user does not deposit anything more than his initial deposit, only the company will be able to update his credit based on his off-chain card usage & repayment. This function MUST only to be called by `admins` since it defines how much a user has to pay on-chain, since the user will not update his liability when buying with his card.
    /// @dev Those who have debt will be the ones that have not paid their bills. They should be punish()ed according to the decided punition.
    /// @dev Those who have credit are probably those who've probably paid more than they should, in order to gain compound credit.
    /// @dev Those with a 0 are the ones who are neither in debt or in credit. They've paid their bills and are supposed to continue receiving credit for the following month.
    /// @param _users these are the target SA of each of the users whose liability is being updated.
    /// @param _liabilities this is the actual debt (<0) or credit(>0) the user has gained in at any time.
    function adminUpdate(
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

    /**
     * @notice This function must return one of the following:
     * v0: if users are the ones to pay for their txs.
     * v1: v0 + if company is able to pay for some of the txs from users. (meta-txs funcionality).
     * v2: v1 + if there's a `staking` mechanism that generates rewards for  company or/and goBlockchain or/and users.
     */
    function version() external pure returns (string memory);
}
