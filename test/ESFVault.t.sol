// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
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
    MockHelioAud public asset;
    address alice = makeAddr("0xABCD");
    address owner = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38; //default foundry testing account
    uint256 public constant deployerkey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public STARTING_BALANCE = 100 ether;

    function setUp() public {
        asset = new MockHelioAud();
        esf = new ESFVault(asset);
        MockHelioAud(address(asset)).mint(alice, STARTING_BALANCE);
        //deposit from erc4626 uses transferFrom so we need to approve Alice
        vm.startPrank(alice);
        asset.approve(address(esf), type(uint256).max);
        vm.stopPrank();
    }

    //////////////////////
    //Constructor Test///
    //////////////////////
    function test__VaultInitialisedCorrectly() public view {
        address checkAsset = esf.asset();
        uint256 vaultSupply = esf.totalSupply();
        uint256 vaultAssets = esf.totalAssets();
        address vaultOwner = esf.owner();
        string memory name = esf.name();
        string memory symbol = esf.symbol();
        assertEq(vaultOwner, 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        assertEq(name, "ESF Vault Share");
        assertEq(symbol, "ESFV");
        assertEq(checkAsset, address(asset));
        assertEq(vaultSupply, 0);
        assertEq(vaultAssets, 0);
    }

    //////////////////////
    ////DEPOSIT TESTS/////
    //////////////////////

    function test__CantDepositZeroAmount() public {
        vm.expectRevert(ESFVault.ESF__CannotDepositZero.selector);
        vm.prank(alice);
        esf.deposit(0, alice);
    }

    function test__ReceiverCantBeZeroAddress() public {
        vm.expectRevert(ESFVault.ESF__ReceiverCantBeZeroAddress.selector);
        vm.prank(alice);
        esf.deposit(1 ether, address(0));
    }

    function test__DepositEventIsEmitted() public {
        vm.expectEmit(true, true, true, true);
        vm.prank(alice);
        esf.deposit(10 ether, alice);
    }

    function test__SharesAreMintedToAlice() public {
        vm.prank(alice);
        uint256 shares = esf.deposit(10 ether, alice);
        uint256 sharesOfAlice = esf.balanceOf(alice);
        assertEq(shares, sharesOfAlice);
    }

    //////////////////////
    ////GETTER TEST///////
    //////////////////////

    function test__HBRReturnedCorrectly() public view {
        uint256 hbr = esf.HBR();
        assertEq(hbr, 1.12e18);
    }
}
