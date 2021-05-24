// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interfaces/IReplica.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IProxyV1.sol";

contract ProxyV1 is IProxyV1 {
    uint256 public constant override VERSION = 1;

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
            IReplica(replica).invoke(receiver, replica.balance, new bytes(0));
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
            bytes memory result = IReplica(replica).invoke(token, 0, input);
            if (checkres) {
                require(
                    (result.length == 0 || abi.decode(result, (bool))),
                    "ERC20_TRANSFER_FAILED"
                );
            }
        }
    }

    function invoke(
        address token,
        address replica,
        bytes calldata input
    ) external payable override OnlyOwner returns (bytes memory result) {
        return IReplica(replica).invoke(token, msg.value, input);
    }
}
