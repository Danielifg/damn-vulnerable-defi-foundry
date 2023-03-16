// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/Script.sol";

contract A {
    uint256 public a = 100;
}
contract Deployment is Test, Script{
    function run() public returns(uint256){
        vm.broadcast();
        A s = new A();
        return s.a();
    }
 } 