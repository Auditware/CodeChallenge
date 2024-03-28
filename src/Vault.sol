// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VulnerableVault is Ownable {
    IERC20 public immutable token;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    struct Stake {
        uint256 amount;
        uint256 startTime;
    }
    mapping(address => Stake) public stakes;

    /// @param _token address of the vault's token contract
    /// @param _owner address of the owner of the entire vault (should be its creator)
    constructor(address _token, address _owner) Ownable(_owner) {
        token = IERC20(_token);
    }

    /// @param _to address to mint VTT for
    /// @param _amount amount of VTT to mint
    function _mint(address _to, uint _amount) private {
        totalSupply += _amount;
        balanceOf[_to] += _amount;
    }

    /// @param _from address whose VTT to burn
    /// @param _amount amount of VTT to burn
    function _burn(address _from, uint _amount) private {
        totalSupply -= _amount;
        balanceOf[_from] -= _amount;
    }

    /// @dev deposits a staker-defined amount in the vault
    /// @param _amount amount to deposit to the vault
    function deposit(uint _amount) external {
        stakes[msg.sender].amount += _amount;
        stakes[msg.sender].startTime = block.timestamp;

        uint shares;
        if (totalSupply == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupply) / getVaultBalance();
        }

        _mint(msg.sender, shares);
        token.transferFrom(msg.sender, address(this), _amount);
    }

    /// @dev withdraw from the vault, including additional staked tokens
    /// @param _amount amount of tokens to withdraw
    function withdraw(uint _amount) external {
        uint256 stakedAmount = stakes[msg.sender].amount;
        require(stakedAmount >= _amount, "Insufficient staked amount");

        uint256 yield = calculateYield(msg.sender);

        // Reset staking for the user - decrease withraw amount and reset time track to now
        stakes[msg.sender].amount -= _amount;
        stakes[msg.sender].startTime = block.timestamp;

        // Transfer the staked amount and yield to the user
        _burn(msg.sender, _amount);
        token.transfer(msg.sender, _amount + yield);
    }

    /// @dev calculate the additional tokens a staking user receives upon withdrawal
    /// @param _staker address of the user withdrawing funds
    function calculateYield(address _staker) public view returns (uint256) {
        Stake memory stake = stakes[_staker];
        uint256 stakingDuration = block.timestamp - stake.startTime;
        uint256 scaleFactor = 100000;
        uint256 balanceBasedBonus = (getVaultBalance() * 5) / 100;

        // The longer the stake duration the bigger the yield
        // The higher the stake amount the bigger the yield
        // The more total balance the vault has, the bigger the yield

        // to fix - remove balanceBasedBonus from the calculation alltogether
        uint256 yield = ((stakingDuration * stake.amount * balanceBasedBonus) /
            (totalSupply * scaleFactor));
        return yield + balanceBasedBonus;
    }

    /// @dev get this contract's balance
    function getVaultBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}