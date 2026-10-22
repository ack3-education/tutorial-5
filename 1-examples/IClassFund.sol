// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice What the outside world needs to know about the class fund.
interface IClassFund {
    struct Contributor {
        address account;
        uint256 total;
    }

    event Contributed(address indexed from, uint256 amount);
    event ExpenseApproved(uint256 indexed expenseId, address indexed to, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    function contribute() external payable;
    function approveExpense(address to, uint256 amount) external;
    function withdraw() external;
    function getOwed(address account) external view returns (uint256);
    function getTopContributors() external view returns (Contributor[] memory);
}
