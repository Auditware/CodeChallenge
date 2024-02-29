// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ReentrancyGuard.sol";

contract Lottery is ReentrancyGuard {

    struct Player {
        uint256 totalWagered; // Total amount wagered by the player in the current round
        uint256 tickets; // Number of tickets the player has in the current round
    }

    mapping(address => Player) public playerInfo;
    address[] public participants; // Track participants for each round

    uint256 public totalTickets = 0;
    uint256 public lotteryStartTime;

    uint256 public constant DURATION = 1 days;
    uint256 public constant TICKET_PRICE = 0.01 ether;

    event LotteryEntry(address player, uint256 amount, uint256 tickets);
    event RewardsDistributed(address[] winners, uint256 totalReward);
    mapping(address => uint256) public rewards;

    constructor() {
        lotteryStartTime = block.timestamp;
    }

    function enterLottery() external payable nonReentrant {

        require(block.timestamp < lotteryStartTime + DURATION, "Lottery round has ended.");
        require(msg.value >= TICKET_PRICE, "Minimum wager is 0.01 ETH.");

        uint256 tickets = msg.value / TICKET_PRICE;
        Player storage player = playerInfo[msg.sender];
        
        if (player.tickets == 0) { // New participant for this round
            participants.push(msg.sender);
        }

        player.totalWagered += msg.value;
        player.tickets += tickets;
        totalTickets += tickets;

        emit LotteryEntry(msg.sender, msg.value, tickets);
    }

    function distributeRewards() public nonReentrant {

        require(block.timestamp >= lotteryStartTime + DURATION, "Lottery round is still active.");

        uint256 rewardPool = address(this).balance;
        uint256 winnersCount = totalTickets / 4;
        uint256 rewardPerWinner = winnersCount > 0 ? rewardPool / winnersCount : 0;

        address[] memory winners = new address[](winnersCount);

        // NOTE - issues related to large for loop are out of scope for this challenge
        for (uint256 i = 0; i < winnersCount; i++) {
            // NOTE - although this psuedo randomness is potenitally manipulable,
            // assume it is secure for the purpose of this challenge.
            uint256 winningTicket = uint256(keccak256(abi.encodePacked(block.timestamp, i))) % totalTickets + 1;
            address winner = selectWinner(winningTicket);
            winners[i] = winner;
            rewards[winner] += rewardPerWinner;
        }
        
        emit RewardsDistributed(winners, rewardPool);
        // Prepare for the next round
        resetForNextRound();
    }

    function withdrawReward() public nonReentrant {
        uint256 amount = rewards[msg.sender];
        require(amount > 0, "No rewards to withdraw");

        rewards[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    function selectWinner(uint256 winningTicket) private view returns (address) {
        uint256 sum = 0;

        // NOTE - issues related to large for loop are out of scope for this challenge
        for (uint256 i = 0; i < participants.length; i++) {
            address participant = participants[i];
            Player storage player = playerInfo[participant];
            sum += player.tickets;

            if (winningTicket <= sum) {
                return participant;
            }
        }
        revert("Winner not found.");
    }

    function resetForNextRound() private {
        // NOTE - issues related to large for loop are out of scope for this challenge
        for (uint256 i = 0; i < participants.length; i++) {
            delete playerInfo[participants[i]]; // Clear participant info for the new round
        }

        delete participants; // Clear participants array for the new round
        totalTickets = 0; // Reset tickets count for the new round
        lotteryStartTime = block.timestamp; // Update start time for the next round
    }
}