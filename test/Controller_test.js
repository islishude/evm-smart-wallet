"use strict";

const { expectRevert, expectEvent } = require("@openzeppelin/test-helpers");
const Controller = artifacts.require("Controller");
const Replica = artifacts.require("Replica");

contract("Controller", async ([alice, bob]) => {
  beforeEach(async () => {
    this.instance = await Controller.new(bob, { from: alice });
  });

  it("should construct contract correct", async () => {
    expect(await this.instance.owner()).to.equal(alice);
    expect(await this.instance.receiver()).to.equal(bob);
  });

  it("should call create() and revert", () => {
    const bytes32 =
      "0x0000000000000000000000000000000000000000000000000000000000000000";
    const tx = this.instance.create([bytes32], { from: bob });
    expectRevert(tx, "403");
  });

  it("should call create() successfully", async () => {
    const bytes32 =
      "0x0000000000000000000000000000000000000000000000000000000000000000";
    const tx = await this.instance.create([bytes32], { from: alice });
    const hash = web3.utils.soliditySha3(
      "0xff",
      this.instance.address,
      bytes32,
      web3.utils.sha3(Replica.bytecode)
    );
    const expectAddress = web3.utils.toChecksumAddress("0x" + hash.slice(-40));
    expectEvent(tx, "Create", { 0: expectAddress });
    expect(await this.instance.replicas(expectAddress)).to.be.equal(true);
  });
});
