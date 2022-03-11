// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ImplementionV0.sol";
import "./interfaces/IProxies.sol";
import "./interfaces/IController.sol";

contract ProxyV0 is IProxyV0 {
    uint256 public constant override VERSION = 0;

    address public immutable override controller;

    constructor(address _ctrl) {
        controller = _ctrl;
    }

    modifier onlyWallet() {
        require(IController(controller).wallets(msg.sender), "only wallet");
        _;
    }

    function flushEther(address payable receiver, address[] calldata replicas)
        external
        override
        onlyWallet
    {
        for (uint256 i = 0; i < replicas.length; i++) {
            address replica = replicas[i];
            IImplenmentionV0(replica).transferEther(receiver, replica.balance);
        }
    }

    function transferEther(
        address payable receiver,
        Payment[] calldata payments
    ) external override onlyWallet {
        for (uint256 i = 0; i < payments.length; i++) {
            Payment calldata payment = payments[i];
            IImplenmentionV0(payment.replica).transferEther(
                receiver,
                payment.value
            );
        }
    }

    function flushERC20(
        address token,
        address payable receiver,
        address[] calldata replicas
    ) external override onlyWallet {
        for (uint256 i = 0; i < replicas.length; i++) {
            address replica = replicas[i];
            IImplenmentionV0(replica).trasnferERC20(
                token,
                receiver,
                IERC20(token).balanceOf(replica)
            );
        }
    }

    function transferERC20(
        address token,
        address receiver,
        Payment[] calldata payments
    ) external override onlyWallet {
        for (uint256 i = 0; i < payments.length; i++) {
            Payment calldata payment = payments[i];
            IImplenmentionV0(payment.replica).trasnferERC20(
                token,
                receiver,
                payment.value
            );
        }
    }
}
