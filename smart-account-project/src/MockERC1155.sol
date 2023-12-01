// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

contract MockERC1155 is
    ERC1155(
        "https://gateway.pinata.cloud/ipfs/QmPJRtRVs21prUD9pu9w55kexhZ4wPaViwRfDrwAxQizwT"
    )
{
    string public name = "CoOlArT";

    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint(address to, uint id) external {
        _mint(to, id, 1, "");
    }
}
