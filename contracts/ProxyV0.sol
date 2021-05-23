// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IReplica.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IProxyV0.sol";

contract Proxy is IProxyV0 {
    uint256 constant VERSION = 0;

    address public override owner;

    modifier OnlyOwner {
        require(msg.sender == owner, "403");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function transferEther(address receiver, Payment[] calldata payments)
        external
        override
        OnlyOwner
    {
        for (uint256 i = 0; i < payments.length; i++) {
            Payment calldata payment = payments[i];
            IReplica(payment.target).dispatch(
                receiver,
                payment.value,
                new bytes(0)
            );
        }
    }

    function transferERC20Token(
        address token,
        address receiver,
        bool checkres,
        Payment[] calldata payments
    ) external override OnlyOwner {
        for (uint256 i = 0; i < payments.length; i++) {
            Payment calldata payment = payments[i];
            bytes memory input =
                abi.encodeWithSelector(0xa9059cbb, receiver, payment.value);
            bytes memory result =
                IReplica(payment.target).dispatch(token, 0, input);
            if (checkres) {
                require(
                    (result.length == 0 || abi.decode(result, (bool))),
                    "ERC20_TRANSFER_FAILED"
                );
            }
        }
    }

    function transferERC20TokenWithFeeBurned(
        address token,
        address receiver,
        bool checkres,
        Payment[] calldata payments
    ) external override OnlyOwner {
        uint256 balanceAtFirst = IERC20(token).balanceOf(receiver);
        uint256 transferAmount = 0;
        for (uint256 i = 0; i < payments.length; i++) {
            Payment calldata payment = payments[i];
            bytes memory input =
                abi.encodeWithSelector(
                    IERC20.transfer.selector,
                    receiver,
                    payment.value
                );
            bytes memory result =
                IReplica(payment.target).dispatch(token, 0, input);
            if (checkres) {
                require(
                    (result.length == 0 || abi.decode(result, (bool))),
                    "ERC20_TRANSFER_FAILED"
                );
            }
            transferAmount += payment.value;
        }
        uint256 balanceAtLast = IERC20(token).balanceOf(receiver);
        uint256 feeBurndAmount =
            balanceAtFirst + transferAmount - balanceAtLast;
        if (feeBurndAmount > 0) {
            emit TokenTransferFeeBurn(token, receiver, feeBurndAmount);
        }
    }

    function transferERC721Token(
        address token,
        address target,
        address receiver,
        uint256 tokenId
    ) external override OnlyOwner {
        // function transferFrom(address from, address to, uint256 tokenId) external;
        bytes memory input =
            abi.encodeWithSelector(0x23b872dd, target, receiver, tokenId);
        IReplica(target).dispatch(token, 0, input);
    }

    function transferIERC1155Token(
        address token,
        address receiver,
        uint256 tokenId,
        Payment[] calldata payments
    ) external override OnlyOwner {
        // function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
        for (uint256 i = 0; i < payments.length; i++) {
            Payment calldata payment = payments[i];
            bytes memory input =
                abi.encodeWithSelector(
                    0xf242432a,
                    payment.target,
                    receiver,
                    payment.value,
                    tokenId,
                    new bytes(0)
                );
            IReplica(payment.target).dispatch(token, 0, input);
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
