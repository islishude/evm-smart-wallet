// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Replica.sol";

contract Controller is IController {
    address public override owner;

    address public override proxy;

    address public override implementation;

    bytes32 public constant override replicaCodeHash =
        keccak256(abi.encodePacked(type(Replica).creationCode));

    mapping(address => bool) public override wallets;

    modifier OnlyOwner() {
        require(msg.sender == owner, "403");
        _;
    }

    constructor(
        address _owner,
        address _proxy,
        address _implemention
    ) {
        owner = _owner;
        proxy = _proxy;
        implementation = _implemention;
    }

    function createReplica(bytes32[] calldata salts)
        external
        override
        OnlyOwner
    {
        for (uint256 i = 0; i < salts.length; i++) {
            Replica replica = new Replica{salt: salts[i]}();
            emit CreateReplica(address(replica));
        }
    }

    function predictReplica(bytes32 salt)
        external
        view
        override
        returns (address)
    {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, replicaCodeHash)
        );
        return address(uint160(uint256(_data)));
    }

    function changeProxy(address _proxy) external override OnlyOwner {
        proxy = _proxy;
        emit ChangeProxy(_proxy);
    }

    function changeImplemention(address _proxy) external override OnlyOwner {
        proxy = _proxy;
        emit ChangeProxy(_proxy);
    }

    function setWallet(address _wallet, bool _yes) external override OnlyOwner {
        wallets[_wallet] = _yes;
        emit SetWallet(_wallet, _yes);
    }
}
