// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {DamnValuableToken} from "../src/Contracts/DamnValuableToken.sol";


contract Vault {
    bool public s_locked;
    bytes32 private s_password;
    uint256 public a;

    constructor(bytes32 password) {
        s_locked = true;
        s_password = password;
    }

    function unlock(bytes32 password) external {
        if (s_password == password) {
            s_locked = false;
        }
    }
}

contract AdvanceCheatcodes is Test {
    using stdStorage for StdStorage;

    DamnValuableToken internal erc20;
    Vault public vault;
    
    function setUp() public{
        erc20 = new DamnValuableToken();
        vault = new Vault("0x124__400x0");
    }

    function test_writeBalance() public {
        // set token balance to 1e18 and update totalSupply()
        deal(address(erc20),address(this),10e18,true);
    }
    function test_writeArbitrary() public{f
        stdstore
            .target(address(vault))
            .sig(vault.a.selector)
            .checked_write(100);
        assertEq(vault.a(),100);
    }
    
    function invariant_CannotUnlockVault() public view {
        assert(vault.s_locked());
    }

}