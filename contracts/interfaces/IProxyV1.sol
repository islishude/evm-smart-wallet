// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IProxyV1 {
    event TokenTransferFeeBurn(address, address, uint256);

    function owner() external returns (address);

    function flushEther(address receiver, address[] calldata targets) external;

    function flushERC20Token(
        address token,
        address receiver,
        bool checkres,
        address[] calldata targets
    ) external;

    function flushERC20TokenWithFeeBurned(
        address token,
        address receiver,
        bool checkres,
        address[] calldata targets
    ) external;

    function flushERC1155Token(
        address token,
        address receiver,
        uint256 tokenId,
        address[] calldata targets
    ) external;

    function transferERC721Token(
        address token,
        address target,
        address receiver,
        uint256 tokenId
    ) external;

    function dispatch(
        address token,
        address target,
        bytes calldata input
    ) external payable returns (bytes memory result);
}
