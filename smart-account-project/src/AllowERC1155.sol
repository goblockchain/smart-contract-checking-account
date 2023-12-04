// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {Storage} from "./Storage.sol";
import {ISmartAccount} from "./interfaces/ISmartAccount.sol";
import {Errors} from "./helpers/Errors.sol";

abstract contract AllowERC1155 is IERC1155Receiver, Storage {
    /// @notice the function below as is MUST NOT be used in production. This is only a demo for a presentation
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external lock returns (bytes4) {
        // NOTE: This is not yet safe. A malicious `msg.sender` can call this function with a registered `from` address, etc.
        // if (_smartAccount[from] == address(0)) revert Errors.NotAUser(from);
        require(_tokensType[msg.sender] == uint(TokenStandard.isERC1155), "!3");
        revertIfZeroAddress(_smartAccount[from]);
        if (!_users[from]) revert Errors.InvalidUser(from);

        ISmartAccount(_smartAccount[from]).update(1000);
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
        if (_smartAccount[from] == address(0)) revert Errors.InvalidUser(from);
        ISmartAccount(_smartAccount[from]).update(1000);
        _tokensType[msg.sender] = uint(TokenStandard.isERC1155);
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
