// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interfaces/IController.sol";

import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract Replica {
    bytes32 constant CONTROLLER_SLOT = bytes32(uint256(keccak256("islishude.wallet.controller")) - 1);

    constructor() {
        StorageSlot.getAddressSlot(CONTROLLER_SLOT).value = msg.sender;
    }

    fallback() external payable {
        IController controller = IController(StorageSlot.getAddressSlot(CONTROLLER_SLOT).value);
        require(msg.sender == controller.proxy(), "only proxy");
        address target = controller.implementation();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    event Received(address sender, uint256 value);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
