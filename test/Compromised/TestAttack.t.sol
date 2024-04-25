//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import '../../src/Compromised/Attack.sol';
import '../../src/Compromised/TrustfulOracleInitializer.sol';
import '../../src/Compromised/TrustfulOracle.sol';
import '../../src/Compromised/Exchange.sol';


contract TestAttack is Test{

    TrustfulOracleInitializer initializer;
    TrustfulOracle oracle;
    Exchange exchange;
    Attack attacker;

    address[] sources = new address[](3);

    uint256 constant INITIAL_EXCHANGE_ETH_BALANCE = 999*10**18;
    uint256 constant INITIAL_NFT_PRICE = 999*10**18;
    uint256 constant INITIAL_PLAYER_ETH_BALANCE = 1 *10**17;
    uint256 constant INITIAL_TRUSTED_SOURCE_ETH_BALANCE = 2*10**18;

    function setUp()external{
        
            sources[0] = 0xA73209FB1a42495120166736362A1DfA9F95A105;
            sources[1] = 0xe92401A4d3af5E446d93D11EEc806b1462b39D15;
            sources[2] = 0x81A5D6E50C214044bE44cA0CB057fe119097850c;

        string[] memory strings =  new string[](3);
        uint256[] memory numbers = new uint256[](3);

        for(uint256 i; i<3; i++){
            deal(sources[i], INITIAL_TRUSTED_SOURCE_ETH_BALANCE);
            strings[i]= "DVNFT";
            numbers[i]= INITIAL_NFT_PRICE;
        }
        
        initializer = new TrustfulOracleInitializer(sources, strings, numbers);
        oracle = initializer.oracle();
        exchange = new Exchange{value: INITIAL_EXCHANGE_ETH_BALANCE}(address(oracle));
        attacker = new Attack();

        vm.deal(address(attacker), INITIAL_PLAYER_ETH_BALANCE);
    }

    function testDeployment()external{
        for(uint256 i; i<3; i++){
            assertEq(sources[i].balance, INITIAL_TRUSTED_SOURCE_ETH_BALANCE);
        }
        assertEq(address(attacker).balance, INITIAL_PLAYER_ETH_BALANCE);
    }
    function testAttack()external{
        for(uint256 i; i<3; i++){
            vm.prank(sources[i]);
            oracle.postPrice("DVNFT", 0);
        }
        assertEq(oracle.getMedianPrice("DVNFT"), 0);
    }
}