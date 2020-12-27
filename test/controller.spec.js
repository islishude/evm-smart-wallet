"use strict";

const { randomBytes } = require("crypto");

const { expectRevert, expectEvent } = require("@openzeppelin/test-helpers");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");

const Controller = artifacts.require("Controller");
const ERC20 = artifacts.require("ERC20");
const Replica = artifacts.require("Replica");

const B = "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB";
const C = "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC";

const newReplicaAddress = (ins, salt) => {
  const codehash = web3.utils.sha3(Replica.bytecode);
  const hash = web3.utils.soliditySha3("0xff", ins, salt, codehash);
  return web3.utils.toChecksumAddress("0x" + hash.slice(-40));
};

contract("Controller", async ([alice, bob, carol]) => {
  beforeEach(async () => {
    this.instance = await Controller.new(B, { from: alice });
  });

  it("should construct contract correct", async () => {
    expect(await this.instance.owner()).to.equal(alice);
    expect(await this.instance.receiver()).to.equal(B);
  });

  it("should call create() and revert by 403", () => {
    const bytes32 = "0x" + randomBytes(32).toString("hex");
    const tx = this.instance.create([bytes32], { from: bob });
    expectRevert(tx, "403");
  });

  it("should call create() and revert", () => {
    const bytes32 = "0x" + randomBytes(32).toString("hex");
    const tx = this.instance.create([bytes32, bytes32], {
      from: alice,
    });
    expectRevert(tx, "revert");
  });

  it("should call create() successfully", async () => {
    const params = [];
    const expectAddrs = [];

    for (let i = 0; i < 10; i++) {
      const random32 = "0x" + randomBytes(32).toString("hex");
      params.push(random32);
      const hash = web3.utils.soliditySha3(
        "0xff",
        this.instance.address,
        random32,
        web3.utils.sha3(Replica.bytecode)
      );
      expectAddrs.push(web3.utils.toChecksumAddress("0x" + hash.slice(-40)));
    }
    const tx = await this.instance.create(params, { from: alice });

    for (const addr of expectAddrs) {
      expectEvent(tx, "Create", { 0: addr });
      expect(await this.instance.replicas(addr)).to.be.equal(true);
    }
  });

  it("should call flushEther successfully", async () => {
    const salt = "0x" + randomBytes(32).toString("hex");
    const newaddr = newReplicaAddress(this.instance.address, salt);

    {
      const tx = this.instance.flushEther([C], { from: alice });
      expectRevert(tx, "unknown target", "should create replica at first");
    }

    {
      const tx = this.instance.flushEther([newaddr], { from: carol });
      expectRevert(tx, "403", "should call by owner");
    }

    // should create replica successfully
    {
      const tx = await this.instance.create([salt], { from: alice });
      expectEvent(tx, "Create", { 0: newaddr });
      expect(await this.instance.replicas(newaddr)).to.be.equal(
        true,
        "the new address should be saved in replicas map"
      );
    }

    const newReplica = await Replica.at(newaddr);

    {
      const tx = await newReplica.send("100", { from: carol });
      expectEvent(
        tx,
        "Deposit",
        { sender: carol, amount: "100" },
        "should send successfuly to the address"
      );
    }

    {
      const Balance = await web3.eth.getBalance(newaddr);
      expect(Balance).to.be.equal(
        "100",
        "balance should be 100 after after deposit"
      );
    }

    // should flush ether successfully
    {
      const tx = await this.instance.flushEther([newaddr], { from: alice });
      let hasFlushEtherEvent = tx.receipt.rawLogs.some(
        (l) => l.topics[0] === web3.utils.sha3("FlushEther(address,uint256)")
      );
      expect(hasFlushEtherEvent).to.be.equal(
        true,
        "should has FlushEther event"
      );

      const result = web3.eth.abi.decodeLog(
        newReplica.abi.filter(
          (v) => v.type == "event" && v.name == "FlushEther"
        )[0].inputs,
        tx.receipt.rawLogs[0].data,
        tx.receipt.rawLogs[0].topics
      );
      expect(result.receiver).to.be.equal(B);
      expect(result.amount).to.be.equal("100");

      const balOfReplica = await web3.eth.getBalance(newaddr);
      expect(balOfReplica).to.be.equal(
        "0",
        "newaddr's balance should be 0 at last"
      );

      const balOfB = await web3.eth.getBalance(B);
      expect(balOfB).to.be.equal("100", "B's balance should be 100 at last");
    }
  });

  it("should call flushERC20Token successfully", async () => {
    {
      const tx = this.instance.flushEther([C], { from: alice });
      expectRevert(tx, "unknown target", "should create replica at first");
    }

    const salt = "0x" + randomBytes(32).toString("hex");
    const newaddr = newReplicaAddress(this.instance.address, salt);

    {
      const tx = this.instance.flushEther([newaddr], { from: carol });
      expectRevert(tx, "403", "should call by owner");
    }

    {
      const tx = await this.instance.create([salt], { from: alice });
      expectEvent(
        tx,
        "Create",
        { 0: newaddr },
        "should create replica successfully"
      );
      expect(await this.instance.replicas(newaddr)).to.be.equal(
        true,
        "the new address should store in replicas map"
      );
    }

    const token = await ERC20.new({ from: carol });
    await token.transfer(newaddr, "100", { from: carol });

    const balToken_1 = await token.balanceOf(newaddr);
    expect(balToken_1.toString()).to.be.equal(
      "100",
      "newaddr's token balance should be 100 after sent"
    );

    await this.instance.flushERC20Token(token.address, [newaddr], 1);
    const balToken_2 = await token.balanceOf(newaddr);
    expect(balToken_2.toString()).to.be.equal(
      "0",
      "newaddr's token balance should be 100 ast last"
    );

    const balToken_3 = await token.balanceOf(B);
    expect(balToken_3.toString()).to.be.equal(
      "100",
      "B's token balance should be 100 at last"
    );
  });
});
