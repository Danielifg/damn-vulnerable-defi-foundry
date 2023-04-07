// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "forge-std/Test.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol";
import {DamnValuableToken} from "../../../src/Contracts/DamnValuableToken.sol";

import {UD60x18, convert, sqrt, pow} from "@prb/math/UD60x18.sol";

contract PuppetV3 is Test {
    DamnValuableToken internal dvt;
    WETH9 internal weth;

    IUniswapV3Factory internal uniswapFactory;
    IERC20Minimal internal weth;
    // uniswapPositionManager;
    // uniswapPool;
    // lendingPool;

    address payable internal attacker;
    address payable internal deployer;
    address internal constant UNISWAPV3_FACTORY_MAINNET = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    uint256 internal initialBlockTimestamp;

    uint256 internal constant UNISWAP_INITIAL_TOKEN_LIQUIDITY = 100 ether;
    uint256 internal constant UNISWAP_INITIAL_WETH_LIQUIDITY = 100 ether;
    uint256 internal constant ATTACKER_INITIAL_TOKEN_BALANCE = 110 ether;
    uint256 internal constant ATTACKER_INITIAL_ETH_BALANCE = 1 ether;
    uint256 internal constant DEPLOYER_INITIAL_ETH_BALANCE = 200 ether;
    uint256 internal constant LENDING_POOL_INITIAL_TOKEN_BALANCE = 1000000 ether;

    function setUp() public {
        // set player balance
        vm.deal(attacker, ATTACKER_INITIAL_ETH_BALANCE);
        assertEq(attacker.balance, ATTACKER_INITIAL_ETH_BALANCE);

        // set deployed balance
        vm.deal(deployer, DEPLOYER_INITIAL_ETH_BALANCE);
        assertEq(deployer.balance, DEPLOYER_INITIAL_ETH_BALANCE);

        // Get a reference to the Uniswap V3 Factory contract
        uniswapFactory = IUniswapV3Factory(UNISWAPV3_FACTORY_MAINNET);

        dvt = new DamnValuableToken();
    }

    // @notice from https://github.com/Uniswap/v3-periphery/blob/5bcdd9f67f9394f3159dad80d0dd01d37ca08c66/test/shared/encodePriceSqrt.ts
    function encodePriceSqrt(uint256 reserve0, uint256 reserve1) internal pure returns (uint256) {
        UD60x18 priceFraction = sqrt(convert(reserve1).div(convert(reserve0)));
        return convert(priceFraction.mul(pow(convert(2), convert(96))));
    }

    function testEncodePriceSqrt() public {
        // BigNumber { value: "79228162514264337593543950336" } js version
        uint256 priceSqrt = 79228162514264337593543950336;
        assertEq(priceSqrt, encodePriceSqrt(1, 1));
    }

    function testExploit() public {
        validation();
    }

    function validation() internal {
        assertLt(block.timestamp - initialBlockTimestamp, 115);
        assertEq(dvt.balanceOf(address(lendingPool)), 0);
        assertGt(dvt.balanceOf(address(attacker)), LENDING_POOL_INITIAL_TOKEN_BALANCE);
    }
}
