# Tutorial 5: Contracts working together

You need:

- [VS Code](https://code.visualstudio.com/)
- the [Solidity (Wake)](https://marketplace.visualstudio.com/items?itemName=AckeeBlockchain.tools-for-solidity) extension

Open this folder in VS Code and deploy from the extension's Deploy & Interact panel.
Compiler 0.8.26.

| Folder | What is in it | What you do |
|:--|:--|:--|
| `1-examples/` | `Owned`, `IClassFund`, `ClassFund`, `Donor`, `Upgrade` | click through ClassFund and Donor; `Upgrade` is shown in class |
| `2-exercise/` | `IMealCredits`, `MealCredits`, `Canteen` | fill in five TODOs |
| `2-exercise/checks/` | `CanteenChecks` | deploy one check per TODO and call `run()` |

Only `2-exercise` has TODOs. `Canteen` imports `Owned` from `1-examples`: the same parent
contract that `ClassFund` uses.

## 1. Example: ClassFund and Donor (`1-examples/`)

1. Deploy `ClassFund` from the first account (the treasurer).
2. Copy its address. Deploy `Donor` with that address in the constructor field.
3. From the second account, call `donate` on Donor with 1 ETH.
4. Call `getTopContributors` on ClassFund: the contributor is the Donor contract, not you.
5. As the treasurer, `approveExpense(<third account>, 1000000000000000000)` (1 ether in wei).
   From the third account, `withdraw`, then `withdraw` again: the second one reverts.

## 2. Upgrade.sol: shown in class

You don't have to deploy it. It is the proxy and the two counter versions from the slides:
read it along while the upgrade is demonstrated.

## 3. Build: the canteen (`2-exercise/`)

`MealCredits` keeps every student's credits; students buy them with ETH, one credit for
`CREDIT_PRICE` = 0.001 ether. The `Canteen` sells meals for 10 credits and sends them to the
kitchen.

| TODO | File | Function | Check |
|:--|:--|:--|:--|
| 1 | `MealCredits.sol` | `allow` | `Check1Allow` |
| 2 | `MealCredits.sol` | `spendFrom` | `Check2SpendFrom` |
| 3 | `Canteen.sol` | `setKitchen` | `Check3Kitchen` |
| 4 | `Canteen.sol` | `buyMeal` | `Check4BuyMeal` |
| 5 | `MealCredits.sol` | `buyCredits` (payable) | `Check5BuyCredits`, call `run()` with 0.01 ether |
| last | (no code) | wire it by hand, below | `Check6Together` runs the whole flow |

After each TODO, open `2-exercise/checks/CanteenChecks.sol`, deploy the check with the TODO's
number and call `run()`. Redeploy the check after every change. `Check5BuyCredits` needs
0.01 ether sent with `run()`; it sends back whatever it doesn't spend.

**Last step, wiring by hand:**

1. Deploy `MealCredits` from the first account (the admin).
2. Deploy `Canteen` with MealCredits' address.
3. `setKitchen` with the third account's address.
4. As the second account: `buyCredits(30)` on MealCredits with 0.03 ether.
5. Still as the second account: `allow(<canteen address>, 30)` on MealCredits, then `buyMeal()` on the Canteen.
6. `getCredits`: the student has 20, the kitchen 10.

## 4. Finished early? Break it on purpose

| Try | You will see |
|:--|:--|
| `buyMeal` without `allow` | `OverLimit`, from inside MealCredits |
| `setKitchen` a second time | `AlreadySet` |
| `setKitchen` from the second account | `NotOwner`, from Owned |
| `buyCredits(3)` with 0.002 ether | `WrongPayment` |
| `allow(canteen, 10)`, then buy two meals | the second one reverts |

---

Part of [ack3 education](https://github.com/ack3-education): hands-on material for
[NIE-BLO](https://courses.fit.cvut.cz/NIE-BLO/) at FIT ČVUT, published by [ack3](https://ack3.ai).
Contracts compile and deploy with [Wake](https://github.com/ack3-ai/wake) for VS Code.
