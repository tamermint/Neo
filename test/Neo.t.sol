// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test} from "lib/forge-std/src/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Neo} from "../src/Neo.sol";
import {DeployNeo} from "../script/DeployNeo.s.sol";

contract NeoTest is Test {
    Neo public neo;

    //State variables
    uint256 private immutable i_CAP = 20e18;

    uint256 public ethAllocation = 40e18;
    uint256 public btcAllocation = 60e18;

    uint256 public ethSigma = 21e18;
    uint256 public btcSigma = 4e18;

    address owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; //default foundry testing account
    address EXTERNAL = makeAddr("external");

    function setUp() external {
        DeployNeo deployer = new DeployNeo();
        neo = deployer.run();
    }

    function test_OwnerCanCallTrim() public {
        vm.prank(owner);
        neo.trim(ethSigma, ethAllocation, 2e18);
    }

    function test_ExternalCannotCallTrim() public {
        vm.expectRevert();
        vm.prank(EXTERNAL);
        neo.trim(ethSigma, ethAllocation, 2e18);
    }

    function test_AllocationCannotBeTrimmedWhenSigmaBelow20PP() public {
        vm.expectRevert();
        neo.trim(5e18, ethAllocation, 2e18);
    }

    function test_AllocationCannotBeTrimmedMoreThanOnceInSingleBlock() public {
        vm.prank(owner);
        neo.trim(21e18, ethAllocation, 2e18);
        vm.expectRevert();
        neo.trim(21e18, ethAllocation, 2e18);
    }

    function test_AllocationCanBeTrimmedOverMultipleBlocks() public {
        vm.prank(owner);
        neo.trim(21e18, ethAllocation, 2e18);
        vm.roll(block.number + 1);
        vm.prank(owner);
        neo.trim(21e18, ethAllocation, 2e18);
    }

    function test_TrimCannotBeAbove5pp() public {
        vm.expectRevert();
        neo.trim(21e18, ethAllocation, 21e18);
    }
    //todo: assertion is failing - start testing here

    function test_BufferRatioIsUpdatedAfterTrim() public {
        uint256 preTrimBufferRatio = neo.getBufferRatio();
        vm.prank(owner);
        neo.trim(21e18, ethAllocation, 2e18);
        uint256 postTrimBufferRatio = neo.getBufferRatio();
        assert(postTrimBufferRatio > preTrimBufferRatio);
    }

    function test_bufferRatioIsReturnedCorrectly() public view {
        uint256 bufferRatio = neo.getBufferRatio();
        assertEq(bufferRatio, 0);
    }

    function test_ethAllocationIsReturnedCorrectly() public view {
        uint256 ethAlloc = neo.getEthAllocation();
        assertEq(ethAlloc, 4e18);
    }

    function test_btcAllocationIsReturnedCorrectly() public view {
        uint256 btcAlloc = neo.getBtcAllocation();
        assertEq(btcAlloc, 6e18);
    }

    function test_ethSigmaIsReturnedCorrectly() public view {
        uint256 ethSig = neo.getEthSigma();
        assertEq(ethSig, 2e18);
    }

    function test_btcSigmaIsReturnedCorrectly() public view {
        uint256 btcSig = neo.getbtcSigma();
        assertEq(btcSig, 4e18);
    }
}
