// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IReplica {
    function invoke(
        address target,
        uint256 value,
        bytes calldata input
    ) external returns (bytes memory);

    function initial(address _factory) external;
}
