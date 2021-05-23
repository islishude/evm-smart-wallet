// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IProxy.sol";

interface IProxyV1 is IProxy {
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
}
