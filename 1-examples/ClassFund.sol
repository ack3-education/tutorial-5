// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./Owned.sol";
import "./IClassFund.sol";

/// @title Class fund
/// @notice Classmates chip in ETH. The treasurer (owner) approves expenses,
///         and whoever paid for something withdraws their money back.
contract ClassFund is Owned, IClassFund {
    uint256 public constant MIN_CONTRIBUTION = 0.001 ether;

    mapping(address => uint256) private totals;      // contributed per address
    address[] private contributors;                  // keys of totals, in order of first contribution
    mapping(address => uint256) private owed;        // approved, not withdrawn yet
    uint256 private totalOwed;                       // sum of everything in owed
    uint256 private expenseCount;

    error TooSmall();
    error NotEnoughFunds();
    error NothingToWithdraw();
    error TransferFailed();

    constructor() Owned(msg.sender) {}

    // ------------------------------------------------------------ Money in
    function contribute() external payable {
        _contribute();
    }

    /// @notice Plain ETH sent to the fund (no function called) counts as a contribution.
    receive() external payable {
        _contribute();
    }

    function _contribute() private {
        if (msg.value < MIN_CONTRIBUTION) revert TooSmall();
        if (totals[msg.sender] == 0) contributors.push(msg.sender);
        totals[msg.sender] += msg.value;
        emit Contributed(msg.sender, msg.value);
    }

    // ------------------------------------------------------------ Bookkeeping
    function approveExpense(address to, uint256 amount) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        uint256 free = address(this).balance - totalOwed;    // not promised to anybody yet
        if (amount == 0 || amount > free) revert NotEnoughFunds();

        owed[to] += amount;
        totalOwed += amount;
        emit ExpenseApproved(expenseCount++, to, amount);
    }

    // ------------------------------------------------------------ Money out
    function withdraw() external {
        uint256 amount = owed[msg.sender];
        if (amount == 0) revert NothingToWithdraw();

        owed[msg.sender] = 0;                         // update our records first...
        totalOwed -= amount;
        emit Withdrawn(msg.sender, amount);

        (bool ok, ) = msg.sender.call{value: amount}("");   // ...send the ETH last
        if (!ok) revert TransferFailed();
    }

    // ------------------------------------------------------------ Override
    function transferOwnership(address newOwner) public override onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        super.transferOwnership(newOwner);
    }

    // ------------------------------------------------------------ Views
    function getOwed(address account) external view returns (uint256) {
        return owed[account];
    }

    /// @notice All contributors, biggest total first. Equal totals keep the order
    ///         of their first contribution.
    function getTopContributors() external view returns (Contributor[] memory list) {
        uint256 n = contributors.length;
        list = new Contributor[](n);
        for (uint256 i = 0; i < n; i++) {
            address a = contributors[i];
            list[i] = Contributor(a, totals[a]);
        }

        // insertion sort: stable, so equal totals keep their order
        for (uint256 i = 1; i < n; i++) {
            Contributor memory current = list[i];
            uint256 j = i;
            while (j > 0 && list[j - 1].total < current.total) {
                list[j] = list[j - 1];
                j--;
            }
            list[j] = current;
        }
    }
}
