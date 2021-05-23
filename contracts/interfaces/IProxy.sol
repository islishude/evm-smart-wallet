// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IProxy {
    event TokenTransferFeeBurn(address, address, uint256);

    function owner() external returns (address);

    function dispatch(
        address token,
        address target,
        bytes calldata input
    ) external payable returns (bytes memory result);
}
