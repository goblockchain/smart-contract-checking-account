// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

interface ISmartAccount {
    /// company's name
    function name() external view returns (string memory);

    /// callable by factory. It sets the config options for the Smart Account.
    function init() external;

    /// public mapping of tokenID -> token address in SmartAccount. Addresses are put into tokenIndex after sorting them in factory
    function tokenIndex(uint tokenIndex) external view returns (address);

    /// used by user to allocate funds and get debts
    function allocate() external;

    /// used by company to allocate with permit of user
    function allocateWithPermit(
        uint tokenIndex,
        uint256 amount,
        uint256 deadline,
        bool includesNonce, // some tokens, like DAI seem to have a nonce in their permit functions.
        uint nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// only to be called by company's contract address.
    function borrow() external;

    /// used to pay debt
    function payback() external;

    /// used by user to cease his/her participation in the protocol
    function cease() external;

    /// used by company to cease user's participation in the protocol
    function ceaseWithPermit(address usr) external;

    /// returns excess credit for the user in a given month
    function excess(address usr) external view returns (uint256);

    /// returns current debt for the user in a given month
    function debt(address usr) external view returns (uint256);

    /// pause companies' mains functionalities. Callable only by Factory on deactivate.
    function pause() external;

    /// unpauses company's mains functionalities. Callable only by Factory on activate.
    function unpause() external;
}

/**
 * Flow inside smart account:
 * user.allocate() or company allocateWithPermit()
 *
 */

/*
    How will the contract flow work?

    goBlockchain(+) -> Factory -> Smart Account of Company
    goBlockchain(-) -> Factory -> Smart Account of Company

    User calldata(+) -> allocate -> Smart Account of Company
    User borrow(-) -> Company's contract -> Smart Account of Company
    User payback(+) -> Smart Account of Company
    User withdraw(-) -> Company's contract -> Smart Account of Company

    Make a contract for the company where it can list different accounts on it and these accounts can be used to call the SmartAccount contract. (Company's contract) 
*/
