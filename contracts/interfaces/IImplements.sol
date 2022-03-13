// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IImplenmentionV0 {
    function transferEther(address payable to, uint256 value) external;

    function trasnferERC20(
        address token,
        address to,
        uint256 value
    ) external;
}
