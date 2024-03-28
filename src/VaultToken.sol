// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VaultToken is ERC20 {
    constructor() ERC20("VaultToken", "VTK") {}

    /// @param account address of the account to mint to
    /// @param amount amount to mint
    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    /// @param account address of the account to burn tokens from
    /// @param amount amount to burn
    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}