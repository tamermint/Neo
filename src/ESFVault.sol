// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/**
 * As a starting point - we are emulating basic vault functions - deposit and withdraw
 * On Deposit of mHAUD, vault shares are sent to sender and esf vault gets the mHAUD token
 * On Withdraw of mHAUD, vault shares are burned, mHAUD is returned to the sender
 * Withdraw conditions
 *  - Timelock condition kicks in - so withdraw should not happen within 24 hrs of deposit
 *  - Emergency withdrawal - 48h SLA - initiated - we need to check HBR first.
 */
contract ESFVault is ERC4626, Ownable, ReentrancyGuard {
    using FixedPointMathLib for uint256;

    //ERRORS
    error ESF__CannotDepositZero();
    error ESF__CannotWithdrawZero();
    error ESF__ReceiverCantBeZeroAddress();
    error ESF__CannotWithdrawWithin24Hrs();
    error ESF__VaultIsEmpty();

    //EVENTS
    event EmergencyWithdrawalInitiated(address indexed owner, uint256 shares);
    event WithdrawRequested(address indexed owner, uint256 shares);
    event TemporaryWithdrawalHold(uint256);
    event VaultSolvencyCheckBreached(uint256, uint256);
    event WithdrawalFulfilled(address indexed executor, address indexed recipient, uint256 shares);
    //event AssetRedeemed(address indexed, uint256);

    //STATE VARIABLES
    uint256 private constant HBR = 1.12e18; //solvency

    mapping(address => withdrawRequest) private lastWithdrawRequest; //enforce timelock

    struct withdrawRequest {
        uint256 timestamp;
        uint256 shares;
    }

    //CONSTRUCTOR
    constructor(IERC20 asset_) ERC20("ESF Vault Share", "ESFV") ERC4626(asset_) Ownable(msg.sender) {}

    //FUNCTIONS

    function depositAsset(uint256 assets, address receiver) public nonReentrant {
        if (assets == 0) {
            revert ESF__CannotDepositZero();
        }
        if (receiver == address(0)) {
            revert ESF__ReceiverCantBeZeroAddress();
        }
        deposit(assets, receiver);
    }

    function requestWithdrawal(uint256 shares) public returns (bool passed) {
        //who calls this function must have the mapping updated
        lastWithdrawRequest[msg.sender].timestamp = block.timestamp;
        lastWithdrawRequest[msg.sender].shares = shares;
        emit WithdrawRequested(msg.sender, shares);
        return true;
    }

    function fulfillWithdrawal(uint256 shares, address requestor) public nonReentrant {
        checkWithdrawalAndVaultConditions(shares, requestor);
        if (block.timestamp - lastWithdrawRequest[requestor].timestamp <= 172800 seconds) {
            emit EmergencyWithdrawalInitiated(requestor, shares);
        }
        redeem(shares, requestor, requestor);
        emit WithdrawalFulfilled(msg.sender, requestor, shares);
        lastWithdrawRequest[requestor].timestamp = 0;
        lastWithdrawRequest[msg.sender].shares = 0;
    }

    function checkWithdrawalAndVaultConditions(uint256 shares, address requestor) public {
        if (totalSupply() == 0) {
            revert ESF__VaultIsEmpty();
        }

        if (block.timestamp - lastWithdrawRequest[requestor].timestamp < 86400 seconds) {
            revert ESF__CannotWithdrawWithin24Hrs();
        }
        if (checkVaultHealthRatioBeforeWithdraw() == false) {
            emit TemporaryWithdrawalHold(block.timestamp);
        }
        if (checkHealthRatioAfterWithdraw(shares) == false) {
            emit VaultSolvencyCheckBreached(shares, block.timestamp);
        }
    }

    function checkVaultHealthRatioBeforeWithdraw() public view returns (bool passed) {
        uint256 totalAssets = totalAssets();
        uint256 totalShares = totalSupply();
        return FixedPointMathLib.divWadDown(totalAssets, totalShares) > HBR ? true : false;
    }

    function checkHealthRatioAfterWithdraw(uint256 shares) public view returns (bool passed) {
        //simulate withdrawal
        //preview redeem
        uint256 assets = previewRedeem(shares);
        //preview assets
        uint256 remainingAssets = totalAssets() - assets;
        uint256 remainingShares = totalSupply() - shares;
        //return HBR
        return FixedPointMathLib.divWadDown(remainingAssets, remainingShares) > HBR ? true : false;
    }
}
