// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {ESFVault} from "../src/ESFVault.sol";
import {HelioAud} from "../src/HelioAUD.sol";
import {MockHelioAud} from "../mocks/mockHelioAud.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DeployESFVault is Script {
    function run() external returns (ESFVault) {
        HelperConfig config = new HelperConfig();
        ERC20 asset = config.assetConfig();
        vm.startBroadcast();
        ESFVault esf = new ESFVault(asset);
        vm.stopBroadcast();
        return esf;
    }
}
