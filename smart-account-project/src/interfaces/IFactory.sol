// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

interface IFactory {
    /// @notice callable only by goBlockchain. Have an id for each company. Sort permitted tokens to place them correctly in a tokenIndex mapping. address(0) must be the token of ID 0, so that we can avoid users passing in address(0) tokens.
    /// @param company company's name
    /// @param companyAdmins company wallets with access to modify state of the Smart Account.
    /// @param minAllocation min allowed allocation by user
    /// @param acceptERC20Tokens flag to allow/disallow erc20s allocations
    /// @param permittedERC20Tokens permitted erc20 tokens
    /// @param acceptERC721Tokens flag to allow/disallow erc721s allocations
    /// @param permittedERC721Tokens permitted erc721 tokens
    /// @param acceptERC1155Tokens flag to allow/disallow erc1155s allocations
    /// @param permittedERC1155Tokens permitted erc1155 tokens
    /// @param percentageFromAllocation percentage of allowcation given to user as credit.
    /// @param paymentTokens tokens allowed to be received as a payment for debt.
    /// @return companyId company's ID generated upon creation
    function create(
        string calldata company,
        address[] calldata companyAdmins,
        uint minAllocation,
        bool acceptERC20Tokens,
        address[] calldata permittedERC20Tokens,
        bool acceptERC721Tokens,
        address[] calldata permittedERC721Tokens,
        bool acceptERC1155Tokens,
        address[] calldata permittedERC1155Tokens,
        uint percentageFromAllocation,
        address[] calldata paymentTokens
    ) external returns (uint companyId);

    /// @notice public mapping showing companies' status.
    /// @param companyId company whose status is being checked.
    function active(uint companyId) external view returns (bool);

    /// @notice Marks company as inactive and pauses Smart Account company's contract. Refunds should be given to users, if any. Callable by goBlockchain only.
    /// @param companyId ID of company to inactivate.
    function deactivate(uint companyId, bool refund) external returns (bool);

    /// @notice function callable by goBlockchain to withdraw any tokens directly transferred to this contract by accident. If token to be withdrawn is the zero address, withdraw ether from contract.
    /// @param token token to be withdrawn.
    /// @param to to whom it should be given to, possibly being the user who sent it by accident.
    function skim(address token, address to) external returns (bool);
}
