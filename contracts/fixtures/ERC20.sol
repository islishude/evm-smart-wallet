// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";

contract ERC20 is IERC20 {
  string public constant override symbol = "ERC20";
  string public constant override name = "ERC20 TOKEN TEST FIXTURE";
  uint8 public constant override decimals = 18;
  uint256 public constant override totalSupply = 1000000 * 10**18;

  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowed;

  constructor() {
    balances[msg.sender] = totalSupply;
    emit Transfer(address(0), msg.sender, totalSupply);
  }

  function balanceOf(address tokenOwner)
    public
    view
    override
    returns (uint256 balance)
  {
    return balances[tokenOwner];
  }

  function transfer(address to, uint256 tokens)
    public
    override
    returns (bool success)
  {
    balances[msg.sender] -= tokens;
    balances[to] += tokens;
    emit Transfer(msg.sender, to, tokens);
    return true;
  }

  function approve(address spender, uint256 tokens)
    public
    override
    returns (bool success)
  {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokens
  ) public override returns (bool success) {
    balances[from] -= tokens;
    allowed[from][msg.sender] -= tokens;
    balances[to] += tokens;
    emit Transfer(from, to, tokens);
    return true;
  }

  function allowance(address tokenOwner, address spender)
    public
    view
    override
    returns (uint256 remaining)
  {
    return allowed[tokenOwner][spender];
  }
}
