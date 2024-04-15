pragma solidity ^0.8.0;

import {Test, console} from 'forge-std/Test.sol';
import '../../src/Selfie/Attack.sol';
import '../../src/Selfie/SimpleGovernance.sol';
import '../../src/Selfie/SelfiePool.sol';
import '../../src/DamnValuableTokenSnapshot.sol';

contract TestAttack is Test{
    
    DamnValuableTokenSnapshot token;
    SimpleGovernance governance;
    SelfiePool pool;
    Attack attacker;

    uint256 constant INITIAL_SUPPLY_TOKEN = 2000000 *10**18;
    uint256 constant INITIAL_SUPPLY_POOL = 1500000 *10**18;
    uint256 constant ACTION_DELAY = 60*60*24*2;

    function setUp()external{

        token = new DamnValuableTokenSnapshot(INITIAL_SUPPLY_TOKEN);
        governance = new SimpleGovernance(address(token));
        pool = new SelfiePool(address(token), address(governance));
        attacker = new Attack(governance, pool, token);

        token.transfer(address(pool), INITIAL_SUPPLY_POOL);
        token.snapshot();
    
    }

    function testDeployment()external{

        assertEq(token.balanceOf(address(pool)), INITIAL_SUPPLY_POOL);
        assertEq(token.totalSupply(),INITIAL_SUPPLY_TOKEN);
        assertEq(token.getBalanceAtLastSnapshot(address(pool)), INITIAL_SUPPLY_POOL);
        
    }

    function testAttack()external{
        
        attacker.attack1();
        uint256 time = block.timestamp;

        skip(ACTION_DELAY);
        assertEq(block.timestamp, time + ACTION_DELAY);

        attacker.attack2();
        assertEq(token.balanceOf(address(attacker)), INITIAL_SUPPLY_POOL);
        assertEq(token.balanceOf(address(pool)), 0);
    
    }
}