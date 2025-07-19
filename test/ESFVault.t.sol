// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test} from "lib/forge-std/src/Test.sol";
import {console2} from "forge-std/console2.sol";
import {ESFVault} from "../src/ESFVault.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MockHelioAud} from "../mocks/mockHelioAud.sol";
import {HelioAud} from "../src/HelioAUD.sol";
import {DeployESFVault} from "../script/DeployESFVault.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract ESFVaultTest is Test {
    ESFVault public esf;
    DeployESFVault public deployer;
    HelperConfig helper;
    ERC20 public asset;
    address alice = makeAddr("0xABCD");
    address owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; //default foundry testing account
    uint256 public STARTING_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployESFVault();
        if (block.chainid == 31337) {
            MockHelioAud(address(asset)).mint(alice, STARTING_BALANCE);
        }
        if (block.chainid == 11155111) {
            HelioAud(address(asset)).mint(alice, STARTING_BALANCE);
        }
        //deposit from erc4626 uses transferFrom so we need to approve Alice
        esf = deployer.run();
        vm.prank(alice);
        asset.approve(address(esf), type(uint256).max);
    }
}
