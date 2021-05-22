// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IReplica.sol";

contract Replica is IReplica {
    address internal factory;

    function initial(address _factory) external override {
        require(factory == address(0));
        factory = _factory;
    }

    function dispatch(
        address target,
        uint256 value,
        bytes calldata input
    ) external override returns (bytes memory) {
        require(msg.sender == factory, "403");
        (bool success, bytes memory data) = target.call{value: value}(input);
        require(success, "dispach failed");
        return data;
    }

    receive() external payable {}
}
