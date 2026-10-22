// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../MealCredits.sol";
import "../Canteen.sol";

// ============================================================================
// Checks for the canteen: 2-exercise/MealCredits.sol and 2-exercise/Canteen.sol
//
// Deploy the check for the TODO you finished (no constructor arguments) and
// call run(). If your code works, the call goes through and says so. If not,
// it reverts with a message saying what is wrong. Each run() deploys fresh
// contracts, so redeploy the check after every change.
// ============================================================================

/// @notice A separate account the checks can use to act as another person.
contract Diner {
    function exec(address target, bytes calldata data) external returns (bool ok, bytes memory result) {
        (ok, result) = target.call(data);
    }
}

abstract contract CanteenCheckBase {
    function _selector(bytes memory result) internal pure returns (bytes4) {
        return result.length >= 4 ? bytes4(result) : bytes4(0);
    }

    function _allowAs(Diner who, MealCredits credits, address spender, uint256 limit) internal returns (bool ok) {
        (ok, ) = who.exec(address(credits), abi.encodeCall(IMealCredits.allow, (spender, limit)));
    }

    /// @dev Quick test of the earlier TODOs, so a missing one gets a clear message.
    function _requireDone(uint256 last) internal {
        MealCredits c = new MealCredits();
        c.allow(address(0xBEEF), 7);
        if (c.limits(address(this), address(0xBEEF)) != 7) revert("Finish TODO 1 first");
        if (last < 2) return;
        Diner p = new Diner();
        c.issue(address(p), 10);
        _allowAs(p, c, address(this), 10);
        try c.spendFrom(address(p), address(0xCAFE), 4) {} catch { revert("Finish TODO 2 first"); }
        if (c.getCredits(address(0xCAFE)) != 4 || c.limits(address(p), address(this)) != 6) revert("Finish TODO 2 first");
        if (last < 3) return;
        Canteen k = new Canteen(address(c));
        try k.setKitchen(address(0xCAFE)) {} catch { revert("Finish TODO 3 first"); }
        if (k.kitchen() != address(0xCAFE)) revert("Finish TODO 3 first");
        if (last < 4) return;
        c.issue(address(p), 10);
        _allowAs(p, c, address(k), 10);
        (bool ok, ) = p.exec(address(k), abi.encodeCall(Canteen.buyMeal, ()));
        if (!ok || k.mealsSold() != 1) revert("Finish TODO 4 first");
    }
}

contract Check1Allow is CanteenCheckBase {
    function run() external returns (string memory) {
        MealCredits credits = new MealCredits();
        address canteen = address(0xCA17);

        credits.allow(canteen, 30);
        require(credits.limits(address(this), canteen) == 30,
            "TODO 1: allow(spender, 30) should store 30 in limits[caller][spender]");
        credits.allow(canteen, 5);
        require(credits.limits(address(this), canteen) == 5, "TODO 1: a new allow should replace the old limit");
        require(credits.limits(canteen, address(this)) == 0,
            "TODO 1: the limit belongs to limits[owner][spender], not the other way round");
        return "TODO 1 works.";
    }
}

contract Check2SpendFrom is CanteenCheckBase {
    function run() external returns (string memory) {
        _requireDone(1);
        MealCredits credits = new MealCredits();          // this check is the admin
        Diner student = new Diner();
        address kitchen = address(0xCAFE);
        credits.issue(address(student), 30);
        _allowAs(student, credits, address(this), 20);     // this check is the spender

        try credits.spendFrom(address(student), kitchen, 10) {} catch {
            revert("TODO 2: spending within the limit should work");
        }
        require(credits.getCredits(address(student)) == 20 && credits.getCredits(kitchen) == 10,
            "TODO 2: move the credits from `from` to `to`");
        require(credits.limits(address(student), address(this)) == 10, "TODO 2: lower the limit by the amount spent");

        try credits.spendFrom(address(student), kitchen, 11) {
            revert("TODO 2: spending more than the limit must revert");
        } catch (bytes memory r) {
            require(_selector(r) == MealCredits.OverLimit.selector, "TODO 2: spending more than the limit must revert with OverLimit");
        }

        Diner stranger = new Diner();
        (bool ok, ) = stranger.exec(address(credits), abi.encodeCall(IMealCredits.spendFrom, (address(student), kitchen, 1)));
        require(!ok, "TODO 2: someone the student never allowed must not be able to spend");

        _allowAs(student, credits, address(this), 100);
        try credits.spendFrom(address(student), kitchen, 25) {
            revert("TODO 2: spending more credits than `from` has must revert");
        } catch (bytes memory r) {
            require(_selector(r) == MealCredits.NotEnoughCredits.selector,
                "TODO 2: spending more credits than `from` has must revert with NotEnoughCredits");
        }
        return "TODO 2 works. Look for Spent in the log when you try it by hand.";
    }
}

contract Check3Kitchen is CanteenCheckBase {
    function run() external returns (string memory) {
        MealCredits credits = new MealCredits();
        Canteen canteen = new Canteen(address(credits));    // this check is the owner

        canteen.setKitchen(address(0xCAFE));
        require(canteen.kitchen() == address(0xCAFE), "TODO 3: setKitchen should store the kitchen");
        try canteen.setKitchen(address(0xBEEF)) {
            revert("TODO 3: the kitchen can be set only once");
        } catch (bytes memory r) {
            require(_selector(r) == Canteen.AlreadySet.selector, "TODO 3: a second setKitchen must revert with AlreadySet");
        }
        require(canteen.kitchen() == address(0xCAFE), "TODO 3: a refused setKitchen must not change the kitchen");
        return "TODO 3 works.";
    }
}

contract Check4BuyMeal is CanteenCheckBase {
    function run() external returns (string memory) {
        _requireDone(3);
        MealCredits credits = new MealCredits();
        Canteen canteen = new Canteen(address(credits));
        Diner student = new Diner();
        address kitchen = address(0xCAFE);

        (bool ok, bytes memory r) = student.exec(address(canteen), abi.encodeCall(Canteen.buyMeal, ()));
        require(!ok && _selector(r) == Canteen.NoKitchen.selector, "TODO 4: buying before the kitchen is set must revert with NoKitchen");

        canteen.setKitchen(kitchen);
        credits.issue(address(student), 30);
        (ok, ) = student.exec(address(canteen), abi.encodeCall(Canteen.buyMeal, ()));
        require(!ok, "TODO 4: without the student's permission the canteen must not be able to take credits");

        _allowAs(student, credits, address(canteen), 30);
        (ok, ) = student.exec(address(canteen), abi.encodeCall(Canteen.buyMeal, ()));
        require(ok, "TODO 4: after allow(canteen, 30), buyMeal should work. Call credits.spendFrom(msg.sender, kitchen, MEAL_PRICE)");
        require(credits.getCredits(address(student)) == 20 && credits.getCredits(kitchen) == 10,
            "TODO 4: a meal moves 10 credits from the student to the kitchen");
        require(canteen.mealsSold() == 1, "TODO 4: add 1 to mealsSold");
        return "TODO 4 works. Look for MealBought in the log when you buy by hand.";
    }
}

contract Check5BuyCredits is CanteenCheckBase {
    receive() external payable {}

    /// @notice Call run() with 0.01 ether. Whatever the check doesn't spend is sent back to you.
    function run() external payable returns (string memory) {
        require(msg.value == 0.01 ether, "Call run() with exactly 0.01 ether");
        MealCredits credits = new MealCredits();
        uint256 price = credits.CREDIT_PRICE();

        try credits.buyCredits{value: 3 * price}(3) {} catch {
            revert("TODO 5: buyCredits(3) with exactly 3 * CREDIT_PRICE should work");
        }
        require(credits.getCredits(address(this)) == 3, "TODO 5: buyCredits(3) should add 3 credits to the caller");

        try credits.buyCredits{value: 2 * price}(3) {
            revert("TODO 5: paying too little must revert");
        } catch (bytes memory r) {
            require(_selector(r) == MealCredits.WrongPayment.selector, "TODO 5: paying too little must revert with WrongPayment");
        }
        try credits.buyCredits{value: 4 * price}(3) {
            revert("TODO 5: paying too much must revert");
        } catch (bytes memory r) {
            require(_selector(r) == MealCredits.WrongPayment.selector, "TODO 5: paying too much must revert with WrongPayment");
        }
        try credits.buyCredits(0) {
            revert("TODO 5: buying 0 credits must revert");
        } catch (bytes memory r) {
            require(_selector(r) == MealCredits.WrongPayment.selector, "TODO 5: buying 0 credits must revert with WrongPayment");
        }
        require(address(credits).balance == 3 * price, "TODO 5: the ETH paid should stay in MealCredits");

        (bool ok, ) = msg.sender.call{value: address(this).balance}("");   // the rest goes back to you
        require(ok, "Could not send the rest of the ETH back");
        return "TODO 5 works. Look for CreditsBought in the log when you try it by hand.";
    }
}

contract Check6Together is CanteenCheckBase {
    function run() external returns (string memory) {
        _requireDone(4);
        // deploy in dependency order, then wire
        MealCredits credits = new MealCredits();
        Canteen canteen = new Canteen(address(credits));
        address kitchen = address(0xCAFE);
        canteen.setKitchen(kitchen);

        Diner ada = new Diner();
        Diner bob = new Diner();
        credits.issue(address(ada), 30);
        credits.issue(address(bob), 30);
        _allowAs(ada, credits, address(canteen), 20);
        _allowAs(bob, credits, address(canteen), 30);

        bytes memory buy = abi.encodeCall(Canteen.buyMeal, ());
        (bool a1, ) = ada.exec(address(canteen), buy);
        (bool a2, ) = ada.exec(address(canteen), buy);
        (bool a3, ) = ada.exec(address(canteen), buy);     // over Ada's limit of 20
        (bool b1, ) = bob.exec(address(canteen), buy);
        require(a1 && a2 && b1, "Together: three meals within the limits should be sold");
        require(!a3, "Together: a third meal for Ada goes over her limit of 20 and must fail");
        require(credits.getCredits(kitchen) == 30 && canteen.mealsSold() == 3,
            "Together: the kitchen should end with 30 credits after 3 meals");
        require(credits.getCredits(address(ada)) == 10 && credits.getCredits(address(bob)) == 20,
            "Together: Ada should have 10 credits left and Bob 20");
        return "Everything works together: 3 meals sold, the kitchen has 30 credits.";
    }
}
