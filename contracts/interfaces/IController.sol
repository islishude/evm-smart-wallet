// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IController {
    struct Payment {
        address target;
        uint256 value;
    }

    event CreateReplica(address indexed);

    function owner() external returns (address);

    function createReplica(bytes32[] calldata salts) external;

    function predictReplica(bytes32 salt)
        external
        view
        returns (address predicted);

    function transferEther(address receiver, Payment[] calldata payments)
        external;

    function transferERC20Token(
        address token,
        address receiver,
        bool checkres,
        Payment[] calldata payments
    ) external;

    function transferERC721Token(
        address token,
        address target,
        address receiver,
        uint256 tokenId
    ) external;

    function transferIERC1155Token(
        address token,
        address receiver,
        uint256 tokenId,
        Payment[] calldata payments
    ) external;

    function dispatch(
        address token,
        address target,
        bytes calldata input
    ) external payable returns (bytes memory result);
}
