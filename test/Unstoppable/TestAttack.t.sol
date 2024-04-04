//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import '../../src/Unstoppable/Attack.sol';
import '../../src/DamnValuableToken.sol';
import '../../src/Unstoppable/UnstoppableVault.sol';
import '../../src/Unstoppable/ReceiverUnstoppable.sol';

contract TestAttack is Test{
    DamnValuableToken token;
    UnstoppableVault vault;
    Attack attacker;
    ReceiverUnstoppable receiver;

    uint256 constant INITIAL_SUPPLY_VAULT = 1000000;
    uint256 constant INITIAL_SUPPLY_ATTACKER = 10;
    function setUp()external{
        token = new DamnValuableToken();
        vault = new UnstoppableVault(token, address(this), address(this));
        attacker = new Attack();
        receiver= new ReceiverUnstoppable(address(vault));

        token.approve(address(vault), INITIAL_SUPPLY_VAULT);
        vault.deposit(1000000, address(this));
        token.transfer(address(attacker), INITIAL_SUPPLY_ATTACKER);
    }
    function testDeployment()external view{
        
        assertEq(token.balanceOf(address(attacker)), INITIAL_SUPPLY_ATTACKER);

        assertEq(token.balanceOf(address(vault)), INITIAL_SUPPLY_VAULT);
    }
    function testDenialOfService()external{
       
        attacker.attack(token, vault);
        vm.expectRevert();
        vault.flashLoan(receiver, address(token), 1017, "");
   
    }
}