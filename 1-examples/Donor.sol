// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./IClassFund.sol";

/// @notice Example: one contract calling another through its interface.
///         Deploy ClassFund first, then Donor with ClassFund's address.
contract Donor {
    IClassFund public immutable fund;          // the contract we talk to

    constructor(address fundAddress) {
        fund = IClassFund(fundAddress);        // given once, at deployment
    }

    /// @notice Pass all the ETH sent with this call on to the fund.
    ///         Inside the fund, msg.sender is this Donor contract.
    function donate() external payable {
        fund.contribute{value: msg.value}();
    }
}
