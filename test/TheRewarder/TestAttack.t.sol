//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from 'forge-std/Test.sol';
import '../../src/TheRewarder/Attack.sol';
import '../../src/TheRewarder/TheRewarderPool.sol';
import '../../src/TheRewarder/FlashLoanerPool.sol';
import '../../src/DamnValuableToken.sol';



contract TestAttack is Test{
    
    DamnValuableToken liquidityToken;
    FlashLoanerPool flashPool;
    TheRewarderPool rewarderPool;
    Attack attacker;
    RewardToken rewardToken;
    AccountingToken accountingToken;

    uint256 constant INITIAL_SUPPLY_LENDER_POOL= 1000000*10**18;
    uint256 constant TIME_TO_SKIP= 5*24*60*60;
    uint256 constant DEPOSIT_AMOUNT= 100*10**18;
    uint256 rewardInRound;

    string[] public users = ["Alice", "Bob", "Charlie", "David"];

    uint256 firstTime;

    function setUp()external{
        liquidityToken = new DamnValuableToken();
        flashPool = new FlashLoanerPool(address(liquidityToken));
        rewarderPool =new TheRewarderPool(address(liquidityToken));
        attacker = new Attack(flashPool, rewarderPool, liquidityToken);
        
        rewardInRound= rewarderPool.REWARDS();
        
        liquidityToken.transfer(address(flashPool), INITIAL_SUPPLY_LENDER_POOL);

        rewardToken= rewarderPool.rewardToken();
        accountingToken= rewarderPool.accountingToken();

        for(uint256 i; i < users.length; i++){
            address userAddr = makeAddr(users[i]);
            liquidityToken.transfer(userAddr, DEPOSIT_AMOUNT);
            vm.prank(userAddr);
            liquidityToken.approve(address(rewarderPool), DEPOSIT_AMOUNT);
            vm.prank(userAddr);
            rewarderPool.deposit(DEPOSIT_AMOUNT);

        }

        skip(TIME_TO_SKIP);

        for(uint256 i; i < users.length; i++){
            address userAddr = makeAddr(users[i]);
            vm.prank(userAddr);
            rewarderPool.distributeRewards();
        }
    }

    function testDeployment()external{
        assertEq(liquidityToken.balanceOf(address(flashPool)), INITIAL_SUPPLY_LENDER_POOL);
        assertEq(liquidityToken.balanceOf(address(attacker)), 0);
        assertEq(accountingToken.totalSupply(), DEPOSIT_AMOUNT * users.length);
        assertEq(rewarderPool.roundNumber(), 2);

        for(uint256 i; i < users.length; i++){
            assertEq(rewardToken.balanceOf(makeAddr(users[i])), rewardInRound/users.length);
        }
    }

    function testAttack()external{
        skip(TIME_TO_SKIP);

        attacker.attack();

        assertApproxEqAbs(rewardToken.balanceOf(address(attacker)), rewardInRound, 10**18);
        assertEq(rewarderPool.roundNumber(), 3);
        assertEq(liquidityToken.balanceOf(address(flashPool)), INITIAL_SUPPLY_LENDER_POOL);
        assertEq(liquidityToken.balanceOf(address(flashPool)), INITIAL_SUPPLY_LENDER_POOL);
        assertEq(liquidityToken.balanceOf(address(attacker)), 0);
    }
}