// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {MockHelioAud} from "../mocks/mockHelioAud.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {HelioAud} from "../src/HelioAUD.sol";
import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    MockHelioAud mockasset = new MockHelioAud();
    HelioAud asset = new HelioAud();

    ERC20 public assetConfig;

    constructor() {
        if (block.chainid == 11155111) {
            assetConfig = getAsset();
        }
        if (block.chainid == 31337) {
            assetConfig = getMockAsset();
        }
    }

    function getMockAsset() public view returns (MockHelioAud) {
        return mockasset;
    }

    function getAsset() public view returns (HelioAud) {
        return asset;
    }
}
