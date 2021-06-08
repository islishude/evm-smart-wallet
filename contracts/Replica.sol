// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interfaces/IReplica.sol";
import "./interfaces/IController.sol";

// Replica is not a forworder

contract Replica is IReplica {
    address public controller;

    function initial(address _controller) external override {
        require(controller == address(0));
        controller = _controller;
    }

    function invoke(
        address target,
        uint256 value,
        bytes calldata input
    ) external override returns (bytes memory) {
        require(msg.sender == IController(controller).proxy(), "403");
        (bool success, bytes memory data) = target.call{value: value}(input);
        require(success, "invoke failed");
        return data;
    }

    fallback() external payable {}

    receive() external payable {}
}
