// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./IMealCredits.sol";

/// @title Meal credits
/// @notice Keeps every student's credits. Students buy them with ETH (or the admin
///         issues them), then let the canteen spend them.
contract MealCredits is IMealCredits {
    uint256 public constant CREDIT_PRICE = 0.001 ether;    // one credit

    address public immutable admin;

    mapping(address => uint256) private credits;
    mapping(address => mapping(address => uint256)) public limits;   // owner => spender => credits

    error NotAdmin();
    error OverLimit();
    error NotEnoughCredits();
    error WrongPayment();
    error TransferFailed();

    constructor() {
        admin = msg.sender;
    }

    function issue(address student, uint256 amount) external {
        if (msg.sender != admin) revert NotAdmin();
        credits[student] += amount;
        emit Issued(student, amount);
    }

    /// @notice Admin only: take out all the ETH paid for credits.
    function withdraw() external {
        if (msg.sender != admin) revert NotAdmin();
        (bool ok, ) = admin.call{value: address(this).balance}("");
        if (!ok) revert TransferFailed();
    }

    function getCredits(address account) external view returns (uint256) {
        return credits[account];
    }

    /// TODO 1: let `spender` spend up to `limit` of the caller's credits.
    /// A new call replaces the old limit. Emit LimitSet.
    function allow(address spender, uint256 limit) external {
    }

    /// TODO 2: the caller (msg.sender) is the spender.
    /// Revert with OverLimit() if `amount` is more than `from` allowed the caller,
    /// and with NotEnoughCredits() if `from` doesn't have `amount`.
    /// Otherwise lower the limit, move the credits from `from` to `to`, and emit Spent.
    function spendFrom(address from, address to, uint256 amount) external {
    }

    /// TODO 5: let the caller buy `amount` credits with ETH.
    /// The call must bring exactly amount * CREDIT_PRICE: revert with WrongPayment()
    /// if amount is 0 or msg.value is anything else. Otherwise add the credits to the
    /// caller and emit CreditsBought. The ETH stays in this contract.
    function buyCredits(uint256 amount) external payable {
    }
}
