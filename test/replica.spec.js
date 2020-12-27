const { expectEvent, expectRevert } = require("@openzeppelin/test-helpers");
const { randomBytes } = require("crypto");

const Replica = artifacts.require("Replica");
const ERC20 = artifacts.require("ERC20");

contract("Replica", async ([alice, bob, carol]) => {
  beforeEach(async () => {
    this.instance = await Replica.new({ from: alice });
  });

  it("should receive ether and emit Deposit", async () => {
    const tx = await this.instance.send("100", { from: carol });
    expectEvent(tx, "Deposit", { sender: carol, amount: "100" });
    const balance = await web3.eth.getBalance(this.instance.address);
    expect(balance).to.be.equal("100");
  });

  it("should revert with 403", async () => {
    const tx = this.instance.dispatch(alice, "0x", 1, { from: bob });
    expectRevert(tx, "403");
  });

  it("should dispatch for ether successfully", async () => {
    const R = web3.utils.toChecksumAddress(
      "0x" + randomBytes(20).toString("hex")
    );
    await this.instance.send("100", { from: carol });
    expect(await web3.eth.getBalance(this.instance.address)).to.be.equal("100");
    const tx = await this.instance.dispatch(R, "0x", 1, { from: alice });
    expectEvent(tx, "FlushEther", { receiver: R, amount: "100" });
    expect(await web3.eth.getBalance(this.instance.address)).to.be.equal("0");
    expect(await web3.eth.getBalance(R)).to.be.equal("100");
  });

  it("should dispatch for ERC20 successfully", async () => {
    const token = await ERC20.new({ from: alice });
    await token.transfer(this.instance.address, "1", { from: alice });

    const bal_0 = (await token.balanceOf(this.instance.address)).toString();
    expect(bal_0).to.be.equal("1");
    const param = web3.eth.abi.encodeFunctionCall(
      token.abi.filter(
        (v) => v.name === "transfer" && v.type === "function"
      )[0],
      [carol, 1]
    );
    await this.instance.dispatch(token.address, param, 0);
    const bal_1 = (await token.balanceOf(this.instance.address)).toString();
    expect(bal_1).to.be.equal("0");
  });
});
