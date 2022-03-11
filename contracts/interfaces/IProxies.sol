// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IProxyV0 {
    function VERSION() external returns (uint256);

    function controller() external returns (address);

    struct Payment {
        address replica;
        uint256 value;
    }

    function flushERC20(
        address token,
        address payable receiver,
        address[] calldata replicas
    ) external;

    function transferERC20(
        address token,
        address receiver,
        Payment[] calldata payments
    ) external;

    function flushEther(address payable receiver, address[] calldata replicas)
        external;

    function transferEther(
        address payable receiver,
        Payment[] calldata payments
    ) external;
}
