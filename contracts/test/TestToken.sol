// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20("TEST", "TEST") {
    constructor() {
        _mint(_msgSender(), 10000);
    }
}
