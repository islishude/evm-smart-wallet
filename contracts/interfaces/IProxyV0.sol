// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IProxy.sol";

interface IProxyV0 is IProxy {
    struct Payment {
        address replica;
        uint256 value;
    }

    function transferEther(address receiver, Payment[] calldata payments)
        external;

    function transferERC20Token(
        address token,
        address receiver,
        bool checkres,
        Payment[] calldata payments
    ) external;

    function transferERC20TokenWithFeeBurned(
        address token,
        address replica,
        address receiver,
        uint256 value
    ) external;
}
