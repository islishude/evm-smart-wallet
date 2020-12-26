// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./replica.sol";

contract Controller {
  address public owner;
  address payable recipient;

  mapping(Replica => bool) public replicas;

  event Create(Replica indexed);

  modifier OnlyOwner {
    require(msg.sender == owner, "403");
    _;
  }

  constructor(address payable _receipt) {
    recipient = _receipt;
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
      target.dispatch(recipient, "", 1);
    }
  }

  /**
   * @notice flush ERC20 Token
   * @param token the ERC20 token
   * @param checkres should verify return of ERC20.transfer()
   */
  function flushERC20Token(
    address token,
    Replica[] calldata targets,
    bool checkres
  ) external OnlyOwner {
    for (uint256 i = 0; i < targets.length; i++) {
      Replica target = targets[i];
      require(replicas[target], "unknown target");
      uint256 balance = IERC20(token).balanceOf(address(target));
      bytes memory param =
        abi.encodeWithSelector(0xa9059cbb, recipient, balance);
      bytes memory result = target.dispatch(token, param, 0);
      if (checkres) {
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
