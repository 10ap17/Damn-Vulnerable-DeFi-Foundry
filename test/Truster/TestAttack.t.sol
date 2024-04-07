//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import '../../src/Truster/Attack.sol';
import '../../src/DamnValuableToken.sol';
import '../../src/Truster/TrusterLenderPool.sol';

contract TestAttack is Test{
    DamnValuableToken token;
    TrusterLenderPool pool;
    Attack attacker;

    uint256 constant INITIAL_SUPPLY_POOL = 1000000;
    
    function setUp()external{
        token = new DamnValuableToken();
        pool =new TrusterLenderPool(token);
        attacker = new Attack();
        
        token.transfer(address(pool), INITIAL_SUPPLY_POOL);
    }
    function testDeployment()external view{
        
        assertEq(token.balanceOf(address(pool)), INITIAL_SUPPLY_POOL);
        assertEq(token.balanceOf(address(attacker)), 0);

    }
    function testTruster()external{
       
        attacker.attack(pool, token);
        assertEq(token.balanceOf(address(pool)),0);
        assertEq(token.balanceOf(address(attacker)), INITIAL_SUPPLY_POOL);
   
    }
}