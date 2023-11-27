// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Factory} from "../src/Factory.sol";
import {SmartAccount} from "../src/SmartAccount.sol";
import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {ERC1155} from "../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

contract MockERC721 is ERC721("Dummy721NFT", "D7NFT") {
    constructor() {
        _safeMint(msg.sender, 1);
    }

    function mintMe(address to) external {
        _safeMint(to, 2);
    }
}

contract MockERC1155 is ERC1155("uri") {
    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint(address to, uint id) external {
        _mint(to, id, 1, "");
    }
}

contract CounterTest is Test {
    MockERC721 nft;
    MockERC1155 batchNft;
    Factory factory;
    SmartAccount smart; // for Henrique
    address admin;
    address userHenrique;
    address goodUser;
    address badUser;

    function setUp() public {
        // get users.
        admin = vm.addr(vm.envUint("DIGEST"));
        userHenrique = vm.addr(vm.envUint("DIGEST2"));
        goodUser = vm.addr(0x12345);
        badUser = vm.addr(0x123456);

        // users get their nfts.
        vm.startPrank(goodUser);
        nft = new MockERC721();
        batchNft = new MockERC1155();
        assertEq(nft.balanceOf(goodUser), 1);
        vm.stopPrank();

        // users get their nfts.
        vm.startPrank(badUser);
        nft.mintMe(badUser);
        assertEq(nft.balanceOf(badUser), 1);
        vm.stopPrank();

        // users can pay their own txs [meta-tx are not supported yet]
        vm.deal(admin, 2 ether);
        vm.deal(userHenrique, 20 ether);
        vm.deal(badUser, 5 ether);
        vm.deal(goodUser, 5 ether);

        // factory is deployed and first user is registered.
        vm.startPrank(admin);
        factory = new Factory(address(userHenrique), "Henrique L. Silva");
        vm.stopPrank();
        smart = SmartAccount(factory.smartAccount(userHenrique));

        emit log_address(address(smart));
    }

    /// @notice check the view functions return as expected.
    function test_ViewFunctions() public {
        assertEq(factory.admin(admin), true);
        assertEq(factory.user(userHenrique), true);
        address[] memory userss = new address[](1);
        userss[0] = userHenrique;
        factory.credits(userss);

        assertEq(smart.credit(), 0);
        assertEq(smart.score(), 0);
        assertEq(smart.maxCredit(), 0);
        assertEq(smart.lastUpdatedAt(), 0);
        assertEq(smart.name(), "Henrique L. Silva");
    }

    /// @notice checks that user gets credit by sending native ETH directly to the Factory.
    function test_ETHCredit() public {
        // a registered user is someone that has been registered by the company.

        // registered user sends ETH/MATIC directly to factory.
        vm.startPrank(userHenrique);
        (bool ok, ) = address(factory).call{value: 3 ether}("");
        assertEq(smart.credit(), 3 * 1000);
        vm.stopPrank();

        // unregistered user sends ETH/MATIC directly to factory.
        vm.startPrank(badUser);
        /// @dev reverts because only registered can get credit.
        vm.expectRevert();
        (bool ko, ) = address(factory).call{value: 3 ether}("");
        vm.stopPrank();

        // user registers itself to be able to send ETH/MATIC directly
        vm.startPrank(goodUser);
        /// @dev self-registration is only supported for visa's presentation.
        address userSmart = factory.registerSelf("goodUser");
        (bool done, ) = address(factory).call{value: 3 ether}("");
        // credit's updated.
        assertEq(SmartAccount(userSmart).credit(), 3 * 1000);
        assertEq(SmartAccount(userSmart).lastUpdatedAt(), block.timestamp);
        vm.stopPrank();

        // admin now registers `badUser`.
        vm.startPrank(admin);
        (, address badUserSmart) = factory.create(badUser, "badUser da Silva");
        vm.stopPrank();

        // `badUser` now is able to send ETH/MATIC directly to contract.
        vm.startPrank(badUser);
        address(factory).call{value: 3 ether}("");
        assertEq(SmartAccount(badUserSmart).credit(), 3 * 1000);
        vm.stopPrank();
    }

    /// @notice tests if user gets credit by sending an NFT directly to the Factory contract.
    function test_NFTCredit() public {
        // unregistered user sends NFT directly to contract.
        vm.startPrank(badUser);

        /// @dev it reverts because unregistered user can't get credit.
        vm.expectRevert();
        nft.safeTransferFrom(badUser, address(factory), 2);
        vm.stopPrank();

        // admin registers users
        vm.startPrank(admin);
        (, address smartGoodUser) = factory.create(goodUser, "goodUser");
        (, address smartBadUser) = factory.create(badUser, "badUser");
        vm.stopPrank();

        // `goodUser` sends ERC721 NFT to contract.
        vm.startPrank(goodUser);
        nft.safeTransferFrom(goodUser, address(factory), 1);
        vm.stopPrank();

        // registered `goodUser` has got his credits.
        assertEq(SmartAccount(factory.smartAccount(goodUser)).credit(), 1000);

        // `badUser` is now registered.
        vm.startPrank(badUser);
        // `badUser` sends ERC721 NFT to contract.
        nft.safeTransferFrom(badUser, address(factory), 2);
        vm.stopPrank();

        // registered `badUser` has got his credits.
        assertEq(SmartAccount(factory.smartAccount(badUser)).credit(), 1000);

        // registered users send ERC1155 NFT to factory.
        /// @dev It reverts if the user isn't registered.
        vm.startPrank(goodUser);
        batchNft.mint(goodUser, 1);
        batchNft.safeTransferFrom(goodUser, address(factory), 1, 1, "");
        vm.stopPrank();

        // since user has sent two NFTs, his credit is updated accordingly.
        /// @dev (1000 + 1000), 1000 for each NFT sent.
        assertEq(SmartAccount(factory.smartAccount(goodUser)).credit(), 2000);
    }
}
