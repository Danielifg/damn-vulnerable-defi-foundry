// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import "forge-std/Test.sol";
import {SafeCast, Math, SafeMath} from "../../../src/Contracts/puppet-v3/Libraries.sol";
import {
    IUniswapV3Factory,
    IUniswapV3Pool,
    INonfungiblePositionManager,
    IDamnValuableToken,
    IPuppetV3Pool,
    IWETH9
} from "../../../src/Contracts/puppet-v3/Interfaces.sol";

// contract PuppetV3 is Test {
//     DamnValuableToken internal dvt;
//     WETH9 internal weth;

//     IUniswapV3Factory internal uniswapFactory;
//     INonfungiblePositionManager internal uniswapPositionManager;
//     IUniswapV3Pool internal uniswapPool;
//     // PuppetV3Pool internal lendingPool;

//     address payable internal attacker;
//     address payable internal deployer;
//     address internal constant UNISWAPV3_FACTORY_MAINNET = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
//     address internal constant UNISWAP_POSITION_MANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
//     address payable internal constant WETH9_ADDRESS = payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
//     uint256 internal initialBlockTimestamp;

//     uint256 internal constant UNISWAP_INITIAL_TOKEN_LIQUIDITY = 100 ether;
//     uint256 internal constant UNISWAP_INITIAL_WETH_LIQUIDITY = 100 ether;
//     uint256 internal constant ATTACKER_INITIAL_TOKEN_BALANCE = 110 ether;
//     uint256 internal constant ATTACKER_INITIAL_ETH_BALANCE = 1 ether;
//     uint256 internal constant DEPLOYER_INITIAL_ETH_BALANCE = 200 ether;
//     uint256 internal constant LENDING_POOL_INITIAL_TOKEN_BALANCE = 1000000 ether;

//     function setUp() public {
//         // set player balance
//         attacker = payable(address(uint160(uint256(keccak256(abi.encodePacked("attacker"))))));
//         vm.label(attacker, "Attacker");
//         vm.deal(attacker, ATTACKER_INITIAL_ETH_BALANCE);
//         assertEq(attacker.balance, ATTACKER_INITIAL_ETH_BALANCE);

//         // set deployed balance

//         deployer = payable(address(uint160(uint256(keccak256(abi.encodePacked("deployer"))))));
//         vm.label(deployer, "deployer");
//         vm.deal(deployer, DEPLOYER_INITIAL_ETH_BALANCE + 1);
//         assertEq(deployer.balance, DEPLOYER_INITIAL_ETH_BALANCE + 1);

//         // Get a reference to the Uniswap V3 Factory contract
//         uniswapFactory = IUniswapV3Factory(UNISWAPV3_FACTORY_MAINNET);

//         // Get a reference to the Uniswap V3 Position Manager
//         uniswapPositionManager = INonfungiblePositionManager(UNISWAP_POSITION_MANAGER);

//         // Deploy custom WETH to createAndInitializePoolIfNecessary
//         weth = WETH9(WETH9_ADDRESS);
//         vm.label(address(weth), "weth");

//         // Deployer wraps ETH in WETH
//         vm.startPrank(deployer);
//         weth.deposit{value: UNISWAP_INITIAL_WETH_LIQUIDITY}();
//         assertEq(weth.balanceOf(deployer), UNISWAP_INITIAL_WETH_LIQUIDITY);

//         // Deploy DVT token. This is the token to be traded against WETH in the Uniswap v3 pool.
//         dvt = new DamnValuableToken();

//         // Create the Uniswap v3 pool
//         uint24 FEE = 3000; // 0.3%
//         testEncodePriceSqrt();
//         address uniswapPoolAddress = uniswapPositionManager.createAndInitializePoolIfNecessary(
//             address(dvt), // token0
//             address(weth), // token1
//             FEE,
//             1
//         );
//         // SafeCast.toUint160(encodePriceSqrt(1, 1))

//         assertEq(uniswapPoolAddress, uniswapFactory.getPool(address(dvt), address(weth), FEE));

//         uniswapPool = IUniswapV3Pool(uniswapPoolAddress);
//         uniswapPool.increaseObservationCardinalityNext(40);

//         // Deployer adds liquidity at current price to Uniswap V3 exchange
//         weth.approve(address(uniswapPositionManager), type(uint256).max);
//         dvt.approve(address(uniswapPositionManager), type(uint256).max);
//         uniswapPositionManager.mint(
//             INonfungiblePositionManager.MintParams({
//                 token0: address(dvt),
//                 token1: address(weth),
//                 tickLower: -60,
//                 tickUpper: 60,
//                 fee: FEE,
//                 recipient: address(deployer),
//                 amount0Desired: UNISWAP_INITIAL_WETH_LIQUIDITY,
//                 amount1Desired: UNISWAP_INITIAL_TOKEN_LIQUIDITY,
//                 amount0Min: 0,
//                 amount1Min: 0,
//                 deadline: block.timestamp * 2
//             })
//         );

//         // deploy the lending pool
//         // lendingPool = PuppetV3Pool(weth, dvt, uniswapPoolAddress);

//         // Setup initial token balances of lending pool and player
//         dvt.transfer(address(attacker), ATTACKER_INITIAL_TOKEN_BALANCE);
//         // dvt.transfer(address(lendingPool), LENDING_POOL_INITIAL_TOKEN_BALANCE);

//         // Some time passes
//         vm.warp(block.timestamp + 3 * 24 * 60 * 60); // 3 days in seconds

//         // Ensure oracle in lending pool is working as expected. At this point, DVT/WETH price should be 1:1.
//         // To borrow 1 DVT, must deposit 3 ETH
//         // assertEq(lendingPool.calculateDepositOfWETHRequired(1 ether), 3 ether);

//         // // To borrow all DVT in lending pool, user must deposit three times its value
//         // assertEq(
//         //     lendingPool.calculateDepositOfWETHRequired(LENDING_POOL_INITIAL_TOKEN_BALANCE),
//         //     LENDING_POOL_INITIAL_TOKEN_BALANCE * 3
//         // );

//         // Ensure player doesn't have that much ETH
//         assertLt(address(attacker).balance, LENDING_POOL_INITIAL_TOKEN_BALANCE * 3);

//         initialBlockTimestamp = block.timestamp;
//     }

//     // from https://github.com/Uniswap/v3-periphery/blob/5bcdd9f67f9394f3159dad80d0dd01d37ca08c66/test/shared/encodePriceSqrt.ts

//     // function encodePriceSqrt(uint256 reserve0, uint256 reserve1) internal view returns (uint256) {
//     //     UD60x18 priceFraction = sqrt(convert(reserve1).div(convert(reserve0)));
//     //     uint160 price = SafeCast.toUint160(convert(priceFraction));
//     //     console.log("1a", price);
//     //     return convert(priceFraction.mul(pow(convert(2), convert(96))));
//     // }

//     function testEncodePriceSqrt() public {
//         // BigNumber { value: "79228162514264337593543950336" } js version
//         uint160 priceSqrt = 79228162514264337593543950336;
//         // assertEq(priceSqrt, SafeCast.toUint160(encodePriceSqrt(1, 1)));

//         console.log("1: ", priceSqrt);
//         console.log("2: ", encodePriceSqrt2(1, 1));
//     }

//     function encodePriceSqrt2(uint256 reserve0, uint256 reserve1) public pure returns (uint160) {
//         return SafeCast.toUint160(Math.sqrt(reserve1 * SafeMath.div(1e18, reserve0)) * (1 << 96)) / 1e9;
//     }

//     function testExploit() public {
//         // validation();
//     }

//     function run() public {
//         testEncodePriceSqrt();
//     }

//     // function validation() internal {
//     //     assertLt(block.timestamp - initialBlockTimestamp, 115);
//     //     assertEq(dvt.balanceOf(address(lendingPool)), 0);
//     //     assertGt(dvt.balanceOf(address(attacker)), LENDING_POOL_INITIAL_TOKEN_BALANCE);
//     // }
// }
