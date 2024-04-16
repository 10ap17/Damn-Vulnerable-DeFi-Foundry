## Damn-Vulnerable-DeFi-Foundry
## Unstoppable
This is an example of Denial of Service where the line `convertToShares(totalSupply) != balanceBefore` is vulnerable. So, by sending any amount of tokens, that is greater than 0, we could cause Denial of Service