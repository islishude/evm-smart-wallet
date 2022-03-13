// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IController {
    event CreateReplica(address);
    event ChangeProxy(address);
    event ChangeImplementation(address);
    event SetWallet(address, bool);

    function owner() external returns (address);

    function proxy() external returns (address);

    function replicaCodeHash() external returns (bytes32);

    function wallets(address) external returns (bool);

    function implementation() external returns (address);

    function createReplica(bytes32[] calldata salts) external;

    function changeProxy(address) external;

    function changeImplemention(address) external;

    function setWallet(address _wallet, bool _yes) external;

    function predictReplica(bytes32 salt) external view returns (address);
}
