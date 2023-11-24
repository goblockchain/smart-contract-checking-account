// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Factory} from "../src/Factory.sol";
import {SmartAccount} from "../src/SmartAccount.sol";
import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721("Dummy721NFT", "D7NFT") {
    constructor() {
        _mint(msg.sender, 1);
    }

    function mintMe() external {
        _mint(msg.sender, 1);
    }
}

contract CounterTest is Test {
    Factory factory;
    SmartAccount smart; // for Henrique
    address admin;
    address userHenrique;

    function setUp() public {
        admin = vm.addr(vm.envUint("DIGEST"));
        userHenrique = vm.addr(vm.envUint("DIGEST2"));
        vm.deal(admin, 2 ether);
        vm.deal(userHenrique, 20 ether);
        vm.startPrank(admin);
        factory = new Factory(address(userHenrique), "Henrique L. Silva");
    }

    function test_ViewFunctions() public {
        assertEq(factory.admin(admin), true);
        assertEq(factory.user(userHenrique), true);
        smart = SmartAccount(factory.smartAccount(userHenrique));
        emit log_address(address(smart));

        assertEq(smart.credit(), 0);
        assertEq(smart.score(), 0);
        assertEq(smart.maxCredit(), 0);
        assertEq(smart.lastUpdatedTimestamp(), 0);
        assertEq(smart.name(), "Henrique L. Silva");
    }

    function test_ETHCredit() public {
        vm.startPrank(userHenrique);
        address(factory).call{value: 3 ether}("");
        assertEq(smart.credit(), 3 * 1000);
    }

    function test_NFTCredit() public {}
}
