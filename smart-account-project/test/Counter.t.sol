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
    address goodUser;
    address badUser;

    function setUp() public {
        admin = vm.addr(vm.envUint("DIGEST"));
        userHenrique = vm.addr(vm.envUint("DIGEST2"));
        goodUser = vm.addr(0x12345);
        badUser = vm.addr(0x123456);
        vm.deal(admin, 2 ether);
        vm.deal(userHenrique, 20 ether);
        vm.deal(badUser, 5 ether);
        vm.deal(goodUser, 5 ether);
        vm.startPrank(admin);
        factory = new Factory(address(userHenrique), "Henrique L. Silva");
        vm.stopPrank();
        smart = SmartAccount(factory.smartAccount(userHenrique));
        emit log_address(address(smart));
    }

    function test_ViewFunctions() public {
        assertEq(factory.admin(admin), true);
        assertEq(factory.user(userHenrique), true);

        assertEq(smart.credit(), 0);
        assertEq(smart.score(), 0);
        assertEq(smart.maxCredit(), 0);
        assertEq(smart.lastUpdatedAt(), 0);
        assertEq(smart.name(), "Henrique L. Silva");
    }

    /// @notice tests if user gets credit by sending native ETH to the Factory.
    function test_ETHCredit() public {
        vm.startPrank(userHenrique);
        (bool ok, ) = address(factory).call{value: 3 ether}("");
        assertEq(smart.credit(), 3 * 1000);

        vm.stopPrank();
        vm.startPrank(badUser);
        vm.expectRevert(); // reverts because user isn't registered.
        (bool ko, ) = address(factory).call{value: 3 ether}("");
        vm.stopPrank();

        vm.startPrank(goodUser);
        address userSmart = factory.registerSelf("goodUser");
        (bool done, ) = address(factory).call{value: 3 ether}("");
        assertEq(SmartAccount(userSmart).credit(), 3 * 1000);
        assertEq(SmartAccount(userSmart).lastUpdatedAt(), block.timestamp);

        vm.startPrank(admin);
        (, address badUserSmart) = factory.create(badUser, "badUser da Silva");

        vm.startPrank(badUser);
        address(factory).call{value: 3 ether}("");
        assertEq(SmartAccount(badUserSmart).credit(), 3 * 1000);
    }

    /// @notice tests if user gets credit by sending an NFT to the Factory contract.
    function test_NFTCredit() public {}
}
