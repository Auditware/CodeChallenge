// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Token.sol";
import "forge-std/Test.sol";

contract CErc20Clone {
    Token public underlying;
    uint256 public totalSupply;
    uint256 public initialExchangeRateMantissa = 1e18;

    mapping(address => uint256) public accountTokens;

    constructor(address tokenAddress) {
        underlying = Token(tokenAddress);
    }

    function mint(address minter, uint256 mintAmount) public {
        require(
            underlying.transferFrom(minter, address(this), mintAmount),
            "Transfer failed"
        );
        uint256 mintTokens = calculateMintAmount(mintAmount);
        console2.log(
            "[CErc20Clone.mint]   Exchange Rate",
            exchangeRateStored()
        );
        console2.log("[CErc20Clone.mint]   Mint Tokens calculated", mintTokens);
        totalSupply += mintTokens;
        accountTokens[minter] += mintTokens;
    }

    function redeem(address redeemer) public {
        uint256 redeemerBalance = accountTokens[redeemer];
        console2.log(
            "[CErc20Clone.redeem] CToken Balance before redeem",
            redeemerBalance
        );
        require(redeemerBalance > 0, "Insufficient balance");

        uint256 currentExchangeRate = exchangeRateStored();
        console2.log(
            "[CErc20Clone.redeem] Current Exchange Rate",
            currentExchangeRate
        );

        uint256 redeemAmount = (redeemerBalance * currentExchangeRate) / 1e18;
        console2.log(
            "[CErc20Clone.redeem] Underlying amount to be redeemed",
            redeemAmount
        );

        accountTokens[redeemer] = 0;
        totalSupply -= redeemerBalance;
        underlying.transfer(redeemer, redeemAmount);
    }

    function calculateMintAmount(
        uint256 mintAmount
    ) public view returns (uint256) {
        uint256 exchangeRate = exchangeRateStored();
        return (mintAmount * 1e18) / exchangeRate;
    }

    function exchangeRateStored() public view returns (uint256) {
        if (totalSupply == 0) {
            return initialExchangeRateMantissa;
        } else {
            uint256 totalCash = underlying.balanceOf(address(this));
            return (totalCash * 1e18) / totalSupply;
        }
    }
}
