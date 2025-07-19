// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {MockHelioAud} from "../mocks/mockHelioAud.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {HelioAud} from "../src/HelioAUD.sol";
import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    MockHelioAud mockasset = new MockHelioAud();
    HelioAud asset = new HelioAud();

    struct NetworkConfig {
        ERC20 activeAsset;
        uint256 deployerKey;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        }
        if (block.chainid == 31337) {
            activeNetworkConfig = getAnvilEthConfig();
        }
    }

    function getAnvilEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            activeAsset: mockasset,
            deployerKey: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        });
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({activeAsset: asset, deployerKey: vm.envUint("PRIVATE_KEY")});
    }
}
