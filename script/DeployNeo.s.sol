// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Neo} from "../src/Neo.sol";

contract DeployNeo is Script {
    function run() external returns (Neo) {
        vm.startBroadcast(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);
        Neo neo = new Neo();
        vm.stopBroadcast();
        return neo;
    }
}
