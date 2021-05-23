// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IProxy.sol";

interface IProxyV1 is IProxy {
    function flushEther(address receiver, address[] calldata replicas) external;

    function flushERC20Token(
        address token,
        address receiver,
        bool checkres,
        address[] calldata replicas
    ) external;

    function flushERC20TokenWithFeeBurned(
        address token,
        address receiver,
        bool checkres,
        address[] calldata replicas
    ) external;
}
