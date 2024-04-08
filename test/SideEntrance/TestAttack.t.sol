pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import '../../src/SideEntrance/Attack.sol';
import '../../src/SideEntrance/SideEntranceLenderPool.sol';

contract TestAttack is Test{
    
    SideEntranceLenderPool pool;
    Attack attacker;

    uint256 constant INITIAL_BALANCE_POOL = 1000 ether;
    uint256 constant INITIAL_BALANCE_ATTACKER = 1 ether;
    
    function setUp()external{
        pool = new SideEntranceLenderPool();
        attacker = new Attack(pool);
        
        pool.deposit{value: INITIAL_BALANCE_POOL}();
        payable(address(attacker)).transfer(INITIAL_BALANCE_ATTACKER);

    }
    
    function testDeployment()external{
        assertEq(address(pool).balance, INITIAL_BALANCE_POOL);
        assertEq(address(attacker).balance, INITIAL_BALANCE_ATTACKER);
    }

    function testSideEntrance()external{
        attacker.attack();

        assertEq(address(pool).balance, 0);
        assertEq(address(attacker).balance, INITIAL_BALANCE_ATTACKER + INITIAL_BALANCE_POOL);
    }
}