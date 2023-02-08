// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {DamnValuableToken} from "../src/Contracts/DamnValuableToken.sol";


contract B {
    uint256 public a;
}

contract AdvanceCheatcodes is Test {

    using stdStorage for StdStorage;

    DamnValuableToken internal erc20;
    B public b;
    
    function setUp() public{
        erc20 = new DamnValuableToken();
        b = new B();
    }

    function test_writeBalance() public {
        // set token balance to 1e18 and update totalSupply()
        deal(address(erc20),address(this),10e18,true);
    }
    function test_writeArbitrary() public{
        stdstore
            .target(address(b))
            .sig(b.a.selector)
            .checked_write(100);
        assertEq(b.a(),100);
    }

}