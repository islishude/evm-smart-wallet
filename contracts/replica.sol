// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IReplica.sol";
import "./interfaces/IController.sol";

contract Replica is IReplica {
    address internal controller;

    function initial(address _controller) external override {
        require(controller == address(0));
        controller = _controller;
    }

    function dispatch(
        address target,
        uint256 value,
        bytes calldata input
    ) external override returns (bytes memory) {
        require(msg.sender == IController(controller).proxy(), "403");
        (bool success, bytes memory data) = target.call{value: value}(input);
        require(success, "dispach failed");
        return data;
    }

    receive() external payable {}
}
