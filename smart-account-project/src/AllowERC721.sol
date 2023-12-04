// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Storage} from "./Storage.sol";
import {ISmartAccount} from "./interfaces/ISmartAccount.sol";
import {Errors} from "./helpers/Errors.sol";

abstract contract AllowERC721 is IERC721Receiver, Storage {
    /// @notice the function below as is MUST NOT be used in production. This is only a demo for a presentation
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external lock returns (bytes4) {
        // NOTE: This is not yet safe. A malicious `msg.sender` can call this function with a registered `from` address, etc.
        if (_smartAccount[from] == address(0)) revert Errors.InvalidUser(from);
        _tokensType[msg.sender] = uint(TokenStandard.isERC721);
        require(uint(TokenStandard.isERC721) == 2, "!2");
        ISmartAccount(_smartAccount[from]).update(1000);
        return IERC721Receiver.onERC721Received.selector;
    }
}
