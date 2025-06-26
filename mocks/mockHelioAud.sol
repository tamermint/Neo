// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {ERC20} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract MockHelioAud is ERC20 {
    constructor() ERC20("HelioAUDMock", "mHAUD") {}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function burn(uint256 amount) public {
        _burn(address(0), amount);
    }
}
