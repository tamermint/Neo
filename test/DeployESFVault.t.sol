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

contract DeployESFVaultTest is Test {
    ESFVault esf;
    DeployESFVault deployer = new DeployESFVault();
    MockHelioAud mock = new MockHelioAud();

    function _deploy(ERC20 asset) internal returns (ESFVault) {
        esf = new ESFVault(asset);
        return esf;
    }

    function testDeployWorks() public {
        esf = _deploy(mock);
        assertEq(esf.asset(), address(mock));
    }
}
