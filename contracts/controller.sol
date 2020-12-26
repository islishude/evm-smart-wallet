// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./replica.sol";

contract Controller {
  address public owner;
  address public receiver;

  mapping(Replica => bool) public replicas;

  event Create(Replica indexed);

  modifier OnlyOwner {
    require(msg.sender == owner, "403");
    _;
  }

  constructor(address _receiver) {
    receiver = _receiver;
    owner = msg.sender;
  }

  function create(bytes32[] calldata salts) external OnlyOwner {
    for (uint256 i = 0; i < salts.length; i++) {
      Replica created = new Replica{ salt: salts[i] }();
      replicas[created] = true;
      emit Create(created);
    }
  }

  function flushEther(Replica[] calldata targets) external OnlyOwner {
    for (uint256 i = 0; i < targets.length; i++) {
      Replica target = targets[i];
      require(replicas[target], "unknown target");
      target.dispatch(receiver, "", 1);
    }
  }

  /**
   * @notice flush ERC20 Token
   * @param token 代币地址
   * @param targets 需要转移代币余额的目标地址
   * @param checkres 是否验证 ERC20.transfer() 返回值，通常情况下需要验证，但如果代币合约提供了返回值，但始终返回 false 特殊合约则不能验证
   */
  function flushERC20Token(
    address token,
    Replica[] calldata targets,
    uint256 checkres
  ) external OnlyOwner {
    for (uint256 i = 0; i < targets.length; i++) {
      Replica target = targets[i];
      require(replicas[target], "unknown target");
      uint256 balance = IERC20(token).balanceOf(address(target));
      bytes memory param =
        abi.encodeWithSelector(0xa9059cbb, receiver, balance);
      bytes memory result = target.dispatch(token, param, 0);
      if (checkres == 1) {
        require(
          (result.length == 0 || abi.decode(result, (bool))),
          "ERC20_TRANSFER_FAILED"
        );
      }
    }
  }

  function dispatch(
    address token,
    Replica target,
    bytes calldata params
  ) external payable OnlyOwner returns (bytes memory data) {
    require(replicas[target], "unknown target");
    return target.dispatch{ value: msg.value }(token, params, 0);
  }
}
