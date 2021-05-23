// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interfaces/IReplica.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IProxyV0.sol";

contract ProxyV0 is IProxyV0 {
    uint256 public constant override VERSION = 0;

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
            IReplica(payment.replica).dispatch(
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
                abi.encodeWithSelector(
                    IERC20.transfer.selector,
                    receiver,
                    payment.value
                );
            bytes memory result =
                IReplica(payment.replica).dispatch(token, 0, input);
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
                IReplica(payment.replica).dispatch(token, 0, input);
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
        address replica,
        address receiver,
        uint256 tokenId
    ) external override OnlyOwner {
        // function transferFrom(address from, address to, uint256 tokenId) external;
        bytes memory input =
            abi.encodeWithSelector(
                IERC721.transferFrom.selector,
                replica,
                receiver,
                tokenId
            );
        IReplica(replica).dispatch(token, 0, input);
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
                    IERC1155.safeTransferFrom.selector,
                    payment.replica,
                    receiver,
                    payment.value,
                    tokenId,
                    new bytes(0)
                );
            IReplica(payment.replica).dispatch(token, 0, input);
        }
    }

    function dispatch(
        address token,
        address replica,
        bytes calldata input
    ) external payable override OnlyOwner returns (bytes memory result) {
        return IReplica(replica).dispatch(token, msg.value, input);
    }
}
