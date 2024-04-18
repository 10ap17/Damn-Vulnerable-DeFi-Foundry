# Damn-Vulnerable-DeFi-Foundry
## Unstoppable
This is an example of Denial of Service where the line `convertToShares(totalSupply) != balanceBefore` is vulnerable. So, by sending any amount of tokens, that is greater than 0, we could cause Denial of Service
## Naive receiver
In the `function flashLoan()`, the pool initiates a flash loan by transferring ETH to the receiver and allowing it to execute arbitrary logic. However, the `function onFlashLoan()` in the receiver contract doesn't properly validate the caller's identity, allowing anyone to invoke it. By exploiting this vulnerability, an attacker can repeatedly trigger the `function flashLoan()`, draining the receiver's ETH balance by forcing it to pay the fixed fee with each loan. This attack effectively takes all ETH held by the receiver contract, exploiting the lack of proper authorization checks in the `function onFlashLoan()`.
### Solution
