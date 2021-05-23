// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IReplica.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IProxyV1.sol";

contract ProxyV1 is IProxyV1 {
    uint256 public constant override VERSION = 0;

    address public override owner;

    modifier OnlyOwner {
        require(msg.sender == owner, "403");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function flushEther(address receiver, address[] calldata replicas)
        external
        override
        OnlyOwner
    {
        for (uint256 i = 0; i < replicas.length; i++) {
            address replica = replicas[i];
            IReplica(replica).dispatch(receiver, replica.balance, new bytes(0));
        }
    }

    function flushERC20Token(
        address token,
        address receiver,
        bool checkres,
        address[] calldata replicas
    ) external override OnlyOwner {
        for (uint256 i = 0; i < replicas.length; i++) {
            address replica = replicas[i];
            uint256 balance = IERC20(token).balanceOf(replica);
            bytes memory input =
                abi.encodeWithSelector(
                    IERC20.transfer.selector,
                    receiver,
                    balance
                );
            bytes memory result = IReplica(replica).dispatch(token, 0, input);
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
        address[] calldata replicas
    ) external override OnlyOwner {
        uint256 balanceAtFirst = IERC20(token).balanceOf(receiver);
        uint256 transferAmount = 0;
        for (uint256 i = 0; i < replicas.length; i++) {
            address replica = replicas[i];
            uint256 balance = IERC20(token).balanceOf(replica);
            bytes memory input =
                abi.encodeWithSelector(
                    IERC20.transfer.selector,
                    receiver,
                    balance
                );
            bytes memory result = IReplica(replica).dispatch(token, 0, input);
            if (checkres) {
                require(
                    (result.length == 0 || abi.decode(result, (bool))),
                    "ERC20_TRANSFER_FAILED"
                );
            }
            transferAmount += balance;
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
        //  function transferFrom(address from, address to, uint256 tokenId) external;
        bytes memory input =
            abi.encodeWithSelector(
                IERC721.transferFrom.selector,
                replica,
                receiver,
                tokenId
            );
        IReplica(replica).dispatch(token, 0, input);
    }

    function flushERC1155Token(
        address token,
        address receiver,
        uint256 tokenId,
        address[] calldata replicas
    ) external override OnlyOwner {
        // function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
        for (uint256 i = 0; i < replicas.length; i++) {
            address replica = replicas[i];
            uint256 balance = IERC1155(token).balanceOf(replica, tokenId);
            bytes memory input =
                abi.encodeWithSelector(
                    IERC1155.safeTransferFrom.selector,
                    replica,
                    receiver,
                    tokenId,
                    balance,
                    new bytes(0)
                );
            IReplica(replica).dispatch(token, 0, input);
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
