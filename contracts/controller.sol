// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Replica.sol";
import "./interfaces/IController.sol";
import "./interfaces/IReplica.sol";

contract Controller is IController {
    using Clones for address;

    address public override owner;

    address public override proxy;

    modifier OnlyOwner {
        require(msg.sender == owner, "403");
        _;
    }

    constructor(address _owner, address _proxy) {
        owner = _owner;
        proxy = _proxy;
    }

    address internal replicaImpl = address(new Replica());

    function createReplica(bytes32[] calldata salts)
        external
        override
        OnlyOwner
    {
        for (uint256 i = 0; i < salts.length; i++) {
            address forwarder = replicaImpl.cloneDeterministic(salts[i]);
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
        return replicaImpl.predictDeterministicAddress(salt, address(this));
    }

    function changeProxy(address _proxy) external override OnlyOwner {
        proxy = _proxy;
        emit ChangeProxy(_proxy);
    }
}
