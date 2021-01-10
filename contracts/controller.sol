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

  /**
   * @notice create new replica addresses
   * @param salts the salt list for create2
   */
  function create(bytes32[] calldata salts) external OnlyOwner {
    for (uint256 i = 0; i < salts.length; i++) {
      Replica created = new Replica{ salt: salts[i] }();
      replicas[created] = true;
      emit Create(created);
    }
  }

  /**
   * @notice collect ethers
   * @param targets the replica list to transfer ethers
   */
  function flushEther(Replica[] calldata targets) external OnlyOwner {
    for (uint256 i = 0; i < targets.length; i++) {
      Replica target = targets[i];
      require(replicas[target], "unknown target");
      target.dispatch(receiver, "", 1);
    }
  }

  /**
   * @notice collect ERC20 tokens
   * @param token the ERC20 token address
   * @param targets the replica list to collect
   * @param checkres verify return of ERC20.transfer() or not,you should give true unless token.transfer() always return false
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

  /**
   * @notice call any for a replica address
   * @param token the address to call by replica
   * @param target the replica address
   * @param params abi encoded call data
   */
  function dispatch(
    address token,
    Replica target,
    bytes calldata params
  ) external payable OnlyOwner returns (bytes memory data) {
    require(replicas[target], "unknown target");
    bytes32 emptyHash32 =
      0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    require(
      token.codehash != 0x0 && token.codehash != emptyHash32,
      "not contract"
    );
    return target.dispatch{ value: msg.value }(token, params, 0);
  }
}
