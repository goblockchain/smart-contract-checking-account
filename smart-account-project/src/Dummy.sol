// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/metatx/ERC2771Forwarder.sol";
import "../lib/openzeppelin-contracts/contracts/metatx/ERC2771Context.sol";

contract Dummy is ERC2771Context, ERC2771Forwarder {

    uint number;

    constructor() ERC2771Forwarder("Factory") ERC2771Context(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2) {
    }
    
    function setNumber(uint _number) external {
        number = _number;
    }

    function getCallData(uint _number) external view returns(bytes4) {
        return bytes4(bytes(keccak256("setNumber(uint256)")));
    }



}