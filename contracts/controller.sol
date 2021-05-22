// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Replica.sol";
import "./interfaces/IController.sol";
import "./interfaces/IReplica.sol";

contract Factory is IController {
    using Clones for address;

    address public override owner;

    modifier OnlyOwner {
        require(msg.sender == owner, "403");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    address internal impl = address(new Replica());

    function createReplica(bytes32[] calldata salts)
        external
        override
        OnlyOwner
    {
        for (uint256 i = 0; i < salts.length; i++) {
            address forwarder = impl.cloneDeterministic(salts[i]);
            IReplica(forwarder).initial(address(this));
            emit CreateReplica(forwarder);
        }
    }

    function predictReplica(bytes32 salt)
        external
        view
        override
        returns (address)
    {
        return impl.predictDeterministicAddress(salt, address(this));
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
