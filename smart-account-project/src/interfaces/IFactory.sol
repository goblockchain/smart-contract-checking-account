// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

interface IFactory {
    /**
     * company's name,
     * minAllocation by user,
     * paymentDay(s),
     * ERC20 accepted tokens,
     * ERC721 accepted tokens,
     * ERC1155 accepted tokens,
     * accepts erc20, (flag to avoid waste of gas)
     * accepts erc721, (flag to avoid waste of gas)
     * accepts erc1155, (flag to avoid waste of gas)
     * percentage upon allocation
     */

    /// callable only by goBlockchain. Have an id for each company. Sort permitted tokens to place them correctly in a tokenIndex mapping.
    /// @param company company's name
    /// @param minAllocation min allowed allocation by user
    /// @param acceptERC20Tokens flag to allow/disallow erc20s allocations
    /// @param permittedERC20Tokens permitted erc20 tokens
    /// @param acceptERC721Tokens flag to allow/disallow erc721s allocations
    /// @param permittedERC721Tokens permitted erc721 tokens
    /// @param acceptERC1155Tokens flag to allow/disallow erc1155s allocations
    /// @param permittedERC1155Tokens permitted erc1155 tokens
    /// @param percentageFromAllocation percentage of credit given to user.
    /// @return companyId company's ID generated upon creation
    function create(
        string calldata company,
        uint minAllocation,
        bool acceptERC20Tokens,
        address[] calldata permittedERC20Tokens,
        bool acceptERC721Tokens,
        address[] calldata permittedERC721Tokens,
        bool acceptERC1155Tokens,
        address[] calldata permittedERC1155Tokens,
        uint percentageFromAllocation
    ) external returns (uint companyId);

    /// public mapping showing companies' status.
    /// @param companyId company whose status is being checked.
    function active(uint companyId) external view returns (bool);

    /// Marks company as inactive and pauses Smart Account company's contract. Refunds should be given to users, if any. Callable by goBlockchain only.
    /// @param companyId ID of company to inactivate.
    function deactivate(uint companyId, bool refund) external returns (bool);
}
