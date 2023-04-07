// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import "forge-std/Test.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol";
// import {IWETH} from "@contracts/puppet-v3/Interfaces.sol";
// import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {DamnValuableToken} from "@contracts/DamnValuableToken.sol";

import {UD60x18, convert, sqrt, pow} from "@prb/math/UD60x18.sol";

contract PuppetV3 is Test {
    DamnValuableToken internal dvt;
    IWETH internal weth;

    IUniswapV3Factory internal uniswapFactory;
    // INonfungiblePositionManager internal uniswapPositionManager;
    // uniswapPool;
    // lendingPool;

    address payable internal attacker;
    address payable internal deployer;
    address internal constant UNISWAPV3_FACTORY_MAINNET = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address internal constant UNISWAP_POSITION_MANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
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

        // Deploy custom WETH to createAndInitializePoolIfNecessary
        // weth = new IWETH();

        // // // Deployer wraps ETH in WETH
        // weth.deposit(UNISWAP_INITIAL_WETH_LIQUIDITY);
        // assertEq(weth.balanceOf(deployer), UNISWAP_INITIAL_WETH_LIQUIDITY);

        // Deploy DVT token. This is the token to be traded against WETH in the Uniswap v3 pool.
        dvt = new DamnValuableToken();

        // Create the Uniswap v3 pool
        uint24 FEE = 3000; // 0.3%
        testEncodePriceSqrt();
        // uniswapPositionManager.createAndInitializePoolIfNecessary{gas: 5000000}(
        //     address(weth), // token0
        //     address(token), // token1
        //     FEE,
        //     encodePriceSqrt(1, 1)
        // );
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
