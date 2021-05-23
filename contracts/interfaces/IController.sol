// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IController {
    event CreateReplica(address);
    event ChangeProxy(address);

    function owner() external returns (address);

    function implementation() external returns (address);

    function proxy() external returns (address);

    function createReplica(bytes32[] calldata salts) external;

    function predictReplica(bytes32 salt)
        external
        view
        returns (address predicted);

    function changeProxy(address _proxy) external;
}
