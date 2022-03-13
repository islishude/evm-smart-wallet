// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interfaces/IImplements.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ImplmentionV0 is IImplenmentionV0 {
    address internal immutable current = address(this);

    modifier onlyProxy() {
        require(address(this) != current, "only proxy");
        _;
    }

    event SendEther(address to, uint256 value);

    function transferEther(address payable to, uint256 value)
        public
        override
        onlyProxy
    {
        to.transfer(value);
        emit SendEther(to, value);
    }

    function trasnferERC20(
        address token,
        address to,
        uint256 value
    ) public override onlyProxy {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ERC20_TRANSFER_FAILED"
        );
    }
}
