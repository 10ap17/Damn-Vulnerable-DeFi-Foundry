//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import '../../src/NaiveReceiver/Attack.sol';
import '../../src/NaiveReceiver/FlashLoanReceiver.sol';
import '../../src/NaiveReceiver/NaiveReceiverLenderPool.sol';


contract TestAttack is Test{
    Attack attacker;
    FlashLoanReceiver receiver;
    NaiveReceiverLenderPool pool;
    uint256 constant INITIAL_BALANCE_POOL = 1000 ether;
    uint256 constant INITIAL_BALANCE_RECEIVER = 10 ether;
    uint256 constant FINAL_BALANCE_POOL = 1010 ether;
    function setUp()external{
        attacker = new Attack();
        pool = new NaiveReceiverLenderPool();
        receiver = new FlashLoanReceiver(address(pool));

        vm.prank(msg.sender);
        payable(address(pool)).transfer(INITIAL_BALANCE_POOL);
        vm.prank(msg.sender);
        payable(address(receiver)).transfer(INITIAL_BALANCE_RECEIVER);
    }
    function testDeployment()external view{
        
        assertEq(address(pool).balance, INITIAL_BALANCE_POOL);
        assertEq(address(receiver).balance, INITIAL_BALANCE_RECEIVER);
        
    }

    function testNaiveReceiver()external{
        attacker.attack(receiver , pool);
        assertEq(address(receiver).balance, 0);
        assertEq(address(pool).balance, FINAL_BALANCE_POOL);
    }
}