// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IProxy.sol";

interface IProxyV0 is IProxy {
    struct Payment {
        address target;
        uint256 value;
    }

    function transferEther(address receiver, Payment[] calldata payments)
        external;

    function transferERC20Token(
        address token,
        address receiver,
        bool checkres,
        Payment[] calldata payments
    ) external;

    function transferERC20TokenWithFeeBurned(
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
}
