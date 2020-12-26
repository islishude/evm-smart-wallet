"use strict";

const { expectRevert, expectEvent } = require("@openzeppelin/test-helpers");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const Controller = artifacts.require("Controller");
const Replica = artifacts.require("Replica");
const { randomBytes } = require("crypto");

const B = "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB";

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
    const random32 = "0x" + randomBytes(32).toString("hex");
    const newaddr = (() => {
      const hash = web3.utils.soliditySha3(
        "0xff",
        this.instance.address,
        random32,
        web3.utils.sha3(Replica.bytecode)
      );
      return web3.utils.toChecksumAddress("0x" + hash.slice(-40));
    })();

    // should transfer to new address successfully by 21000 gas limit
    {
      const tx_1 = await web3.eth.sendTransaction({
        from: carol,
        to: newaddr,
        value: "100",
        gas: 21000,
      });
      expect(tx_1.status).to.be.equal(
        true,
        "send ether to new address should be true"
      );
    }

    // should create replica successfully
    {
      const tx = await this.instance.create([random32], { from: alice });
      expectEvent(tx, "Create", { 0: newaddr });
      expect(await this.instance.replicas(newaddr)).to.be.equal(
        true,
        "the new address should store in replicas map"
      );
    }

    // should send successfuly to the address
    {
      const newReplica = await Replica.at(newaddr);
      const tx = await newReplica.send("100", { from: carol });
      expectEvent(tx, "Deposit", { sender: carol, amount: "100" });
    }

    // balance should be 200 at now
    {
      const Balance = await web3.eth.getBalance(newaddr);
      expect(Balance).to.be.equal("200", "balance should be 200 after tx_3");
    }

    // should call by owner
    {
      const tx = this.instance.flushEther([newaddr], { from: carol });
      expectRevert(tx, "403");
    }

    // should register at first
    {
      const c = "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC";
      const tx = this.instance.flushEther([c], { from: alice });
      expectRevert(tx, "unknown target");
    }

    // should flush ether successfully
    {
      const tx = await this.instance.flushEther([newaddr], { from: alice });
      // let hasFlushEtherEvent = tx.receipt.rawLogs.some(
      //   (l) => l.topics[0] === web3.utils.sha3("FlushEther(address,uint256)")
      // );
      // expect(hasFlushEtherEvent).to.be.equal(
      //   true,
      //   "should has FlushEther event"
      // );

      // const newReplica = await Replica.at(newaddr);
      // expectEvent(tx, "FlushEther", { receiver: B, amount: "200" }); // TODO: truffle bug

      const balOfReplica = await web3.eth.getBalance(newaddr);
      expect(balOfReplica).to.be.equal("0", "balance should be 200 after tx_3");

      const balOfB = await web3.eth.getBalance(B);
      expect(balOfB).to.be.equal("200", "balance should be 200 after tx_3");
    }
  });
});
