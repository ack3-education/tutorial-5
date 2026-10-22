// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice What the canteen needs to know about the credits contract.
interface IMealCredits {
    event Issued(address indexed student, uint256 amount);
    event LimitSet(address indexed owner, address indexed spender, uint256 limit);
    event Spent(address indexed from, address indexed to, address indexed spender, uint256 amount);
    event CreditsBought(address indexed student, uint256 amount);

    /// @notice Admin only: give credits to a student.
    function issue(address student, uint256 amount) external;

    /// @notice Buy `amount` credits, paying exactly amount * CREDIT_PRICE in ETH.
    function buyCredits(uint256 amount) external payable;

    /// @notice Credits held by an address.
    function getCredits(address account) external view returns (uint256);

    /// @notice Let `spender` spend up to `limit` of the caller's credits. Replaces any old limit.
    function allow(address spender, uint256 limit) external;

    /// @notice How many of `owner`'s credits `spender` may still spend.
    function limits(address owner, address spender) external view returns (uint256);

    /// @notice Called by a spender: move credits from `from` to `to`, within the limit `from` allowed it.
    function spendFrom(address from, address to, uint256 amount) external;
}
