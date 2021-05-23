// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IReplica.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IProxy.sol";

contract Proxy is IProxy {
    uint256 constant VERSION = 1;

    address public override owner;

    modifier OnlyOwner {
        require(msg.sender == owner, "403");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function ERC20Balance(address _token, address _account)
        internal
        view
        returns (uint256)
    {
        (bool success, bytes memory data) =
            _token.staticcall(
                abi.encodeWithSelector(IERC20.balanceOf.selector, _account)
            );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    function flushEther(address receiver, address[] calldata targets)
        external
        override
        OnlyOwner
    {
        for (uint256 i = 0; i < targets.length; i++) {
            address target = targets[i];
            IReplica(target).dispatch(receiver, target.balance, new bytes(0));
        }
    }

    function flushERC20Token(
        address token,
        address receiver,
        bool checkres,
        address[] calldata targets
    ) external override OnlyOwner {
        for (uint256 i = 0; i < targets.length; i++) {
            address target = targets[i];
            uint256 balance = ERC20Balance(token, target);
            bytes memory input =
                abi.encodeWithSelector(
                    IERC20.transfer.selector,
                    receiver,
                    balance
                );
            bytes memory result = IReplica(target).dispatch(token, 0, input);
            if (checkres) {
                require(
                    (result.length == 0 || abi.decode(result, (bool))),
                    "ERC20_TRANSFER_FAILED"
                );
            }
        }
    }

    function flushERC20TokenWithFeeBurned(
        address token,
        address receiver,
        bool checkres,
        address[] calldata targets
    ) external override OnlyOwner {
        uint256 balanceAtFirst = ERC20Balance(token, receiver);
        uint256 transferAmount = 0;
        for (uint256 i = 0; i < targets.length; i++) {
            address target = targets[i];
            uint256 balance = ERC20Balance(token, target);
            bytes memory input =
                abi.encodeWithSelector(
                    IERC20.transfer.selector,
                    receiver,
                    balance
                );
            bytes memory result = IReplica(target).dispatch(token, 0, input);
            if (checkres) {
                require(
                    (result.length == 0 || abi.decode(result, (bool))),
                    "ERC20_TRANSFER_FAILED"
                );
            }
            transferAmount += balance;
        }
        uint256 balanceAtLast = ERC20Balance(token, receiver);
        uint256 feeBurndAmount =
            balanceAtLast - balanceAtFirst - transferAmount;
        if (feeBurndAmount > 0) {
            emit TokenTransferFeeBurn(token, receiver, feeBurndAmount);
        }
    }

    function dispatch(
        address token,
        address target,
        bytes calldata input
    ) external payable override OnlyOwner returns (bytes memory result) {
        return IReplica(target).dispatch(token, msg.value, input);
    }
}
