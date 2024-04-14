pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
//import '../../src/Selfie/Attack.sol';
import '../../src/Selfie/SimpleGovernance.sol';
import '../../src/Selfie/SelfiePool.sol';
import '../../src/DamnValuableTokenSnapshot.sol';

contract TestAttack is Test{
    
    DamnValuableTokenSnapshot token;
    SimpleGovernance governance;
    SelfiePool pool;

    uint256 constant INITIAL_SUPPLY_TOKEN = 2000000 *10**18;
    uint256 constant INITIAL_SUPPLY_POOL = 1500000 *10**18;

    function setUp()external{

        token = new DamnValuableTokenSnapshot(INITIAL_SUPPLY_TOKEN);
        governance = new SimpleGovernance(address(token));
        pool = new SelfiePool(address(token), address(governance));

        token.transfer(address(pool), INITIAL_SUPPLY_POOL);
        token.snapshot();
    }

    function testDeployment()external{
        assertEq(token.balanceOf(address(pool)), INITIAL_SUPPLY_POOL);
        assertEq(token.totalSupply(),INITIAL_SUPPLY_TOKEN);
        assertEq(token.getBalanceAtLastSnapshot(address(pool)), INITIAL_SUPPLY_POOL);
        
    }
}