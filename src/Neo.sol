// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @author Vivek Mitra
 * @notice This contract emulates a guardrail condition for dynamic asset allocation strategy
 * @notice Similar to a Comprehensive Portfolio Risk Insurance
 * @notice this contract stores a buffer ratio which denominates the percentage allocation
 * @notice it implements a trim function which updates buffer ratio based on volatility
 * @notice verifies an oracle proof before allowing trim function
 */
contract Neo is Ownable(msg.sender) {
    //EVENTS
    event VolTrim(string, uint256, uint256);

    //ERRORS
    error Neo__TrimIsAbove5PP();

    //STATE VARIABLES
    uint256 public bufferRatio;
    uint256 public lastTrimBlock;
    uint256 private immutable i_CAP = 20e18;

    uint256 public ethAllocation = 4e18;
    uint256 public btcAllocation = 6e18;

    uint256 public ethSigma = 2e18;
    uint256 public btcSigma = 4e18;

    //FUNCTIONS
    /**
     * @notice check sigma and trim allocationand then emit trim event
     * @notice simple way to ensure that 5pp trim happens gradually over multiple blocks
     * @param assetSigma the reported sigma of the asset
     * @param assetAllocation the allocation of each asset
     */
    function trim(uint256 assetSigma, uint256 assetAllocation, uint256 trimpp) public onlyOwner {
        if (assetSigma >= i_CAP && lastTrimBlock < block.number) {
            updateAllocation(assetAllocation, trimpp);
            emit VolTrim("Trimmed", assetAllocation, assetSigma);
            lastTrimBlock = block.number;
        }
        lastTrimBlock = block.number;
    }

    /**
     * @notice updates the current buffer ratio
     */
    function updateBufferRatio() internal returns (uint256) {
        bufferRatio = btcAllocation / ethAllocation;
        return bufferRatio;
    }

    /**
     *
     * @param allocation the allocation to update
     * @notice updates buffer ratio after changing allocation
     */
    function updateAllocation(uint256 allocation, uint256 trimpp) internal {
        //move 5pp out of the affected asset
        //assuming that 5pp trim = 5e18 deduction from the asset allocation
        if (trimpp > i_CAP) {
            revert Neo__TrimIsAbove5PP();
        }
        allocation = allocation - trimpp;
        updateBufferRatio();
    }

    //GETTERS
    /**
     * @notice gets the current buffer ratio
     */
    function getBufferRatio() public view returns (uint256) {
        return bufferRatio;
    }

    /**
     * @notice gets the ethAllocation
     */
    function getEthAllocation() public view returns (uint256) {
        return ethAllocation;
    }

    /**
     * @notice gets the btcAllocation
     */
    function getBtcAllocation() public view returns (uint256) {
        return btcAllocation;
    }

    /**
     * @notice gets the ethSigma
     */
    function getEthSigma() public view returns (uint256) {
        return ethSigma;
    }

    /**
     * @notice gets the btcSigma
     */
    function getbtcSigma() public view returns (uint256) {
        return btcSigma;
    }
}
