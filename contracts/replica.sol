// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Replica {
  address internal controller;

  event FlushEther(address receiver, uint256 amount);
  event Deposit(address sender, uint256 amount);

  constructor() {
    controller = msg.sender;
  }

  function dispatch(
    address target,
    bytes calldata params,
    uint256 flushEther
  ) external payable returns (bytes memory) {
    require(msg.sender == controller, "403");
    uint256 value = msg.value;
    if (flushEther == 1) {
      value = address(this).balance;
      emit FlushEther(target, value);
    }
    (bool success, bytes memory data) = target.call{ value: value }(params);
    require(success, "400");
    return data;
  }

  receive() external payable {
    emit Deposit(msg.sender, msg.value);
  }
}
