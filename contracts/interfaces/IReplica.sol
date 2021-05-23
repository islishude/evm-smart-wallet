// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IReplica {
    function dispatch(
        address replica,
        uint256 value,
        bytes calldata params
    ) external returns (bytes memory);

    function initial(address _factory) external;
}
