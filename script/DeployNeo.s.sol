// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Neo} from "../src/Neo.sol";

contract DeployNeo is Script {
    function run() external returns (Neo) {
        vm.startBroadcast();
        Neo neo = new Neo();
        vm.stopBroadcast();
        return neo;
    }
}
