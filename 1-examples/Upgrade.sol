// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice The proxy and every implementation share these first two storage slots.
abstract contract ProxyStorage {
    address public implementation;   // slot 0
    address public admin;            // slot 1
}

/// @notice Demo: an upgradeable counter.
/// Users always talk to the Proxy. Its fallback runs the implementation's code
/// on the proxy's own storage, so `count` survives an upgrade.
contract Proxy is ProxyStorage {
    event Upgraded(address indexed implementation);
    error NotAdmin();
    error CallFailed();

    constructor(address firstImplementation) {
        implementation = firstImplementation;
        admin = msg.sender;
    }

    /// @notice Only the admin may point the proxy at new code.
    function upgradeTo(address newImplementation) external {
        if (msg.sender != admin) revert NotAdmin();
        implementation = newImplementation;
        emit Upgraded(newImplementation);
    }

    /// @notice Every call the proxy doesn't know runs the implementation's code here.
    fallback(bytes calldata data) external returns (bytes memory) {
        (bool ok, bytes memory result) = implementation.delegatecall(data);
        if (!ok) revert CallFailed();
        return result;
    }
}

contract CounterV1 is ProxyStorage {
    uint256 public count;            // slot 2

    function increment() external {
        count += 1;
    }
}

contract CounterV2 is ProxyStorage {
    uint256 public count;            // slot 2: same place as in V1

    function increment() external {
        count += 10;                 // the new version counts in tens
    }

    function reset() external {
        count = 0;
    }
}
