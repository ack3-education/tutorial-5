// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../1-examples/Owned.sol";      // the same Owned as in the example
import "./IMealCredits.sol";

/// @title Canteen
/// @notice Sells meals for 10 credits each and sends the credits to the kitchen.
///         Deploy MealCredits first, then the Canteen with MealCredits' address.
contract Canteen is Owned {
    uint256 public constant MEAL_PRICE = 10;

    IMealCredits public immutable credits;
    address public kitchen;          // address(0) until set
    uint256 public mealsSold;

    event KitchenSet(address kitchen);
    event MealBought(address indexed student);

    error AlreadySet();
    error NoKitchen();

    constructor(address creditsAddress) Owned(msg.sender) {
        credits = IMealCredits(creditsAddress);
    }

    /// TODO 3: owner only (the modifier is already there). The kitchen can be set once:
    /// revert with AlreadySet() if it is already set. Otherwise store it and emit KitchenSet.
    function setKitchen(address k) external onlyOwner {
    }

    /// TODO 4: revert with NoKitchen() if the kitchen isn't set.
    /// Otherwise have the credits contract move MEAL_PRICE credits from the caller
    /// to the kitchen, add 1 to mealsSold and emit MealBought.
    function buyMeal() external {
    }
}
